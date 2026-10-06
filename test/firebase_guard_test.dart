import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/services/analytics_service.dart';

void main() {
  group('AnalyticsService — Firebase guard', () {
    // When Firebase is not initialized, Firebase.apps is empty.
    // All AnalyticsService calls must complete without throwing.

    test('logLogin does not throw when Firebase is not initialized', () {
      expect(() => AnalyticsService.logLogin(), returnsNormally);
    });

    test('logSignUp does not throw when Firebase is not initialized', () {
      expect(() => AnalyticsService.logSignUp(role: 'student'), returnsNormally);
    });

    test('logEnroll does not throw when Firebase is not initialized', () {
      expect(
        () => AnalyticsService.logEnroll(courseId: 'course-123'),
        returnsNormally,
      );
    });

    test('logSessionJoin does not throw when Firebase is not initialized', () {
      expect(
        () => AnalyticsService.logSessionJoin(
          sessionId: 'session-abc',
          isMentor: false,
        ),
        returnsNormally,
      );
    });

    test('logSubscribe does not throw when Firebase is not initialized', () {
      expect(
        () => AnalyticsService.logSubscribe(plan: 'premium'),
        returnsNormally,
      );
    });
  });
}
