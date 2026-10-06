// Basic smoke test for the login screen.
//
// NOTE: Loginview depends on FlutterSecureStorage and FCM services that use
// platform channels.  Running this test on the pure Dart VM host will throw
// MissingPluginException for those channels.  Execute on a real device or
// emulator with `flutter test --device-id <id>`, or use flutter_test with a
// properly initialised binding.
//
// The test is intentionally minimal: it only verifies the screen mounts
// without crashing and contains at least one TextField.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/view/auth/login_view.dart';

void main() {
  testWidgets('Login screen renders email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Loginview()));
    // Allow any async frame work to settle.
    await tester.pump();
    // The login form must contain at least the email and password TextFields.
    expect(find.byType(TextField), findsWidgets);
  });
}
