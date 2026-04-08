/// Mock data for all roles — Student, Teacher, Mentor.
/// When AWS is ready, remove this file and point repos to real API.

class MockData {
  // ── Student Profile ───────────────────────────────────
  static Map<String, dynamic> studentProfile = {
    'userId': 'usr_001',
    'name': 'Henry Mitchell',
    'email': 'henry@toriino.com',
    'phone': '+1 234 567 8900',
    'role': 'Student',
    'bio': 'Passionate learner interested in UI/UX Design and Mobile Development.',
    'avatarUrl': '',
    'dateOfBirth': '1998-05-14',
    'location': 'Ohio, United States',
    'interests': ['UI/UX Design', 'Flutter', 'Product Management'],
    'createdAt': '2026-01-15T10:30:00Z',
    'updatedAt': '2026-04-01T08:00:00Z',
  };

  // ── Teacher Profile ───────────────────────────────────
  static Map<String, dynamic> teacherProfile = {
    'userId': 'tch_001',
    'name': 'Sarah Johnson',
    'email': 'sarah@toriino.com',
    'phone': '+1 345 678 9012',
    'role': 'Teacher',
    'bio': 'Senior UI/UX Designer and educator with 10+ years of experience. Teaching design thinking and prototyping.',
    'avatarUrl': '',
    'location': 'New York, United States',
    'subjects': ['UI/UX Design', 'Figma', 'Design Systems'],
    'qualification': 'M.A. in Interaction Design',
    'yearsOfExperience': 10,
    'rating': 4.8,
    'totalCourses': 4,
    'totalStudents': 532,
    'createdAt': '2025-09-01T10:00:00Z',
  };

  // ── Mentor Profile ────────────────────────────────────
  static Map<String, dynamic> mentorProfile = {
    'userId': 'mnt_001',
    'name': 'Jaylon Culhane',
    'email': 'jaylon@toriino.com',
    'phone': '+1 456 789 0123',
    'role': 'Mentor',
    'bio': 'Senior UX Designer with 8+ years at top tech companies. Passionate about mentoring the next generation of designers.',
    'avatarUrl': '',
    'location': 'San Francisco, United States',
    'expertise': ['UI/UX Design', 'Product Design', 'Design Systems'],
    'hourlyRate': 45.0,
    'rating': 4.9,
    'totalSessions': 142,
    'totalStudents': 56,
    'introVideoUrl': '',
    'createdAt': '2025-06-01T10:00:00Z',
  };

  /// Returns profile based on active role
  static Map<String, dynamic> userProfile = studentProfile;

  static void setRole(String role) {
    if (role == 'Teacher') {
      userProfile = teacherProfile;
    } else if (role == 'Mentor') {
      userProfile = mentorProfile;
    } else {
      userProfile = studentProfile;
    }
  }

  // ── Courses ───────────────────────────────────────────
  static List<Map<String, dynamic>> courses = [
    {
      'courseId': 'crs_001',
      'teacherId': 'tch_001',
      'title': 'UI/UX Design Fundamentals',
      'description': 'Learn the core principles of user interface and user experience design. From wireframing to prototyping.',
      'category': 'Design',
      'duration': '8 weeks',
      'price': 29.99,
      'imageUrl': '',
      'level': 'Beginner',
      'rating': 4.8,
      'enrollmentCount': 234,
      'status': 'published',
      'createdAt': '2026-02-01T10:00:00Z',
      'teacherName': 'Sarah Johnson',
    },
    {
      'courseId': 'crs_002',
      'teacherId': 'tch_002',
      'title': 'Flutter Mobile Development',
      'description': 'Build beautiful cross-platform mobile apps with Flutter and Dart from scratch.',
      'category': 'Programming',
      'duration': '12 weeks',
      'price': 49.99,
      'imageUrl': '',
      'level': 'Intermediate',
      'rating': 4.9,
      'enrollmentCount': 189,
      'status': 'published',
      'createdAt': '2026-01-15T10:00:00Z',
      'teacherName': 'Alex Chen',
    },
    {
      'courseId': 'crs_003',
      'teacherId': 'tch_003',
      'title': 'Product Management Essentials',
      'description': 'Master the skills needed to become a successful product manager in the tech industry.',
      'category': 'Business',
      'duration': '6 weeks',
      'price': 39.99,
      'imageUrl': '',
      'level': 'Beginner',
      'rating': 4.6,
      'enrollmentCount': 156,
      'status': 'published',
      'createdAt': '2026-03-01T10:00:00Z',
      'teacherName': 'Maria Garcia',
    },
    {
      'courseId': 'crs_004',
      'teacherId': 'tch_001',
      'title': 'Advanced Figma Masterclass',
      'description': 'Take your Figma skills to the next level with advanced prototyping, auto-layout and components.',
      'category': 'Design',
      'duration': '4 weeks',
      'price': 19.99,
      'imageUrl': '',
      'level': 'Advanced',
      'rating': 4.7,
      'enrollmentCount': 98,
      'status': 'published',
      'createdAt': '2026-03-15T10:00:00Z',
      'teacherName': 'Sarah Johnson',
    },
    {
      'courseId': 'crs_005',
      'teacherId': 'tch_004',
      'title': 'Data Science with Python',
      'description': 'Introduction to data analysis, visualization and machine learning with Python.',
      'category': 'Programming',
      'duration': '10 weeks',
      'price': 59.99,
      'imageUrl': '',
      'level': 'Intermediate',
      'rating': 4.5,
      'enrollmentCount': 312,
      'status': 'published',
      'createdAt': '2026-02-20T10:00:00Z',
      'teacherName': 'David Kim',
    },
  ];

