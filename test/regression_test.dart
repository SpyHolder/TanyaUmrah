import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanya_umrah/core/app_config.dart';
import 'package:tanya_umrah/models/message.dart';
import 'package:tanya_umrah/models/student.dart';
import 'package:tanya_umrah/providers/auth_provider.dart';
import 'package:tanya_umrah/providers/chat_provider.dart';
import 'package:tanya_umrah/services/api_service.dart';
import 'package:tanya_umrah/services/firebase_session_service.dart';
import 'package:tanya_umrah/services/sse_decoder.dart';
import 'package:tanya_umrah/services/storage_service.dart';

Student student() => Student.fromJson({
  'nim': '2401020163',
  'nama': 'Mahasiswa',
  'email': '2401020163@student.umrah.ac.id',
});

class FakeSession implements SessionService {
  SessionIdentity? identity;
  final changes = StreamController<bool>.broadcast();
  FakeSession([this.identity]);
  @override
  Future<SessionIdentity?> restore() async => identity;
  @override
  Future<SessionIdentity> signIn() async => identity!;
  @override
  Future<String?> getIdToken() async =>
      identity == null ? null : 'firebase-id-token';
  @override
  Future<void> signOut() async {
    identity = null;
  }

  @override
  Stream<bool> get signedInChanges => changes.stream;
}

