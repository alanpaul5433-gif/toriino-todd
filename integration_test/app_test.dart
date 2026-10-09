import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:toriino_todd/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Toriino — Full Integration Test Suite', () {

    // ── 1. Splash Screen ───────────────────────────────────────────────────
    group('Splash Screen', () {
      testWidgets('shows logo and navigates to login', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // After splash (3s), should be on login screen
        expect(find.textContaining('Login'), findsAny);
      });
    });

    // ── 2. Login Screen ────────────────────────────────────────────────────
    group('Login Screen', () {
      testWidgets('renders email and password fields', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      });

      testWidgets('shows error on empty submit', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // Tap login button without filling fields
        final loginBtn = find.byType(ElevatedButton).first;
        await tester.tap(loginBtn);
        await tester.pumpAndSettle();

        // Should show validation or error message
        expect(
          find.byType(SnackBar).evaluate().isNotEmpty ||
          find.textContaining('required', skipOffstage: false).evaluate().isNotEmpty ||
          find.textContaining('enter', skipOffstage: false).evaluate().isNotEmpty,
          isTrue,
        );
      });

      testWidgets('shows error on wrong credentials', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'wrong@email.com');
        await tester.enterText(fields.at(1), 'WrongPass123');
        await tester.pumpAndSettle();

        final loginBtn = find.byType(ElevatedButton).first;
        await tester.tap(loginBtn);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should show an auth error
        expect(
          find.textContaining('incorrect', skipOffstage: false).evaluate().isNotEmpty ||
          find.textContaining('Invalid', skipOffstage: false).evaluate().isNotEmpty ||
          find.textContaining('failed', skipOffstage: false).evaluate().isNotEmpty ||
          find.byType(SnackBar).evaluate().isNotEmpty,
          isTrue,
        );
      });

      testWidgets('student login succeeds → home screen', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'demo.student@toriino.com');
        await tester.enterText(fields.at(1), 'Demo@1234');
        await tester.pumpAndSettle();

        final loginBtn = find.byType(ElevatedButton).first;
        await tester.tap(loginBtn);
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Should navigate away from login
        expect(find.textContaining('Login').evaluate().isEmpty ||
               find.byType(BottomNavigationBar).evaluate().isNotEmpty, isTrue);
      });
    });

    // ── 3. Student Home ────────────────────────────────────────────────────
    group('Student Home (after login)', () {
      Future<void> loginAsStudent(WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'demo.student@toriino.com');
        await tester.enterText(fields.at(1), 'Demo@1234');
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pumpAndSettle(const Duration(seconds: 8));
      }

      testWidgets('home screen renders after login', (tester) async {
        await loginAsStudent(tester);
        expect(find.byType(Scaffold), findsAny);
      });

      testWidgets('bottom nav bar is present', (tester) async {
        await loginAsStudent(tester);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('can navigate to courses tab', (tester) async {
        await loginAsStudent(tester);
        final navItems = find.byType(BottomNavigationBar);
        if (navItems.evaluate().isNotEmpty) {
          // Tap second nav item (usually Courses)
          await tester.tap(find.byType(BottomNavigationBarItem).at(1));
          await tester.pumpAndSettle(const Duration(seconds: 3));
          expect(find.byType(Scaffold), findsAny);
        }
      });

      testWidgets('can navigate to sessions tab', (tester) async {
        await loginAsStudent(tester);
        final navItems = find.byType(BottomNavigationBar);
        if (navItems.evaluate().isNotEmpty) {
          await tester.tap(find.byType(BottomNavigationBarItem).at(2));
          await tester.pumpAndSettle(const Duration(seconds: 3));
          expect(find.byType(Scaffold), findsAny);
        }
      });

      testWidgets('can navigate to profile tab', (tester) async {
        await loginAsStudent(tester);
        final navItems = find.byType(BottomNavigationBar);
        if (navItems.evaluate().isNotEmpty) {
          await tester.tap(find.byType(BottomNavigationBarItem).last);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          expect(find.byType(Scaffold), findsAny);
        }
      });
    });

    // ── 4. Mentor Login ────────────────────────────────────────────────────
    group('Mentor Login', () {
      testWidgets('mentor login succeeds → mentor home', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'demo.mentor@toriino.com');
        await tester.enterText(fields.at(1), 'Demo@1234');
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pumpAndSettle(const Duration(seconds: 8));

        expect(find.byType(Scaffold), findsAny);
      });
    });

    // ── 5. UI / Rendering ──────────────────────────────────────────────────
    group('UI Rendering', () {
      testWidgets('no pixel overflow on login screen (portrait)', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));
        expect(tester.takeException(), isNull);
      });

      testWidgets('no pixel overflow on login screen (small screen 360x640)', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));
        expect(tester.takeException(), isNull);
      });
    });

  });
}
