import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/bottom_filter.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/view/widgets/course_enroll_sheet.dart';
import 'package:toriino_todd/view/users/student_view/my_taken_cousre_view.dart';

export 'package:toriino_todd/view/widgets/course_enroll_sheet.dart'
    show showCourseEnrollSheet;
import 'package:toriino_todd/viewmodel/controller/student/course_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';

class CourseView extends StatelessWidget {
  CourseView({super.key});

  final CourseViewmodel courseController = Get.put(CourseViewmodel());

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.0.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Courses",
                      style: TextStyle(
                        color: AppColor.secconderyColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                    //  GestureDetector(
                    //   onTap: () => Navigator.pop(context),
                    //   child: Row(
                    //     spacing: 4,
                    //     children: [
                    //       SvgPicture.asset(
                    //         width: Responsive.w(6),
                    //         height: Responsive.w(6),
                    //         "assets/icons/Arrow - Right 3.svg",
                    //       ),
                    //       Text(
                    //         "Courses",
                    //         style: TextStyle(
                    //           color: AppColor.secconderyColor,
                    //           fontWeight: FontWeight.w600,
                    //           fontSize: 16.sp,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ),
                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(),
                          ),
                        ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: Responsive.padding(
                          left: 2,
                          right: 2,
                          bottom: 2,
                          top: 2,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/notification.svg',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () {
                      return customDrawerController.toggleDrawer();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: Responsive.padding(
                          left: 2,
                          right: 2,
                          bottom: 2,
                          top: 2,
                        ),
                        child: SvgPicture.asset('assets/icons/menu.svg'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      // Filters the loaded catalog (the field did nothing before — UAT Round 6).
                      onChanged: (v) => courseController.searchQuery.value = v,
                      decoration: InputDecoration(
                        hintText: "Search by title, teacher, or category",
                        hintStyle: TextStyle(
                          color: AppColor.secconderyColor,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColor.secconderyColor,
                        ),
                        filled: true,
                        fillColor: AppColor.backGroundColor.withValues(
                          alpha: 0.1,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () => _showFilterSuggestipon(context),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.red,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.0.w),
                        child: SvgPicture.asset(
                          'assets/icons/filter.svg',
                          // Using a placeholder icon
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: Obx(() {
                  final response = courseController.rxCourses.value;
                  if (response.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (response.status == Status.error) {
                    return Center(child: Text('Error loading courses', style: TextStyle(color: AppColor.white)));
                  }
                  final courses = courseController.filterCourses(response.data?.courses ?? []);
                  if (courses.isEmpty && courseController.searchQuery.value.trim().isNotEmpty) {
                    return Center(
                      child: Text(
                        courseController.hasMoreCourses
                            ? 'No loaded course matches. Scroll the full list to load more.'
                            : 'No courses match your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColor.white),
                      ),
                    );
                  }
                  // Enrolled courses show "Open" instead of "Enroll" (UAT L6).
                  final enrolledIds = {
                    for (final c in courseController.rxMyCourses.value.data?.courses ?? const <CourseModel>[])
                      if ((c.courseId ?? '').isNotEmpty) c.courseId!,
                  };
                  return NotificationListener<ScrollNotification>(
                  // Near the end of the list, fetch the next catalog page.
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 600) courseController.loadMoreCourses();
                    return false;
                  },
                  child: ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: EdgeInsets.all(8.0.w),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: AppColor.white.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/Frame 1000002079.svg",
                                        // Using a placeholder icon
                                        colorFilter: ColorFilter.mode(
                                          AppColor.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        courses[index].displayPrice == null
                                            ? ''
                                            : courses[index].displayPrice! > 0
                                                ? formatMoney(courses[index].displayPrice!, courses[index].pricing?.currency)
                                                : 'Free',
                                        style: TextStyle(
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (enrolledIds.contains(courses[index].courseId)) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MyTakenCousreView(course: courses[index]),
                                          ),
                                        );
                                      } else {
                                        showCourseEnrollSheet(context, courses[index]);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        color: AppColor.red,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0.h,
                                          horizontal: 16.0.w,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              enrolledIds.contains(courses[index].courseId) ? "Open" : "Enroll",
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: AppColor.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 5.w),
                                            SvgPicture.asset(
                                              "assets/icons/arrow.svg",
                                              // Using a placeholder icon
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((courses[index].duration ?? '').isNotEmpty) ...[
                                SizedBox(height: 10.h),
                                Text(
                                  "Duration: ${courses[index].duration}",
                                  style: TextStyle(
                                    color: AppColor.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Long titles wrap to two lines instead of overflowing the card.
                                  Expanded(
                                    child: Text(
                                      courses[index].title ?? 'Course',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              _courseMetaRow(courses[index]),
                              SizedBox(height: 10.h),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  ),
                );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom row of a catalog course card: the teacher (when the API sent a
/// `teacherName`), category / level, and the rating when there is one.
Widget _courseMetaRow(CourseModel course) {
  final teacher = (course.teacherName ?? '').trim();
  final sub = [
    if ((course.category ?? '').isNotEmpty) course.category!,
    if ((course.level ?? '').isNotEmpty) course.level!,
  ].join(' · ');
  final rating = course.rating ?? 0;
  if (teacher.isEmpty && sub.isEmpty && rating <= 0) {
    return SizedBox(height: 10.h);
  }
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            children: [
              if (teacher.isNotEmpty) ...[
                // Neutral placeholder (was a white icon on a white circle — UAT L10).
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.white12,
                  child: const Icon(Icons.person, color: Colors.white54),
                ),
                SizedBox(width: 10.w),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (teacher.isNotEmpty)
                      Text(
                        teacher,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: AppColor.white, size: 16.sp),
              SizedBox(width: 5.w),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

void _showFilterSuggestipon(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FilterBottomSheet(),
  );
}

