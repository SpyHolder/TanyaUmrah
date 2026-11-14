import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/student.dart';
import '../models/calendar_event.dart';

class ApiService {
  static String get baseUrl => StorageService.getApiBaseUrl();

  // Verify Student Login
  static Future<Student> verifyStudent({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/verify');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Student.fromJson(data['profile']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Gagal memverifikasi akun mahasiswa.');
    }
  }

  // Update Student Profile
  static Future<Student> updateProfile(String nim, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/user/profile/$nim');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Student.fromJson(data['profile']);
    } else {
      throw Exception('Gagal memperbarui profil.');
    }
  }

  // Send Chat Query with SSE Streaming
  static Stream<Map<String, dynamic>> streamChatQuery({
    required String query,
    String? nim,
    String? conversationId,
  }) async* {
    final uri = Uri.parse('$baseUrl/chat');
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'query': query,
      'nim': nim,
      'conversation_id': conversationId,
    });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield {
          'type': 'token',
          'content': 'Maaf, server backend sedang tidak dapat dihubungi (${response.statusCode}).',
        };
        yield {'type': 'done'};
        return;
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventString = buffer.substring(0, eventEnd).trim();
          buffer = buffer.substring(eventEnd + 2);

          for (final line in eventString.split('\n')) {
            if (line.startsWith('data:')) {
              final jsonStr = line.replaceFirst('data:', '').trim();
              if (jsonStr.isNotEmpty) {
                try {
                  final data = jsonDecode(jsonStr);
                  yield data;
                } catch (_) {}
              }
            }
          }
        }
      }
    } catch (e) {
      yield {
        'type': 'token',
        'content': '\n\n⚠️ Kendala koneksi ke server ($baseUrl): $e\nPastikan backend FastAPI sedang berjalan.',
      };
      yield {'type': 'done'};
    } finally {
      client.close();
    }
  }

  // Get Academic Calendar Events
  static Future<List<CalendarEvent>> getCalendarEvents({int? month, int? year}) async {
    String url = '$baseUrl/calendar/events';
    final params = <String>[];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['events'] ?? [];
      return list.map((item) => CalendarEvent.fromJson(item)).toList();
    }
    return [];
  }

  // Get Document Knowledge Base List
  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final response = await http.get(Uri.parse('$baseUrl/documents')).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['documents'] ?? []);
    }
    return [];
  }

  // Submit Feedback
  static Future<bool> sendFeedback({
    required String messageId,
    required String rating,
    String? nim,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message_id': messageId,
          'rating': rating,
          'nim': nim,
          'comment': comment,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
