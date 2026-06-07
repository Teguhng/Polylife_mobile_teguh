import 'package:http/http.dart' as http;
import 'package:mobile_ver/core/network/api_client.dart';

class FakeApiRequest {
  final String method;
  final String endpoint;
  final Map<String, dynamic>? body;

  const FakeApiRequest({
    required this.method,
    required this.endpoint,
    this.body,
  });
}

class FakeHttpApiClient implements HttpApiClient {
  final Map<String, http.Response> _responses = <String, http.Response>{};
  final List<FakeApiRequest> requests = <FakeApiRequest>[];

  void when(
    String method,
    String endpoint, {
    required int statusCode,
    required String body,
  }) {
    _responses['${method.toUpperCase()} $endpoint'] = http.Response(
      body,
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }

  @override
  Future<http.Response> get(String endpoint) async {
    requests.add(FakeApiRequest(method: 'GET', endpoint: endpoint));
    return _responseFor('GET', endpoint);
  }

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    requests.add(
      FakeApiRequest(method: 'POST', endpoint: endpoint, body: body),
    );
    return _responseFor('POST', endpoint);
  }

  @override
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    requests.add(FakeApiRequest(method: 'PUT', endpoint: endpoint, body: body));
    return _responseFor('PUT', endpoint);
  }

  @override
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    requests.add(
      FakeApiRequest(method: 'PATCH', endpoint: endpoint, body: body),
    );
    return _responseFor('PATCH', endpoint);
  }

  @override
  Future<http.Response> delete(String endpoint) async {
    requests.add(FakeApiRequest(method: 'DELETE', endpoint: endpoint));
    return _responseFor('DELETE', endpoint);
  }

  http.Response _responseFor(String method, String endpoint) {
    return _responses['${method.toUpperCase()} $endpoint'] ??
        http.Response('{"message":"Not faked"}', 500);
  }
}
