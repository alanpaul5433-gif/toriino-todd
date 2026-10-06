import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static void logSignUp({required String role}) {
    debugPrint('[Analytics] sign_up role=$role');
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.setCustomKey('last_event', 'sign_up');
    }
  }

  static void logLogin() {
    debugPrint('[Analytics] login');
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.setCustomKey('last_event', 'login');
    }
  }

  static void logEnroll({required String courseId}) {
    debugPrint('[Analytics] enroll courseId=$courseId');
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.setCustomKey('last_event', 'enroll');
      FirebaseCrashlytics.instance.setCustomKey('last_course_id', courseId);
    }
  }

  static void logSessionJoin({required String sessionId, required bool isMentor}) {
    debugPrint('[Analytics] session_join sessionId=$sessionId isMentor=$isMentor');
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.setCustomKey('last_event', 'session_join');
    }
  }

  static void logSubscribe({required String plan}) {
    debugPrint('[Analytics] subscribe plan=$plan');
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.setCustomKey('last_event', 'subscribe');
    }
  }
}
