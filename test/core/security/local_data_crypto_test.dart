import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/core/security/local_data_crypto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = call.arguments is Map
              ? Map<Object?, Object?>.from(call.arguments as Map)
              : const <Object?, Object?>{};
          final key = args['key']?.toString();

          switch (call.method) {
            case 'read':
              return key == null ? null : storage[key];
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'containsKey':
              return key != null && storage.containsKey(key);
            case 'write':
              if (key != null) {
                storage[key] = args['value']?.toString() ?? '';
              }
              return null;
            case 'delete':
              if (key != null) {
                storage.remove(key);
              }
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
          }

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('encrypts and decrypts a local string for the same user', () async {
    const plainText = 'Catatan rahasia untuk sync offline.';

    final encrypted = await LocalDataCrypto.encryptString(10, plainText);

    expect(LocalDataCrypto.isEncryptedString(encrypted), isTrue);
    expect(encrypted, isNot(plainText));
    expect(encrypted.contains(plainText), isFalse);
    expect(await LocalDataCrypto.decryptString(10, encrypted), plainText);
  });

  test('does not decrypt encrypted data with a different user key', () async {
    final encrypted = await LocalDataCrypto.encryptString(
      11,
      'Isi milik user 11',
    );

    expect(await LocalDataCrypto.tryDecryptString(12, encrypted), isNull);
  });

  test('keeps legacy plaintext readable during gradual migration', () async {
    expect(
      await LocalDataCrypto.decryptString(13, 'legacy plain'),
      'legacy plain',
    );
    expect(await LocalDataCrypto.encryptString(13, ''), '');
  });

  test('deleted local key makes old encrypted cache unreadable', () async {
    final encrypted = await LocalDataCrypto.encryptString(
      14,
      'Cache lokal lama',
    );

    await LocalDataCrypto.deleteUserKey(14);

    expect(await LocalDataCrypto.tryDecryptString(14, encrypted), isNull);
  });
}
