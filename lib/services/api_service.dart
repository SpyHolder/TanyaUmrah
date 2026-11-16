import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/student.dart';
import '../models/calendar_event.dart';
import 'sse_decoder.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static Future<String?> Function()? tokenProvider;
  static Future<void> Function()? onUnauthorized;
  static http.Client Function() clientFactory = http.Client.new;

  static Future<Map<String, String>> _headers({String? token}) async {
    token ??= await tokenProvider?.call();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi tidak tersedia. Silakan masuk kembali.',
        401,
      );
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<void> _check(int status, String body) async {
    if (status >= 200 && status < 300) return;
    if (status == 401) await onUnauthorized?.call();
    String message = 'Permintaan gagal (HTTP $status). Silakan coba lagi.';
    try {
      final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
      if (detail is String) message = detail;
      if (detail is List) {
        message = 'Data tidak valid. Periksa kembali isian Anda.';
      }
    } catch (_) {
      /* Non-JSON reverse proxy response. */
    }
    throw ApiException(message, status);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = clientFactory();
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers.addAll(await _headers(token: token));
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(AppConfig.requestTimeout);
      await _check(response.statusCode, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw ApiException(
        'Koneksi ke $baseUrl melewati batas waktu. Periksa server lokal dan lib/core/app_config.dart.',
      );
    } on http.ClientException {
      throw ApiException(
        'Tidak dapat terhubung ke $baseUrl. Periksa server, jaringan, dan lib/core/app_config.dart.',
      );
    } on FormatException {
      throw const ApiException('Respons server tidak valid.');
    } finally {
      client.close();
    }
  }

  static Future<Student> verifyStudent({required String idToken}) async {
    final data = await _request(
      'POST',
      '/auth/verify',
      token: idToken,
      body: {'id_token': idToken},
    );
    return Student.fromJson(data['profile']);
  }

  static Future<Student> updateProfile(
    String nim,
    Map<String, dynamic> payload,
  ) async {
    final data = await _request('PUT', '/user/profile/$nim', body: payload);
    return Student.fromJson(data['profile']);
  }

  static Stream<Map<String, dynamic>> streamChatQuery({
    required String query,
    String? conversationId,
    List<Map<String, String>> history = const [],
    required http.Client client,
  }) async* {
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/chat'));
      request.headers.addAll(await _headers());
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode({
        'query': query,
        'conversation_id': conversationId,
        'history': history,
      });
      final response = await client
          .send(request)
          .timeout(AppConfig.requestTimeout);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString().timeout(
          AppConfig.requestTimeout,
        );
        await _check(response.statusCode, body);
      }
      var completed = false;
      await for (final event in SseDecoder.decode(
        response.stream.timeout(AppConfig.streamIdleTimeout),
      )) {
        if (event['type'] == 'error') {
          throw ApiException(
            event['content'] as String? ?? 'Layanan jawaban sedang bermasalah.',
          );
        }
        yield event;
        if (event['type'] == 'done') {
          completed = true;
          break;
        }
      }
      if (!completed) {
        throw const ApiException(
          'Koneksi terputus sebelum jawaban selesai. Silakan coba lagi.',
        );
      }
    } on TimeoutException {
      throw const ApiException(
        'Server terlalu lama merespons. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Koneksi chat terputus. Periksa jaringan dan backend lokal.',
      );
    } on FormatException {
      throw const ApiException('Format streaming dari server tidak valid.');
    } finally {
      client.close();
    }
  }

  static Future<List<CalendarEvent>> getCalendarEvents({
    int? month,
    int? year,
  }) async {
    final params = <String, String>{
      if (month != null) 'month': '$month',
      if (year != null) 'year': '$year',
    };
    final query = params.isEmpty
        ? ''
        : '?${Uri(queryParameters: params).query}';
    final data = await _request('GET', '/calendar/events$query');
    return (data['events'] as List)
        .map((item) => CalendarEvent.fromJson(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final data = await _request('GET', '/documents');
    return List<Map<String, dynamic>>.from(data['documents']);
  }

  static Future<void> sendFeedback({
    required String messageId,
    required String rating,
    String? conversationId,
  }) async {
    await _request(
      'POST',
      '/chat/feedback',
      body: {
        'message_id': messageId,
        'rating': rating,
        'conversation_id': conversationId,
      },
    );
  }
}
