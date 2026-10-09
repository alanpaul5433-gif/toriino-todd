import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/viewmodel/controller/common/ai_tutor_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/common/notification_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_availability_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_earnings_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_home_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_session_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/student/course_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/student/home_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/student/mentor_list_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/student/profile_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/student/session_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/subscription/subscription_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_course_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_earnings_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_home_viewmodel.dart';

/// Ends the signed-in session completely: Cognito tokens, saved role and every GetX
/// controller that caches the user's data. Without the controller reset, the next account
/// to log in on the device saw the previous user's name, earnings and sessions until the
/// app was restarted (UAT Round 4b H5).
class SessionReset {
  SessionReset._();

  /// Signs out, opens the login screen (clearing the back stack) and, once the old screens
  /// are gone, drops the per-user controllers. [message] is shown on the login screen.
  static Future<void> logOut(BuildContext context, {String? message}) async {
    await AuthService.signOut();
    await UsersPrefrence().removeUser();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Loginview()),
      (_) => false,
    );
    if (message != null) Utils.toastMassage(message);
    // The old routes still use these controllers during the transition; delete them after.
    Future.delayed(const Duration(seconds: 1), clearUserControllers);
  }

  /// Deletes every per-user controller so the next login starts from fresh data.
  static void clearUserControllers() {
    void drop<T>() {
      if (Get.isRegistered<T>()) Get.delete<T>(force: true);
    }

    drop<HomeViewmodel>();
    drop<ProfileViewmodel>();
    drop<CourseViewmodel>();
    drop<SessionViewmodel>();
    drop<MentorListViewmodel>();
    drop<MentorHomeViewmodel>();
    drop<MentorSessionViewmodel>();
    drop<MentorEarningsViewmodel>();
    drop<MentorAvailabilityViewmodel>();
    drop<TeacherHomeViewmodel>();
    drop<TeacherCourseViewmodel>();
    drop<TeacherEarningsViewmodel>();
    drop<NotificationViewmodel>();
    drop<SubscriptionViewModel>();
    drop<AiTutorViewmodel>();
  }
}
