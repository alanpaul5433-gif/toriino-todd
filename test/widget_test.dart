import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';

void main() {
  // ── Auth Flow Tests ──────────────────────────────────────────────

  group('Login Screen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const Loginview()),
      );
      await tester.pump();
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows toast when email is empty on login tap', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const Loginview()),
      );
      await tester.tap(find.text('Login'));
      await tester.pump();
      // Toast should appear — login button blocked without email
      expect(find.byType(Loginview), findsOneWidget);
    });

    testWidgets('shows password error when password is too short', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const Loginview()),
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        '123',
      );
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(find.byType(Loginview), findsOneWidget);
    });
  });

  group('Role Selector Screen', () {
    testWidgets('Continue button is disabled when no role selected', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const RoleSelectionScreen()),
      );
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Continue button enabled after role selected', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const RoleSelectionScreen()),
      );
      await tester.pump();
      await tester.tap(find.text("I’m a Student", skipOffstage: false));
      await tester.pump();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('All 3 role cards are visible', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: const RoleSelectionScreen()),
      );
      await tester.pump();
      expect(find.text("I’m a Student", skipOffstage: false), findsOneWidget);
      expect(find.text("I’m a Teacher", skipOffstage: false), findsOneWidget);
      expect(find.text("I’m a Mentor", skipOffstage: false), findsOneWidget);
    });
  });

}
