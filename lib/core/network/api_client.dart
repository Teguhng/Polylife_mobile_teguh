import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_ver/core/config/api_config.dart';
import 'package:mobile_ver/core/storage/local_storage.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 20);
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await LocalStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return http
        .get(ApiConfig.endpointUri(endpoint), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return http
        .post(
          ApiConfig.endpointUri(endpoint),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> postMultipart(
    String endpoint, {
    required String fileField,
    required String filePath,
    Map<String, String> fields = const {},
  }) async {
    final headers = await _getHeaders();
    final request = http.MultipartRequest(
      'POST',
      ApiConfig.endpointUri(endpoint),
    );

    request.headers.addAll(headers);
    request.headers.remove('Content-Type');
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final response = await request.send().timeout(_timeout);

    return http.Response.fromStream(response);
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return http
        .put(
          ApiConfig.endpointUri(endpoint),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return http
        .patch(
          ApiConfig.endpointUri(endpoint),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return http
        .delete(ApiConfig.endpointUri(endpoint), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> deleteWithBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return http
        .delete(
          ApiConfig.endpointUri(endpoint),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }
}

abstract class HttpApiClient {
  Future<http.Response> get(String endpoint);

  Future<http.Response> post(String endpoint, Map<String, dynamic> body);

  Future<http.Response> put(String endpoint, Map<String, dynamic> body);

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body);

  Future<http.Response> delete(String endpoint);
}

class StaticApiClientAdapter implements HttpApiClient {
  const StaticApiClientAdapter();

  @override
  Future<http.Response> get(String endpoint) {
    return ApiClient.get(endpoint);
  }

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) {
    return ApiClient.post(endpoint, body);
  }

  @override
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) {
    return ApiClient.put(endpoint, body);
  }

  @override
  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) {
    return ApiClient.patch(endpoint, body);
  }

  @override
  Future<http.Response> delete(String endpoint) {
    return ApiClient.delete(endpoint);
  }
}
