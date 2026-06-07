import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override with:
  // flutter run --dart-define=POLYLIFE_API_BASE_URL=https://domainmu.com/api/v1
  static const String _configuredBaseUrl = String.fromEnvironment(
    'POLYLIFE_API_BASE_URL',
    defaultValue: 'https://polylife.site/api/v1',
  );

  static const String releaseHttpsErrorMessage =
      'Release build requires an HTTPS API base URL.';

  static String get baseUrl => _validatedBaseUrl;

  static Uri endpointUri(String endpoint) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return Uri.parse('$normalizedBase$normalizedEndpoint');
  }

  static String? resolveMediaUrl(String? rawPath) {
    final path = rawPath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }

    if (_hasAbsoluteScheme(path)) {
      return isAllowedAbsoluteUrl(path) ? path : null;
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final resolved = '$baseOrigin$normalizedPath';

    return isAllowedAbsoluteUrl(resolved) ? resolved : null;
  }

  static bool isAllowedAbsoluteUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return false;
    }

    if (kReleaseMode) {
      return scheme == 'https';
    }

    return true;
  }

  static String get baseOrigin {
    final uri = endpointUri('/');

    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static String get _validatedBaseUrl {
    final candidate = _configuredBaseUrl.trim();
    if (candidate.isEmpty) {
      throw StateError('API base URL must not be empty.');
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API base URL is invalid.');
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw StateError('API base URL must use HTTP or HTTPS.');
    }

    if (kReleaseMode && scheme != 'https') {
      throw StateError(releaseHttpsErrorMessage);
    }

    return candidate;
  }

  static bool _hasAbsoluteScheme(String value) {
    final uri = Uri.tryParse(value);

    return uri != null && uri.hasScheme;
  }
}
