import 'package:flutter/material.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/widgets/custom_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// "Ongoing course" card built from a real enrollment (GET
/// /courses/my-courses). Every optional field is hidden when absent.
class OngoingCourseCard extends StatelessWidget {
  final String courseTitle;
  final String? duration;
  final String? mentorName;
  final double? rating;

  /// `enrollment.progress` (0-100) from the server.
  final int? progress;
  final String headerText;
  final VoidCallback continuetocousre;

  const OngoingCourseCard({
    super.key,
    required this.courseTitle,
    required this.headerText,
    required this.continuetocousre,
    this.duration,
    this.mentorName,
    this.rating,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final p = progress?.clamp(0, 100);
    final teacher = (mentorName ?? '').trim();
    final dur = (duration ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: TextStyle(
            color: AppColor.secconderyColor,
            fontSize: Responsive.sp(14),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColor.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book, color: Colors.white),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      courseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (rating != null && rating! > 0) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.star,
                      color: Colors.white,
                      size: Responsive.textScaleFactor * 16,
                    ),
                    SizedBox(width: 4.sp),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
              if (dur.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  dur,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: Responsive.sp(10),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: teacher.isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColor.white.withValues(alpha: 0.15),
                                child: const Icon(Icons.person,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  teacher,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                  CustomButton(
                    backgroundColor: const Color.fromRGBO(231, 49, 33, 1),
                    width: 120.w,
                    text: 'Continue',
                    onTap: continuetocousre,
                  ),
                ],
              ),
              if (p != null) ...[
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: p / 100,
                    backgroundColor: Colors.white24,
                    color: Colors.green,
                    minHeight: 6,
                  ),
                ),
                SizedBox(height: 4.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Completion",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: Responsive.textScaleFactor * 14,
                      ),
                    ),
                    Text(
                      "$p %",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: Responsive.textScaleFactor * 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
