import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/analytics_service.dart';
import 'package:toriino_todd/services/course_enrollment_service.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/viewmodel/controller/student/course_viewmodel.dart';

/// Runs the real enrollment flow for [course] (free → enroll, paid → Stripe
/// PaymentSheet then wait for the webhook) behind a blocking progress dialog,
/// then tells the user the actual outcome.
Future<EnrollResult?> runCourseEnrollment(
  BuildContext context,
  CourseModel course, {
  CourseEnrollmentService? service,
}) async {
  final status = ValueNotifier<String>(
      (course.displayPrice ?? 0) > 0 ? 'Opening secure payment…' : 'Enrolling…');
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColor.red),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (_, text, __) => Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: AppColor.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  final result = await (service ?? CourseEnrollmentService())
      .enroll(course, onStatus: (s) => status.value = s);

  if (navigator.mounted) navigator.pop();
  status.dispose();

  if (result.isEnrolled) {
    AnalyticsService.logEnroll(courseId: course.courseId ?? '');
  }
  if (result.isEnrolled || result.outcome == EnrollOutcome.pendingConfirmation) {
    if (Get.isRegistered<CourseViewmodel>()) {
      Get.find<CourseViewmodel>().fetchMyCourses();
    }
  }

  if (!context.mounted) return result;
  switch (result.outcome) {
    case EnrollOutcome.enrolled:
      _showResultDialog(
        context,
        title: "You're Enrolled!",
        body: 'You now have access to "${course.title ?? 'this course'}". '
            'Head to My Courses to start learning.',
        success: true,
      );
      break;
    case EnrollOutcome.pendingConfirmation:
      _showResultDialog(
        context,
        title: 'Payment received',
        body: result.message,
        success: false,
      );
      break;
    case EnrollOutcome.cancelled:
      Utils.toastMassage(result.message);
      break;
    case EnrollOutcome.failed:
      _showResultDialog(
        context,
        title: 'Could not enroll',
        body: result.message,
        success: false,
      );
      break;
  }
  return result;
}

/// Shown when the server answers 402 for lesson media: the user must enroll
/// (free) or purchase (paid) first. Returns true once actually enrolled.
Future<bool> showEnrollRequiredDialog(
  BuildContext context,
  CourseModel? course,
) async {
  final paid = (course?.displayPrice ?? 0) > 0;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColor.primaryColor,
      title: Text('Enroll in this course to watch',
          style: GoogleFonts.dmSans(
              color: AppColor.white, fontWeight: FontWeight.w700)),
      content: Text(
        course == null
            ? 'This lesson is part of a paid course. Enroll from the course page to watch it.'
            : paid
                ? 'This lesson is part of a paid course (${formatMoney(course.displayPrice!, course.pricing?.currency)}).'
                : 'Enroll for free to watch this lesson.',
        style: GoogleFonts.dmSans(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now', style: TextStyle(color: Colors.white54)),
        ),
        if (course != null)
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(paid ? 'Purchase' : 'Enroll',
                style: const TextStyle(color: AppColor.red)),
          ),
      ],
    ),
  );
  if (go != true || course == null || !context.mounted) return false;
  final result = await runCourseEnrollment(context, course);
  return result?.isEnrolled ?? false;
}

void _showResultDialog(
  BuildContext context, {
  required String title,
  required String body,
  required bool success,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColor.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (success)
              SvgPicture.asset("assets/icons/checkmark-circle-02.svg")
            else
              const Icon(Icons.info_outline, color: AppColor.white, size: 48),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColor.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppColor.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColor.red,
                ),
                child: Text(
                  success ? 'Start Learning' : 'OK',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColor.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
