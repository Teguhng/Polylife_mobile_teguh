import 'dart:convert';
import 'dart:math';

import 'package:mobile_ver/core/network/api_client.dart';

class AiChatService {
  Future<List<Map<String, dynamic>>> sessions() async {
    final response = await ApiClient.get('/ai/sessions');
    final body = _decode(response.body, response.statusCode);
    return ((body['sessions'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> messages(int sessionId) async {
    final response = await ApiClient.get('/ai/sessions/$sessionId');
    return _decode(response.body, response.statusCode);
  }

  Future<Map<String, dynamic>> send(String message, {int? sessionId}) async {
    final response = await ApiClient.post('/ai/chat', {
      'message': message,
      'session_id': sessionId,
      'request_id': _requestId(),
    });
    return _decode(response.body, response.statusCode);
  }

  Future<Map<String, dynamic>> run(int runId) async {
    final response = await ApiClient.get('/ai/runs/$runId');
    return _decode(response.body, response.statusCode, acceptRunning: true);
  }

  Map<String, dynamic> _decode(
    String source,
    int statusCode, {
    bool acceptRunning = false,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) throw const FormatException('Respons AI tidak valid.');
    final body = Map<String, dynamic>.from(decoded);
    final success = statusCode >= 200 && statusCode < 300;
    if (!success && !(acceptRunning && statusCode == 202)) {
      throw Exception(body['message']?.toString() ?? 'Permintaan AI gagal.');
    }
    return body;
  }

  String _requestId() {
    final random = Random.secure();
    String group(int length) => List.generate(
          length,
          (_) => random.nextInt(16).toRadixString(16),
        ).join();
    return '${group(8)}-${group(4)}-4${group(3)}-a${group(3)}-${group(12)}';
  }
}
