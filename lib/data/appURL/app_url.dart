class AppUrl {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod',
  );

  // Auth (public - no token required)
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String verifyEmail = '$baseUrl/auth/verify';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String setRole = '$baseUrl/auth/set-role';
  static const String logout = '$baseUrl/auth/logout';

  // Users
  static const String userProfile = '$baseUrl/users/profile';
  static const String userRole = '$baseUrl/users/role';
  static const String deleteAccount = '$baseUrl/users/account';

  // Courses
  static const String courses = '$baseUrl/courses';
  static const String myCourses = '$baseUrl/courses/my-courses';
  static const String myCreatedCourses = '$baseUrl/courses/my-created';
  static String courseById(String id) => '$baseUrl/courses/$id';
  static String courseLessons(String id) => '$baseUrl/courses/$id/lessons';
  static String courseLesson(String courseId, String lessonId) =>
      '$baseUrl/courses/$courseId/lessons/$lessonId';
  static String enrollCourse(String id) => '$baseUrl/courses/$id/enroll';
  /// Marks the caller's own active enrollment completed (idempotent).
  static String completeCourse(String id) => '$baseUrl/courses/$id/complete';
  /// Pre-signed (300 s) GET URLs for a lesson's private video/material.
  static String lessonMedia(String courseId, String lessonId) =>
      '$baseUrl/courses/$courseId/lessons/$lessonId/media';

  // Sessions
  static const String sessions = '$baseUrl/sessions';
  static String sessionById(String id) => '$baseUrl/sessions/$id';
  static String sessionStatus(String id) => '$baseUrl/sessions/$id/status';

  // Mentors
  static const String mentors = '$baseUrl/mentors';
  static String mentorById(String id) => '$baseUrl/mentors/$id';
  static String mentorAvailability(String id) =>
      '$baseUrl/mentors/$id/availability';
  static const String updateAvailability = '$baseUrl/mentors/availability';

  // Reviews
  static const String reviews = '$baseUrl/reviews';
  static String reviewsByTarget(String targetId) =>
      '$baseUrl/reviews/$targetId';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static String markNotificationRead(String sortKey) =>
      '$baseUrl/notifications/${Uri.encodeComponent(sortKey)}/read';
  static const String registerFcmToken = '$baseUrl/notifications/fcm-token';

  // Earnings
  static const String earnings = '$baseUrl/earnings';
  static const String earningsHistory = '$baseUrl/earnings/history';

  // Upload — pre-signed S3 PUT URL (P2-2)
  static const String uploadUrl = '$baseUrl/upload-url';

  // Agora token (server-generated, never on client)
  static const String agoraToken = '$baseUrl/sessions/token';

  // Session recording
  static String startRecording(String sessionId) =>
      '$baseUrl/sessions/$sessionId/recording/start';
  static String stopRecording(String sessionId) =>
      '$baseUrl/sessions/$sessionId/recording/stop';

  // AI — session intelligence
  static String sessionSummary(String sessionId) =>
      '$baseUrl/sessions/$sessionId/summary';
  static String sessionTranscript(String sessionId) =>
      '$baseUrl/sessions/$sessionId/transcript';

  // AI — chat history per user
  static String aiChat(String userId) => '$baseUrl/ai/chat/$userId';

  // AI — AI Twins
  static String aiTwin(String userId) => '$baseUrl/ai/twins/$userId';

  // AI — user memory (progress, activity, preferences)
  static String aiMemory(String userId) => '$baseUrl/ai/memory/$userId';

  // Wallet
  static const String walletBalance = '$baseUrl/wallet';
  static const String walletDeduct = '$baseUrl/wallet/deduct';

  // Student search (mentor 1-on-1 session scheduling)
  static String studentSearch(String query) =>
      '$baseUrl/students/search?q=${Uri.encodeQueryComponent(query)}';
}
