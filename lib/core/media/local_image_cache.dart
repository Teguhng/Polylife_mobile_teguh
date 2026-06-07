import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mobile_ver/core/config/api_config.dart';
import 'package:path_provider/path_provider.dart';

class LocalImageCache {
  static const Duration _timeout = Duration(seconds: 20);
  static const String _directoryName = 'broadcast_images';

  static Future<File?> getOrFetch(
    String url, {
    bool forceRefresh = false,
    Map<String, String>? headers,
    String cacheNamespace = _directoryName,
  }) async {
    try {
      if (!ApiConfig.isAllowedAbsoluteUrl(url)) {
        return null;
      }

      final file = await _resolveFile(url, cacheNamespace: cacheNamespace);

      if (forceRefresh && await file.exists()) {
        await file.delete();
      }

      if (await file.exists() && await file.length() > 0) {
        if (await _looksLikeImageFile(file)) {
          return file;
        }

        await file.delete();
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);
      final contentType = (response.headers['content-type'] ?? '')
          .toLowerCase();

      if (response.statusCode != 200 ||
          response.bodyBytes.isEmpty ||
          (contentType.isNotEmpty && !contentType.startsWith('image/')) ||
          !_looksLikeImageBytes(response.bodyBytes)) {
        return null;
      }

      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!await _looksLikeImageFile(file)) {
        await file.delete();
        return null;
      }

      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> getOrFetchBytes(
    String url, {
    bool forceRefresh = false,
    Map<String, String>? headers,
    String cacheNamespace = _directoryName,
  }) async {
    try {
      final file = await getOrFetch(
        url,
        forceRefresh: forceRefresh,
        headers: headers,
        cacheNamespace: cacheNamespace,
      );
      if (file == null || !await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !_looksLikeImageBytes(bytes)) {
        return null;
      }

      return bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> getIfExists(
    String url, {
    String cacheNamespace = _directoryName,
  }) async {
    try {
      final file = await _resolveFile(url, cacheNamespace: cacheNamespace);
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    } catch (_) {
      // ignore and fall through
    }

    return null;
  }

  static Future<File> _resolveFile(
    String url, {
    required String cacheNamespace,
  }) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}${_safeDirectoryName(cacheNamespace)}',
    );
    final extension = _extensionFromUrl(url);
    final fileName = '${_stableHash(url)}$extension';

    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  static String _safeDirectoryName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return normalized.isEmpty ? _directoryName : normalized;
  }

  static Future<bool> _looksLikeImageFile(File file) async {
    try {
      final bytes = await file
          .openRead(0, 16)
          .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));

      return _looksLikeImageBytes(bytes);
    } catch (_) {
      return false;
    }
  }

  static bool _looksLikeImageBytes(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return true;
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return true;
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }

    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    if (bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70 &&
        ((bytes[8] == 0x61 &&
                bytes[9] == 0x76 &&
                bytes[10] == 0x69 &&
                bytes[11] == 0x66) ||
            (bytes[8] == 0x61 &&
                bytes[9] == 0x76 &&
                bytes[10] == 0x69 &&
                bytes[11] == 0x73))) {
      return true;
    }

    return false;
  }

  static String _extensionFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final index = path.lastIndexOf('.');
    if (index == -1) {
      return '.img';
    }

    final ext = path.substring(index).toLowerCase();
    if (ext.length > 6 || ext.contains('/') || ext.contains('?')) {
      return '.img';
    }

    return ext;
  }

  static String _stableHash(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return hash.toRadixString(16);
  }
}
