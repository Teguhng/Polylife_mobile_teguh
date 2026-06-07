import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDataCryptoException implements Exception {
  const LocalDataCryptoException(this.message);

  final String message;

  @override
  String toString() => 'LocalDataCryptoException: $message';
}

class LocalDataCrypto {
  const LocalDataCrypto._();

  static const String _prefix = 'plc:v1';
  static final AesGcm _cipher = AesGcm.with256bits();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static bool isEncryptedString(String? value) {
    return value != null && value.startsWith('$_prefix:');
  }

  static Future<String> encryptString(int userId, String value) async {
    if (value.isEmpty || userId <= 0 || isEncryptedString(value)) {
      return value;
    }

    final secretKey = await _secretKeyForUser(userId);
    final nonce = _cipher.newNonce();
    final box = await _cipher.encrypt(
      utf8.encode(value),
      secretKey: secretKey,
      nonce: nonce,
      aad: _aadForUser(userId),
    );

    return [
      _prefix,
      base64Url.encode(box.nonce),
      base64Url.encode(box.mac.bytes),
      base64Url.encode(box.cipherText),
    ].join(':');
  }

  static Future<String> decryptString(int userId, String value) async {
    final decrypted = await tryDecryptString(userId, value);
    if (decrypted == null) {
      throw const LocalDataCryptoException(
        'Data lokal terenkripsi tidak bisa dibuka.',
      );
    }

    return decrypted;
  }

  static Future<String?> tryDecryptString(int userId, String value) async {
    if (value.isEmpty || userId <= 0 || !isEncryptedString(value)) {
      return value;
    }

    final parts = value.split(':');
    if (parts.length != 5 || '${parts[0]}:${parts[1]}' != _prefix) {
      return null;
    }

    try {
      final secretKey = await _secretKeyForUser(userId);
      final box = SecretBox(
        base64Url.decode(parts[4]),
        nonce: base64Url.decode(parts[2]),
        mac: Mac(base64Url.decode(parts[3])),
      );
      final clearBytes = await _cipher.decrypt(
        box,
        secretKey: secretKey,
        aad: _aadForUser(userId),
      );

      return utf8.decode(clearBytes);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUserKey(int userId) async {
    if (userId <= 0) {
      return;
    }

    await _secureStorage.delete(key: _keyName(userId));
  }

  static Future<SecretKey> _secretKeyForUser(int userId) async {
    final keyName = _keyName(userId);
    final existing = await _secureStorage.read(key: keyName);
    final existingBytes = _decodeKey(existing);
    if (existingBytes != null) {
      return _cipher.newSecretKeyFromBytes(existingBytes);
    }

    final secretKey = await _cipher.newSecretKey();
    final secretBytes = await secretKey.extractBytes();
    await _secureStorage.write(
      key: keyName,
      value: base64Url.encode(secretBytes),
    );

    return secretKey;
  }

  static List<int>? _decodeKey(String? rawKey) {
    if (rawKey == null || rawKey.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = base64Url.decode(rawKey);
      return decoded.length == 32 ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static List<int> _aadForUser(int userId) {
    return utf8.encode('polylife:local-data:v1:user:$userId');
  }

  static String _keyName(int userId) {
    return 'local_data_key_user_$userId';
  }
}
