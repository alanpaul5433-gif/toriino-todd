import 'package:getxmvvm/repository/mock/mock_data.dart';

/// Mock repository that simulates API responses with local data.
/// Replace with real repos when AWS backend is deployed.
class MockRepo {
  static Future<T> _delay<T>(T data, {int ms = 500}) async {
    await Future.delayed(Duration(milliseconds: ms));
    return data;
  }

  // ── User ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() =>
      _delay(MockData.userProfile);

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) {
    MockData.userProfile.addAll(data);
    return _delay(MockData.userProfile);
  }

  // ── Courses (browsing) ────────────────────────────────
  static Future<Map<String, dynamic>> getCourses({String? category}) {
    List<Map<String, dynamic>> filtered = MockData.courses;
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((c) => c['category'] == category).toList();
    }
    return _delay({'courses': filtered, 'count': filtered.length});
  }

  static Future<Map<String, dynamic>> getCourseById(String courseId) {
    final course = MockData.courses.firstWhere(
      (c) => c['courseId'] == courseId,
      orElse: () => {},
    );
    return _delay(course);
  }

  static Future<Map<String, dynamic>> getMyEnrolledCourses() =>
      _delay({'courses': MockData.enrolledCourses, 'count': MockData.enrolledCourses.length});

  static Future<Map<String, dynamic>> enrollCourse(String courseId) {
    final enrollment = {
      'studentId': 'usr_001',
      'courseId': courseId,
      'enrolledAt': DateTime.now().toIso8601String(),
      'progress': 0,
      'status': 'active',
    };
    return _delay(enrollment);
  }

  static Future<Map<String, dynamic>> getLessons(String courseId) =>
      _delay({'lessons': MockData.lessons});

  // ── Teacher Courses (my created) ──────────────────────
  static Future<Map<String, dynamic>> getMyCreatedCourses() =>
      _delay({'courses': MockData.teacherCourses, 'count': MockData.teacherCourses.length});

  static Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) {
    final course = {
      'courseId': 'crs_${DateTime.now().millisecondsSinceEpoch}',
      'teacherId': 'tch_001',
      ...data,
      'rating': 0.0,
      'enrollmentCount': 0,
      'status': 'draft',
      'createdAt': DateTime.now().toIso8601String(),
    };
    MockData.teacherCourses.add(course);
    MockData.courses.add(course);
    return _delay(course);
  }

  static Future<Map<String, dynamic>> addLesson(String courseId, Map<String, dynamic> data) {
    final lesson = {
      'courseId': courseId,
      'lessonId': 'lsn_${DateTime.now().millisecondsSinceEpoch}',
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
    };
    MockData.lessons.add(lesson);
    return _delay(lesson);
  }

  // ── Mentors ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getMentors({String? expertise}) {
    List<Map<String, dynamic>> filtered = MockData.mentors;
    if (expertise != null && expertise.isNotEmpty) {
      filtered = filtered
          .where((m) => (m['expertise'] as List).any(
              (e) => e.toString().toLowerCase().contains(expertise.toLowerCase())))
          .toList();
    }
    return _delay({'mentors': filtered, 'count': filtered.length});
  }

  static Future<Map<String, dynamic>> getMentorById(String mentorId) {
    final mentor = MockData.mentors.firstWhere(
      (m) => m['userId'] == mentorId,
      orElse: () => {},
    );
    return _delay(mentor);
  }

  static Future<Map<String, dynamic>> getAvailability(String mentorId) =>
      _delay({'slots': MockData.availability});

  static Future<Map<String, dynamic>> updateAvailability(Map<String, dynamic> data) {
    if (data['slots'] != null) {
      MockData.availability = List<Map<String, dynamic>>.from(
        (data['slots'] as List).map((s) => Map<String, dynamic>.from(s)),
      );
    }
    return _delay({'slots': MockData.availability});
  }

  // ── Sessions ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getSessions({String role = 'student'}) {
    List<Map<String, dynamic>> filtered;
    if (role == 'mentor') {
      filtered = MockData.sessions.where((s) => s['mentorId'] == 'mnt_001').toList();
    } else {
      filtered = MockData.sessions.where((s) => s['studentId'] == 'usr_001').toList();
    }
    return _delay({'sessions': filtered, 'count': filtered.length});
  }

  static Future<Map<String, dynamic>> bookSession(Map<String, dynamic> data) {
    final session = {
      'sessionId': 'ses_${DateTime.now().millisecondsSinceEpoch}',
      'studentId': 'usr_001',
      ...data,
      'status': 'scheduled',
      'createdAt': DateTime.now().toIso8601String(),
    };
    MockData.sessions.insert(0, session);
    return _delay(session);
  }

  // ── Earnings ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getEarningsSummary() =>
      _delay(MockData.earningsSummary);

  static Future<Map<String, dynamic>> getEarningsHistory() =>
      _delay({'history': MockData.earningsHistory, 'count': MockData.earningsHistory.length});

  // ── Reviews ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getReviews(String targetId) {
    final filtered = MockData.reviews.where((r) => r['targetId'] == targetId).toList();
    return _delay({'reviews': filtered, 'count': filtered.length});
  }

  static Future<Map<String, dynamic>> submitReview(Map<String, dynamic> data) {
    final review = {
      'reviewId': 'rev_${DateTime.now().millisecondsSinceEpoch}',
      'reviewerId': 'usr_001',
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
    };
    MockData.reviews.add(review);
    return _delay(review);
  }

  // ── Notifications ─────────────────────────────────────
  static Future<Map<String, dynamic>> getNotifications() =>
      _delay({'notifications': MockData.notifications, 'count': MockData.notifications.length});

  static Future<Map<String, dynamic>> markNotificationRead(String sortKey) {
    final notif = MockData.notifications.firstWhere(
      (n) => n['sortKey'] == sortKey,
      orElse: () => {},
    );
    if (notif.isNotEmpty) notif['isRead'] = true;
    return _delay(notif);
  }
}