  // Teacher's own courses (tch_001 = Sarah Johnson)
  static List<Map<String, dynamic>> teacherCourses = [
    courses[0], // UI/UX Design Fundamentals
    courses[3], // Advanced Figma Masterclass
  ];

  static List<Map<String, dynamic>> enrolledCourses = [
    {
      ...courses[0],
      'enrollment': {'studentId': 'usr_001', 'courseId': 'crs_001', 'enrolledAt': '2026-03-10T10:00:00Z', 'progress': 65, 'status': 'active'},
    },
    {
      ...courses[1],
      'enrollment': {'studentId': 'usr_001', 'courseId': 'crs_002', 'enrolledAt': '2026-02-20T10:00:00Z', 'progress': 30, 'status': 'active'},
    },
  ];

  // ── Lessons ───────────────────────────────────────────
  static List<Map<String, dynamic>> lessons = [
    {'courseId': 'crs_001', 'lessonId': 'lsn_001', 'title': 'Introduction to Design Thinking', 'description': 'Understanding the design process and user-centered design.', 'videoUrl': '', 'duration': '45 min', 'order': 1},
    {'courseId': 'crs_001', 'lessonId': 'lsn_002', 'title': 'Wireframing Basics', 'description': 'Learn to create low-fidelity wireframes.', 'videoUrl': '', 'duration': '60 min', 'order': 2},
    {'courseId': 'crs_001', 'lessonId': 'lsn_003', 'title': 'Color Theory & Typography', 'description': 'Selecting colors and fonts for your designs.', 'videoUrl': '', 'duration': '50 min', 'order': 3},
    {'courseId': 'crs_001', 'lessonId': 'lsn_004', 'title': 'Prototyping in Figma', 'description': 'Creating interactive prototypes.', 'videoUrl': '', 'duration': '55 min', 'order': 4},
  ];

