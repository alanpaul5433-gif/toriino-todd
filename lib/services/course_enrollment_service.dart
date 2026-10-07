import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/services/stripe_service.dart';
import 'package:toriino_todd/utils/utils.dart';

enum EnrollOutcome {
  /// The course is confirmed in GET /courses/my-courses (or the free enroll
  /// call returned 2xx).
  enrolled,

  /// Payment succeeded but the webhook had not enrolled the student before the
  /// polling window ended. Not a failure — the course will appear shortly.
  pendingConfirmation,

  /// The user dismissed the PaymentSheet.
  cancelled,

  /// Enrollment or payment failed; [EnrollResult.message] has the reason.
  failed,
}

class EnrollResult {
  final EnrollOutcome outcome;
  final String message;
  final bool paid;
  const EnrollResult(this.outcome, this.message, {this.paid = false});

  bool get isEnrolled => outcome == EnrollOutcome.enrolled;
}

typedef CoursePurchaser = Future<Map<String, dynamic>> Function({
  required String courseId,
  required String courseTitle,
});

/// Real enrollment flow for the backend contract:
///
/// * Free course (price 0) → POST /courses/{id}/enroll (201).
/// * Paid course → StripeService.purchaseCourse (server computes the price).
///   After the PaymentSheet succeeds the app does NOT call enroll — the Stripe
///   webhook enrolls the student. The app polls GET /courses/my-courses until
///   the course appears (default every 2 s for up to 30 s).
/// * If enroll unexpectedly answers 402, the paid flow is used instead.
class CourseEnrollmentService {
  static const String finishingMessage =
      'Payment received — finishing enrollment…';
  static const String pendingMessage =
      'Your payment is being processed. Check My Courses shortly — the course '
      'will appear there as soon as enrollment completes.';

  final CourseRepo _repo;
  final CoursePurchaser _purchase;
  final Duration pollInterval;
  final Duration pollTimeout;

  CourseEnrollmentService({
    CourseRepo? repo,
    CoursePurchaser? purchase,
    this.pollInterval = const Duration(seconds: 2),
    this.pollTimeout = const Duration(seconds: 30),
  })  : _repo = repo ?? CourseRepo(),
        _purchase = purchase ?? StripeService.purchaseCourse;

  Future<EnrollResult> enroll(
    CourseModel course, {
    void Function(String status)? onStatus,
  }) async {
    final courseId = course.courseId ?? '';
    if (courseId.isEmpty) {
      return const EnrollResult(EnrollOutcome.failed, 'Course not found.');
    }

    if ((course.displayPrice ?? 0) <= 0) {
      onStatus?.call('Enrolling…');
      try {
        await _repo.enrollCourse(courseId);
        return const EnrollResult(EnrollOutcome.enrolled, "You're enrolled!");
      } on PaymentRequiredException {
        // Server says the course is paid (price changed or stale list data).
      } catch (e) {
        return EnrollResult(EnrollOutcome.failed, Utils.errorMessage(e));
      }
    }

    return _purchaseAndConfirm(course, courseId, onStatus);
  }

  Future<EnrollResult> _purchaseAndConfirm(
    CourseModel course,
    String courseId,
    void Function(String status)? onStatus,
  ) async {
    // Don't charge twice: if already enrolled, stop here.
    if (await isEnrolled(courseId)) {
      return const EnrollResult(
          EnrollOutcome.enrolled, "You're already enrolled in this course.");
    }

    onStatus?.call('Opening secure payment…');
    final result = await _purchase(
      courseId: courseId,
      courseTitle: course.title ?? 'Course',
    );
    if (result['success'] != true) {
      final msg = (result['message'] as String?)?.trim();
      if (result['cancelled'] == true) {
        return EnrollResult(EnrollOutcome.cancelled,
            (msg == null || msg.isEmpty) ? 'Payment cancelled' : msg);
      }
      return EnrollResult(EnrollOutcome.failed,
          (msg == null || msg.isEmpty) ? 'Payment failed' : msg);
    }

    onStatus?.call(finishingMessage);
    final confirmed = await waitForEnrollment(courseId);
    if (confirmed) {
      return const EnrollResult(EnrollOutcome.enrolled, "You're enrolled!",
          paid: true);
    }
    return const EnrollResult(EnrollOutcome.pendingConfirmation, pendingMessage,
        paid: true);
  }

  /// One GET /courses/my-courses check. Errors count as "not (yet) enrolled".
  Future<bool> isEnrolled(String courseId) async {
    try {
      final value = await _repo.getMyEnrolledCourses();
      if (value is! Map) return false;
      final list = value['courses'];
      if (list is! List) return false;
      return list.any((e) => e is Map && e['courseId'] == courseId);
    } catch (_) {
      return false;
    }
  }

  /// Polls GET /courses/my-courses every [pollInterval] until [courseId]
  /// appears or [pollTimeout] elapses.
  Future<bool> waitForEnrollment(String courseId) async {
    final deadline = DateTime.now().add(pollTimeout);
    while (true) {
      if (await isEnrolled(courseId)) return true;
      if (DateTime.now().add(pollInterval).isAfter(deadline)) return false;
      await Future<void>.delayed(pollInterval);
    }
  }
}
