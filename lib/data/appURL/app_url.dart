class AppUrl {
  // TODO: Replace with your actual AWS API Gateway URL after deployment
  static const String baseUrl = 'https://YOUR_API_ID.execute-api.us-east-2.amazonaws.com/prod';

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
  static const String userAvatar = '$baseUrl/users/avatar';
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
  static const String mentorIntroVideo = '$baseUrl/mentors/intro-video';

  // Reviews
  static const String reviews = '$baseUrl/reviews';
  static String reviewsByTarget(String targetId) =>
      '$baseUrl/reviews/$targetId';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static String markNotificationRead(String sortKey) =>
      '$baseUrl/notifications/$sortKey/read';
  static const String registerFcmToken = '$baseUrl/notifications/fcm-token';

  // Earnings
  static const String earnings = '$baseUrl/earnings';
  static const String earningsHistory = '$baseUrl/earnings/history';
}