  // ── Mentors ───────────────────────────────────────────
  static List<Map<String, dynamic>> mentors = [
    {'userId': 'mnt_001', 'name': 'Jaylon Culhane', 'email': 'jaylon@toriino.com', 'avatarUrl': '', 'bio': 'Senior UX Designer with 8+ years at top tech companies. Passionate about mentoring the next generation.', 'expertise': ['UI/UX Design', 'Product Design', 'Design Systems'], 'hourlyRate': 45.0, 'rating': 4.9, 'totalSessions': 142, 'totalStudents': 56, 'introVideoUrl': ''},
    {'userId': 'mnt_002', 'name': 'Giana Rhiel Madsen', 'email': 'giana@toriino.com', 'avatarUrl': '', 'bio': 'Full-stack developer and technical mentor. Specializing in Flutter, React and cloud architecture.', 'expertise': ['Flutter', 'React', 'Cloud Architecture'], 'hourlyRate': 55.0, 'rating': 4.8, 'totalSessions': 98, 'totalStudents': 41, 'introVideoUrl': ''},
    {'userId': 'mnt_003', 'name': 'Emerson Dorwart', 'email': 'emerson@toriino.com', 'avatarUrl': '', 'bio': 'Product Manager at a Fortune 500 company. Helping aspiring PMs break into the industry.', 'expertise': ['Product Management', 'Agile', 'Strategy'], 'hourlyRate': 60.0, 'rating': 4.7, 'totalSessions': 76, 'totalStudents': 33, 'introVideoUrl': ''},
    {'userId': 'mnt_004', 'name': 'Kadin Lipshutz', 'email': 'kadin@toriino.com', 'avatarUrl': '', 'bio': 'Data scientist and AI researcher. Teaching data analysis and machine learning concepts.', 'expertise': ['Data Science', 'Python', 'Machine Learning'], 'hourlyRate': 50.0, 'rating': 4.6, 'totalSessions': 64, 'totalStudents': 28, 'introVideoUrl': ''},
    {'userId': 'mnt_005', 'name': 'Lindsey Schleifer', 'email': 'lindsey@toriino.com', 'avatarUrl': '', 'bio': 'Creative director specializing in brand identity and visual design.', 'expertise': ['Branding', 'Visual Design', 'Illustration'], 'hourlyRate': 40.0, 'rating': 4.8, 'totalSessions': 89, 'totalStudents': 37, 'introVideoUrl': ''},
  ];

  // ── Availability ──────────────────────────────────────
  static List<Map<String, dynamic>> availability = [
    {'mentorId': 'mnt_001', 'slotId': 'sl_1', 'dayOfWeek': 'Monday', 'startTime': '09:00', 'endTime': '12:00', 'isRecurring': true},
    {'mentorId': 'mnt_001', 'slotId': 'sl_2', 'dayOfWeek': 'Tuesday', 'startTime': '14:00', 'endTime': '17:00', 'isRecurring': true},
    {'mentorId': 'mnt_001', 'slotId': 'sl_3', 'dayOfWeek': 'Wednesday', 'startTime': '09:00', 'endTime': '12:00', 'isRecurring': true},
    {'mentorId': 'mnt_001', 'slotId': 'sl_4', 'dayOfWeek': 'Thursday', 'startTime': '14:00', 'endTime': '17:00', 'isRecurring': true},
    {'mentorId': 'mnt_001', 'slotId': 'sl_5', 'dayOfWeek': 'Friday', 'startTime': '10:00', 'endTime': '13:00', 'isRecurring': true},
  ];

  // ── Sessions (used by both student & mentor) ──────────
  static List<Map<String, dynamic>> sessions = [
    {'sessionId': 'ses_001', 'studentId': 'usr_001', 'mentorId': 'mnt_001', 'dateTime': '2026-04-10T10:00:00Z', 'duration': 60, 'topic': 'Portfolio Review', 'notes': 'Bring 3 case studies for review', 'status': 'scheduled', 'meetingLink': 'https://meet.google.com/abc-defg-hij', 'mentorName': 'Jaylon Culhane', 'studentName': 'Henry Mitchell'},
    {'sessionId': 'ses_002', 'studentId': 'usr_002', 'mentorId': 'mnt_001', 'dateTime': '2026-04-11T14:00:00Z', 'duration': 45, 'topic': 'Design Systems Workshop', 'notes': '', 'status': 'scheduled', 'meetingLink': 'https://meet.google.com/xyz-abcd-efg', 'mentorName': 'Jaylon Culhane', 'studentName': 'Emma Watson'},
    {'sessionId': 'ses_003', 'studentId': 'usr_003', 'mentorId': 'mnt_001', 'dateTime': '2026-04-08T09:00:00Z', 'duration': 60, 'topic': 'UX Research Methods', 'notes': '', 'status': 'in_progress', 'meetingLink': 'https://meet.google.com/lmn-opqr-stu', 'mentorName': 'Jaylon Culhane', 'studentName': 'Liam Parker'},
    {'sessionId': 'ses_004', 'studentId': 'usr_001', 'mentorId': 'mnt_001', 'dateTime': '2026-04-05T09:00:00Z', 'duration': 60, 'topic': 'Career Guidance', 'notes': '', 'status': 'completed', 'meetingLink': '', 'mentorName': 'Jaylon Culhane', 'studentName': 'Henry Mitchell'},
    {'sessionId': 'ses_005', 'studentId': 'usr_004', 'mentorId': 'mnt_001', 'dateTime': '2026-04-03T11:00:00Z', 'duration': 60, 'topic': 'Design Systems Deep Dive', 'notes': '', 'status': 'completed', 'meetingLink': '', 'mentorName': 'Jaylon Culhane', 'studentName': 'Sophia Chen'},
  ];

