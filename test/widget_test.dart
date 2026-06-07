import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_ver/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          switch (call.method) {
            case 'read':
              return null;
            case 'readAll':
              return <String, String>{};
            case 'containsKey':
              return false;
            case 'write':
            case 'delete':
            case 'deleteAll':
              return null;
          }

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('Unauthenticated user lands on login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('PolyLife'), findsOneWidget);
  });

  testWidgets('Guest auth links open register and forgot password screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final registerLink = find.widgetWithText(TextButton, 'Register');
    await tester.ensureVisible(registerLink);
    await tester.pump();
    await tester.tap(registerLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('REGISTER'), findsOneWidget);
    expect(find.text('Buat akun PolyLife'), findsOneWidget);

    final loginLink = find.widgetWithText(TextButton, 'Login');
    await tester.ensureVisible(loginLink);
    await tester.pump();
    await tester.tap(loginLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final forgotPasswordLink = find.widgetWithText(
      TextButton,
      'Lupa password?',
    );
    await tester.ensureVisible(forgotPasswordLink);
    await tester.pump();
    await tester.tap(forgotPasswordLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('KIRIM LINK RESET'), findsOneWidget);
    expect(find.text('Lupa password?'), findsOneWidget);
  });
}
