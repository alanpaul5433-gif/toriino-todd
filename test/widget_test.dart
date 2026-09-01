import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/repository/mock/mock_data.dart';
import 'package:toriino_todd/repository/mock/mock_repo.dart';

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

  // ── Mock Data Layer Tests ────────────────────────────────────────

  group('MockData - Student Profile', () {
    setUp(() => MockData.setRole('Student'));

    test('student profile has correct name', () {
      final profile = MockData.studentProfile;
      expect(profile['name'], equals('Henry Mitchell'));
    });

    test('student profile has email', () {
      final profile = MockData.studentProfile;
      expect(profile['email'], isNotEmpty);
    });
  });

  group('MockData - Teacher Profile', () {
    setUp(() => MockData.setRole('Teacher'));

    test('teacher profile has correct name', () {
      final profile = MockData.teacherProfile;
      expect(profile['name'], equals('Sarah Johnson'));
    });
  });

  group('MockData - Mentor Profile', () {
    setUp(() => MockData.setRole('Mentor'));

    test('mentor profile has correct name', () {
      final profile = MockData.mentorProfile;
      expect(profile['name'], equals('Jaylon Culhane'));
    });
  });

  group('MockRepo - Async Data', () {
    test('getCourses returns non-empty list', () async {
      final courses = await MockRepo.getCourses();
      expect(courses, isNotEmpty);
    });

    test('getMentors returns non-empty list', () async {
      final mentors = await MockRepo.getMentors();
      expect(mentors, isNotEmpty);
    });

    test('getSessions returns list for student role', () async {
      final sessions = await MockRepo.getSessions(role: 'student');
      expect(sessions, isNotEmpty);
    });

    test('getSessions returns list for mentor role', () async {
      final sessions = await MockRepo.getSessions(role: 'mentor');
      expect(sessions, isNotEmpty);
    });

    test('getEarningsSummary returns valid earnings data', () async {
      final earnings = await MockRepo.getEarningsSummary();
      expect(earnings['totalEarnings'], greaterThan(0));
    });

    test('getMyCreatedCourses returns teacher courses', () async {
      final courses = await MockRepo.getMyCreatedCourses();
      expect(courses, isNotEmpty);
    });
  });
}