  // ── Earnings (used by teacher & mentor) ────────────────
  static Map<String, dynamic> earningsSummary = {
    'currentMonth': {'userId': 'tch_001', 'periodKey': '2026-04', 'amount': 540.00, 'sessions': 12},
    'totalEarnings': 4280.00,
    'monthlyBreakdown': [
      {'userId': 'tch_001', 'periodKey': '2026-04', 'amount': 540.00, 'sessions': 12},
      {'userId': 'tch_001', 'periodKey': '2026-03', 'amount': 720.00, 'sessions': 16},
      {'userId': 'tch_001', 'periodKey': '2026-02', 'amount': 650.00, 'sessions': 14},
      {'userId': 'tch_001', 'periodKey': '2026-01', 'amount': 480.00, 'sessions': 10},
      {'userId': 'tch_001', 'periodKey': '2025-12', 'amount': 390.00, 'sessions': 8},
      {'userId': 'tch_001', 'periodKey': '2025-11', 'amount': 510.00, 'sessions': 11},
    ],
  };

  static List<Map<String, dynamic>> earningsHistory = [
    {'userId': 'tch_001', 'periodKey': '2026-04', 'amount': 540.00, 'sessions': 12},
    {'userId': 'tch_001', 'periodKey': '2026-03', 'amount': 720.00, 'sessions': 16},
    {'userId': 'tch_001', 'periodKey': '2026-02', 'amount': 650.00, 'sessions': 14},
    {'userId': 'tch_001', 'periodKey': '2026-01', 'amount': 480.00, 'sessions': 10},
    {'userId': 'tch_001', 'periodKey': '2025-12', 'amount': 390.00, 'sessions': 8},
    {'userId': 'tch_001', 'periodKey': '2025-11', 'amount': 510.00, 'sessions': 11},
  ];

  // ── Reviews ───────────────────────────────────────────
  static List<Map<String, dynamic>> reviews = [
    {'targetId': 'mnt_001', 'reviewId': 'rev_001', 'reviewerId': 'usr_002', 'rating': 5, 'comment': 'Incredible mentor! Helped me land my first UX role.', 'targetType': 'mentor', 'createdAt': '2026-03-20T10:00:00Z'},
    {'targetId': 'mnt_001', 'reviewId': 'rev_002', 'reviewerId': 'usr_003', 'rating': 5, 'comment': 'Very insightful sessions. Highly recommend!', 'targetType': 'mentor', 'createdAt': '2026-03-15T10:00:00Z'},
    {'targetId': 'mnt_001', 'reviewId': 'rev_003', 'reviewerId': 'usr_004', 'rating': 4, 'comment': 'Great feedback on my portfolio.', 'targetType': 'mentor', 'createdAt': '2026-03-10T10:00:00Z'},
  ];

  // ── Notifications ─────────────────────────────────────
  static List<Map<String, dynamic>> notifications = [
    {'userId': 'usr_001', 'sortKey': '2026-04-07T09:00:00Z#n001', 'title': 'Session Reminder', 'message': 'Your session with Jaylon Culhane starts in 3 days.', 'type': 'session', 'isRead': false, 'createdAt': '2026-04-07T09:00:00Z'},
    {'userId': 'usr_001', 'sortKey': '2026-04-06T14:30:00Z#n002', 'title': 'Course Update', 'message': 'New lesson added to UI/UX Design Fundamentals.', 'type': 'course', 'isRead': false, 'createdAt': '2026-04-06T14:30:00Z'},
    {'userId': 'usr_001', 'sortKey': '2026-04-05T10:00:00Z#n003', 'title': 'Session Completed', 'message': 'Your session with Emerson Dorwart is complete. Leave a review!', 'type': 'session', 'isRead': true, 'createdAt': '2026-04-05T10:00:00Z'},
    {'userId': 'usr_001', 'sortKey': '2026-04-04T08:00:00Z#n004', 'title': 'Welcome to Toriino!', 'message': 'Start exploring courses and mentors to begin your learning journey.', 'type': 'general', 'isRead': true, 'createdAt': '2026-04-04T08:00:00Z'},
  ];
}
