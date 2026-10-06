import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static void logSignUp({required String role}) {
    debugPrint('[Analytics] sign_up role=$role');
    FirebaseCrashlytics.instance.setCustomKey('last_event', 'sign_up');
  }

  static void logLogin() {
    debugPrint('[Analytics] login');
    FirebaseCrashlytics.instance.setCustomKey('last_event', 'login');
  }

  static void logEnroll({required String courseId}) {
    debugPrint('[Analytics] enroll courseId=$courseId');
    FirebaseCrashlytics.instance.setCustomKey('last_event', 'enroll');
    FirebaseCrashlytics.instance.setCustomKey('last_course_id', courseId);
  }

  static void logSessionJoin({required String sessionId, required bool isMentor}) {
    debugPrint('[Analytics] session_join sessionId=$sessionId isMentor=$isMentor');
    FirebaseCrashlytics.instance.setCustomKey('last_event', 'session_join');
  }

  static void logSubscribe({required String plan}) {
    debugPrint('[Analytics] subscribe plan=$plan');
    FirebaseCrashlytics.instance.setCustomKey('last_event', 'subscribe');
  }
}
