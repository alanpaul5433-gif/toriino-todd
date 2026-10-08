import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/payment/pricing_model.dart';
import 'package:toriino_todd/repository/payments_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/course_enroll_flow.dart';
import 'package:toriino_todd/widgets/auth_button.dart';

/// Course detail / enroll sheet. Every amount comes from the server: the
/// course's `pricing` object or, when a paid course has none, GET
/// /payments/quote?courseId=. The student pays `price`; the platform fee is
/// taken from the teacher's share (shown as "included"), never added.
void showCourseEnrollSheet(BuildContext context, CourseModel course) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (_) => _CourseEnrollSheet(course: course, hostContext: context),
  );
}

class _CourseEnrollSheet extends StatefulWidget {
  final CourseModel course;
  final BuildContext hostContext;
  const _CourseEnrollSheet({required this.course, required this.hostContext});

  @override
  State<_CourseEnrollSheet> createState() => _CourseEnrollSheetState();
}

class _CourseEnrollSheetState extends State<_CourseEnrollSheet> {
  PaymentQuoteModel? _quote;
  String? _quoteError;
  bool _loadingQuote = false;

  CourseModel get course => widget.course;

  @override
  void initState() {
    super.initState();
    // Fee breakdown missing on a paid course → ask the server for a quote.
    final id = course.courseId ?? '';
    if (course.pricing == null && (course.displayPrice ?? 0) > 0 && id.isNotEmpty) {
      _loadQuote(id);
    }
  }

  Future<void> _loadQuote(String courseId) async {
    setState(() => _loadingQuote = true);
    try {
      final q = await PaymentsRepo().quoteForCourse(courseId);
      if (!mounted) return;
      setState(() {
        _quote = q;
        _loadingQuote = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteError = Utils.errorMessage(e);
        _loadingQuote = false;
      });
    }
  }

  void _enroll() {
    Navigator.pop(context);
    final host = widget.hostContext;
    if (host.mounted) runCourseEnrollment(host, course);
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final pricing = course.pricing;
    final quote = _quote;
    final currency = pricing?.currency ?? quote?.currency;
    final price = pricing?.price ?? quote?.price ?? course.price;
    final fee = pricing?.platformFee ?? quote?.platformFee;
    final feePercent = pricing?.platformFeePercent ?? quote?.platformFeePercent;
    final isFree = price != null && price <= 0;

    // The sheet's MediaQuery has no system-bar padding: add the window's navigation-bar
    // height so "Enroll for Free" is not drawn under it (UAT L6).
    final view = View.of(context);
    final navBarInset = view.viewPadding.bottom / view.devicePixelRatio;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + navBarInset,
        left: Responsive.w(5),
        right: Responsive.w(5),
        top: Responsive.h(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  (course.title ?? '').trim(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: AppColor.white),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(2)),
          if ((course.teacherName ?? '').isNotEmpty)
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColor.red,
                  child: Icon(Icons.person, color: AppColor.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.teacherName!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Instructor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: Responsive.h(2)),
          const Divider(color: Colors.grey),
          SizedBox(height: Responsive.h(2)),
          if ((course.category ?? '').isNotEmpty) ...[
            _row("Course Category", course.category!),
            SizedBox(height: Responsive.h(1)),
          ],
          if ((course.duration ?? '').isNotEmpty) ...[
            _row("Course Duration", course.duration!),
            SizedBox(height: Responsive.h(1)),
          ],
          if ((course.level ?? '').isNotEmpty) ...[
            _row("Level", course.level!),
            SizedBox(height: Responsive.h(1)),
          ],
          if ((course.rating ?? 0) > 0) ...[
            _row("Rating", course.rating!.toStringAsFixed(1)),
            SizedBox(height: Responsive.h(1)),
          ],
          if (price != null) ...[
            _row("Price", isFree ? "FREE" : formatMoney(price, currency)),
            SizedBox(height: Responsive.h(1)),
          ],
          if (!isFree && fee != null) ...[
            _row(
              feePercent != null
                  ? "Platform fee (${formatPercent(feePercent)}, included)"
                  : "Platform fee (included)",
              formatMoney(fee, currency),
            ),
            SizedBox(height: Responsive.h(1)),
          ],
          if (_loadingQuote)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                  child: CircularProgressIndicator(color: AppColor.red)),
            ),
          if (_quoteError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _quoteError!,
                style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
              ),
            ),
          SizedBox(height: Responsive.h(1)),
          if (course.description != null && course.description!.isNotEmpty)
            Text(
              course.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.5),
            ),
          SizedBox(height: Responsive.h(2)),
          AuthButton(
            buttontext: isFree ? "Enroll for Free" : "Proceed to Payment",
            onPress: _enroll,
            loading: false,
          ),
          SizedBox(height: Responsive.h(2)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
