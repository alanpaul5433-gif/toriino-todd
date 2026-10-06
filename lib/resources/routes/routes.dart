import 'package:get/get.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/reset_password_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/view/auth/sign_up_view.dart';
import 'package:toriino_todd/view/auth/splash_view.dart';
import 'package:toriino_todd/view/live_session/live_session_screen.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_public_profile.dart';
import 'package:toriino_todd/view/users/student_view/home_view.dart';
import 'package:toriino_todd/view/users/student_view/lesson_video_view.dart';
import 'package:toriino_todd/view/users/student_view/my_taken_cousre_view.dart';

class AppRoutes {
  static appRoutes() => [
    GetPage(
      name: RoutesName.splashview,
      page: () => SplashView(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.loginview,
      page: () => Loginview(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.role,
      page: () => RoleSelectionScreen(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.signup,
      page: () => Sginupview(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.homeview,
      page: () => HomeView(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.resetPassword,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return ResetPasswordView(email: args['email'] as String);
      },
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.liveSession,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return LiveSessionScreen(
          sessionId: args['sessionId'] as String,
          isMentor: args['isMentor'] as bool? ?? false,
          subjectArea: args['subjectArea'] as String? ?? 'general',
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.lessonVideo,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return LessonVideoView(
          videoUrl: args['videoUrl'] as String,
          title: args['title'] as String,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.myCourseDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return MyTakenCousreView(course: args['course'] as CourseModel?);
      },
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.mentorPublicProfile,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return MentorPublicProfile(mentor: args['mentor'] as MentorModel?);
      },
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
  ];
}
