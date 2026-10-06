import 'package:flutter_test/flutter_test.dart';

// Role normalisation logic extracted for unit testing.
// Mirrors the logic in splash_view.dart and login_view.dart.
String? normaliseRole(String? raw) => raw?.toLowerCase();

String resolveDestination(String? role) {
  final r = normaliseRole(role);
  if (r == 'student') return 'student_home';
  if (r == 'teacher') return 'teacher_home';
  if (r == 'mentor') return 'mentor_home';
  return 'role_selection';
}

void main() {
  group('Role routing — case normalisation', () {
    test('student (lowercase) routes to student home', () {
      expect(resolveDestination('student'), 'student_home');
    });

    test('teacher (lowercase) routes to teacher home', () {
      expect(resolveDestination('teacher'), 'teacher_home');
    });

    test('mentor (lowercase) routes to mentor home', () {
      expect(resolveDestination('mentor'), 'mentor_home');
    });

    test('STUDENT (uppercase) routes to student home', () {
      expect(resolveDestination('STUDENT'), 'student_home');
    });

    test('TEACHER (uppercase) routes to teacher home', () {
      expect(resolveDestination('TEACHER'), 'teacher_home');
    });

    test('MENTOR (uppercase) routes to mentor home', () {
      expect(resolveDestination('MENTOR'), 'mentor_home');
    });

    test('Teacher (title case) routes to teacher home', () {
      expect(resolveDestination('Teacher'), 'teacher_home');
    });

    test('Mentor (title case) routes to mentor home', () {
      expect(resolveDestination('Mentor'), 'mentor_home');
    });

    test('Student (title case) routes to student home', () {
      expect(resolveDestination('Student'), 'student_home');
    });

    test('unknown role routes to role selection screen', () {
      expect(resolveDestination('admin'), 'role_selection');
    });

    test('null role routes to role selection screen', () {
      expect(resolveDestination(null), 'role_selection');
    });

    test('empty string routes to role selection screen', () {
      expect(resolveDestination(''), 'role_selection');
    });
  });
}
