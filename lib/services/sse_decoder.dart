import 'dart:convert';

/// SSE framing independent of HTTP chunks, including CRLF and multiline data.
class SseDecoder {
  static Stream<Map<String, dynamic>> decode(Stream<List<int>> bytes) async* {
    final data = <String>[];
    Map<String, dynamic> parse() {
      final decoded = jsonDecode(data.join('\n'));
      data.clear();
      if (decoded is! Map<String, dynamic> || decoded['type'] is! String) {
        throw const FormatException('Event SSE tidak valid.');
      }
      return decoded;
    }

    await for (final line
        in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (data.isNotEmpty) yield parse();
      } else if (line.startsWith('data:')) {
        final value = line.substring(5);
        data.add(value.startsWith(' ') ? value.substring(1) : value);
      }
    }
    if (data.isNotEmpty) yield parse();
  }
}
