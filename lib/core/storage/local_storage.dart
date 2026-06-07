import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> saveToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await removeToken();
      return;
    }

    await _secureStorage.write(key: _tokenKey, value: normalizedToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<String?> getToken() async {
    final secureToken = (await _secureStorage.read(key: _tokenKey))?.trim();
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey)?.trim();
    if (legacyToken == null || legacyToken.isEmpty) {
      if (legacyToken != null) {
        await prefs.remove(_tokenKey);
      }

      return null;
    }

    await _secureStorage.write(key: _tokenKey, value: legacyToken);
    await prefs.remove(_tokenKey);

    return legacyToken;
  }

  static Future<void> removeToken() async {
    await _secureStorage.delete(key: _tokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<User?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return User.fromJson(decoded);
      }
      if (decoded is Map) {
        return User.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      await prefs.remove(_userKey);
    }

    return null;
  }

  static Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