String sse(Map<String, dynamic> event) => 'data: ${jsonEncode(event)}\n\n';
ChatMessage message(String id) => ChatMessage(
  id: id,
  role: MessageRole.assistant,
  content: 'Jawaban',
  timestamp: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    StorageService.useAccount('account-a');
    ApiService.tokenProvider = () async => 'firebase-id-token';
    ApiService.onUnauthorized = null;
  });
  tearDown(() {
    ApiService.clientFactory = http.Client.new;
    ApiService.tokenProvider = null;
    ApiService.onUnauthorized = null;
  });

  test('Only full numeric student email is accepted', () {
    expect(AppConfig.isStudentEmail('2401020163@student.umrah.ac.id'), isTrue);
    for (final email in [
      'student@gmail.com',
      '1@umrah.ac.id',
      '1@student.umrah.ac.id.evil.test',
      '1abc@student.umrah.ac.id',
      'name@student.umrah.ac.id',
    ]) {
      expect(AppConfig.isStudentEmail(email), isFalse, reason: email);
    }
  });

  test('Message lists are independently mutable even with const input', () {
    final a = message('a');
    final b = message('b');
    a.sources.addAll([]);
    a.suggestions.add('Lanjut?');
    expect(b.suggestions, isEmpty);
    expect(ChatMessage.fromJson(a.toJson()).suggestions, ['Lanjut?']);
  });

  test(
    'Legacy anonymous data and old UI server override are discarded',
    () async {
      SharedPreferences.setMockInitialValues({
        'tanya_umrah_history': jsonEncode([message('legacy').toJson()]),
        'tanya_umrah_api_url': 'http://wrong-server/api/v1',
      });
      await StorageService.init();
      StorageService.useAccount('account-a');
      expect(StorageService.getChatHistory(), isEmpty);
      expect(ApiService.baseUrl, AppConfig.apiBaseUrl);
      expect(ApiService.baseUrl, isNot(contains('wrong-server')));
    },
  );

  test(
    'History, bookmarks and conversation ID are isolated by Firebase UID',
    () async {
      final a = message('a');
      await StorageService.saveChatHistory([a]);
      await StorageService.toggleBookmark(a);
      await StorageService.saveConversationId('conversation-a');
      StorageService.useAccount('account-b');
      expect(StorageService.getChatHistory(), isEmpty);
      expect(StorageService.getBookmarks(), isEmpty);
      expect(StorageService.getConversationId(), isNull);
      StorageService.useAccount(null);
      expect(StorageService.getChatHistory(), isEmpty);
      StorageService.useAccount('account-a');
      expect(StorageService.getChatHistory().single.isBookmarked, isTrue);
      expect(StorageService.getConversationId(), 'conversation-a');
    },
  );

  test('SSE supports CRLF, split UTF8, multiline data and final EOF', () async {
    final bytes = utf8.encode(
      ': heartbeat\r\ndata: {"type":"token",\r\n'
      'data: "content":"Halo 🌊"}\r\n\r\ndata: {"type":"done"}',
    );
    final events = await SseDecoder.decode(
      Stream.fromIterable(bytes.map((byte) => [byte])),
    ).toList();
    expect(events.first['content'], 'Halo 🌊');
    expect(events.last['type'], 'done');
  });

  test('Malformed SSE is not silently swallowed', () async {
    await expectLater(
      SseDecoder.decode(Stream.value(utf8.encode('data: not-json\n\n'))),
      emitsError(isA<FormatException>()),
    );
  });

  test('Verify sends ID token, not user-editable email/name', () async {
    ApiService.clientFactory = () => MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer firebase-id-token');
      expect(jsonDecode(request.body), {'id_token': 'firebase-id-token'});
      return http.Response(jsonEncode({'profile': student().toJson()}), 200);
    });
    expect(
      (await ApiService.verifyStudent(idToken: 'firebase-id-token')).nim,
      '2401020163',
    );
  });

  test(
    'HTTP 401 invalidates session; non-200 documents is not an empty list',
    () async {
      var invalidated = false;
      ApiService.onUnauthorized = () async {
        invalidated = true;
      };
      ApiService.clientFactory = () => MockClient(
        (_) async => http.Response('{"detail":"Sesi berakhir"}', 401),
      );
      await expectLater(
        ApiService.getDocuments(),
        throwsA(isA<ApiException>()),
      );
      expect(invalidated, isTrue);
    },
  );

  test('Missing token fails without sending HTTP', () async {
    ApiService.tokenProvider = () async => null;
    var called = false;
    ApiService.clientFactory = () => MockClient((_) async {
      called = true;
      return http.Response('{}', 200);
    });
    await expectLater(ApiService.getDocuments(), throwsA(isA<ApiException>()));
    expect(called, isFalse);
  });

  test(
    'Chat finalizes sources/suggestions, persists ID and sends bounded history',
    () async {
      var calls = 0;
      final provider = ChatProvider(
        clientFactory: () => MockClient((request) async {
          calls++;
          final body = jsonDecode(request.body);
          if (calls == 2) {
            expect(body['conversation_id'], 'conv-1');
            expect((body['history'] as List).length, 2);
          }
          return http.Response(
            [
              sse({'type': 'meta', 'conversation_id': 'conv-1'}),
              sse({'type': 'token', 'content': 'Jawaban'}),
              sse({
                'type': 'sources',
                'data': [
                  {
                    'document': 'Pedoman',
                    'page': 1,
                    'section': 'Pasal 1',
                    'similarity': 0.8,
                  },
                ],
              }),
              sse({
                'type': 'suggestions',
                'data': ['Lanjut?'],
              }),
              sse({'type': 'done'}),
            ].join(),
            200,
          );
        }),
      );
      provider.setAccount('account-a');
      await provider.sendMessage(query: 'Bagaimana KRS?');
      expect(provider.messages.last.hasError, isFalse);
      expect(provider.messages.last.sources.single.document, 'Pedoman');
      expect(provider.messages.last.suggestions, ['Lanjut?']);
      expect(provider.isStreaming, isFalse);
      expect(StorageService.getChatHistory().length, 2);
      expect(StorageService.getConversationId(), 'conv-1');
      await provider.sendMessage(query: 'Syaratnya?');
      await provider.toggleBookmark(provider.messages.last);
      expect(StorageService.getChatHistory().last.isBookmarked, isTrue);
      final saved = StorageService.getBookmarks().single;
      await provider.toggleBookmark(saved);
      expect(provider.messages.last.isBookmarked, isFalse);
      provider.dispose();
    },
  );

  test(
    'Truncated stream and explicit server errors are marked as failures',
    () async {
      for (final response in [
        sse({'type': 'token', 'content': 'Sebagian'}),
        sse({'type': 'error', 'content': 'Layanan gagal'}),
      ]) {
        final provider = ChatProvider(
          clientFactory: () =>
              MockClient((_) async => http.Response(response, 200)),
        );
        provider.setAccount('account-a');
        await provider.sendMessage(query: 'KRS?');
        expect(provider.messages.last.hasError, isTrue);
        expect(provider.isStreaming, isFalse);
        await provider.clearChat();
        provider.dispose();
      }
    },
  );

  test(
    'Clearing a streaming chat ignores late tokens and does not resurrect history',
    () async {
      final controller = StreamController<List<int>>();
      final ready = Completer<void>();
      final provider = ChatProvider(
        clientFactory: () => MockClient.streaming((_, _) async {
          ready.complete();
          return http.StreamedResponse(controller.stream, 200);
        }),
      );
      provider.setAccount('account-a');
      final sending = provider.sendMessage(query: 'KRS?');
      await ready.future;
      await provider.clearChat();
      controller.add(utf8.encode(sse({'type': 'token', 'content': 'Late'})));
      await controller.close();
      await sending;
      expect(provider.messages, isEmpty);
      expect(provider.isStreaming, isFalse);
      expect(StorageService.getChatHistory(), isEmpty);
      provider.dispose();
    },
  );

  test(
    'Account switch before widget rebuild cannot persist old stream into new account',
    () async {
      final controller = StreamController<List<int>>();
      final ready = Completer<void>();
      final provider = ChatProvider(
        clientFactory: () => MockClient.streaming((_, _) async {
          ready.complete();
          return http.StreamedResponse(controller.stream, 200);
        }),
      );
      provider.setAccount('account-a');
      final sending = provider.sendMessage(query: 'KRS?');
      await ready.future;
      StorageService.useAccount('account-b');
      controller.add(
        utf8.encode(sse({'type': 'token', 'content': 'Old private answer'})),
      );
      await controller.close();
      await sending;
      expect(StorageService.getChatHistory(), isEmpty);
      expect(StorageService.getConversationId(), isNull);
      provider.setAccount('account-b');
      expect(provider.messages, isEmpty);
      provider.dispose();
    },
  );

  test(
    'Local profile never authenticates a signed-out Firebase session',
    () async {
      await StorageService.saveStudent(student());
      final session = FakeSession();
      var verified = false;
      final auth = AuthProvider(
        session: session,
        verify: (_) async {
          verified = true;
          return student();
        },
      );
      await auth.initialize();
      expect(auth.isInitializing, isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(verified, isFalse);
      auth.dispose();
      await session.changes.close();
    },
  );

  test('Firebase session must also pass backend verification', () async {
    final session = FakeSession(
      const SessionIdentity('account-a', '2401020163@student.umrah.ac.id'),
    );
    final auth = AuthProvider(
      session: session,
      verify: (_) async => throw const ApiException('Akun ditolak', 403),
    );
    await auth.initialize();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.errorMessage, contains('ditolak'));
    expect(session.identity, isNull);
    auth.dispose();
    await session.changes.close();
  });

  test(
    'Restored Firebase session is verified and logout removes active scope',
    () async {
      final session = FakeSession(
        const SessionIdentity('account-a', '2401020163@student.umrah.ac.id'),
      );
      final auth = AuthProvider(
        session: session,
        verify: (token) async {
          expect(token, 'firebase-id-token');
          return student();
        },
      );
      await auth.initialize();
      expect(auth.isLoggedIn, isTrue);
      expect(auth.accountId, 'account-a');
      await auth.logout();
      expect(auth.currentStudent, isNull);
      expect(StorageService.getStudent(), isNull);
      auth.dispose();
      await session.changes.close();
    },
  );
}
