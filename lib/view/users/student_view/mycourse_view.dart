import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/viewmodel/controller/student/course_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class MycourseView extends StatelessWidget {
  MycourseView({super.key});

  final CourseViewmodel _courseVm = Get.put(CourseViewmodel());

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      spacing: 2,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset(
                            width: Responsive.w(6),
                            height: Responsive.w(6),
                            "assets/icons/Arrow - Right 3.svg",
                          ),
                        ),
                        Text(
                          "In Progress Courses",
                          style: TextStyle(
                            color: AppColor.secconderyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.textScaleFactor * 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.backGroundColor.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/notification.svg'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.backGroundColor.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/menu.svg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Obx(() {
                  final state = _courseVm.rxMyCourses.value;
                  if (state.status == Status.loading) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (state.status == Status.error) {
                    return Center(
                        child: Text('Error loading courses',
                            style: TextStyle(color: AppColor.white)));
                  }
                  final courses = state.data?.courses ?? [];
                  if (courses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined,
                              color: Colors.white38, size: 56),
                          const SizedBox(height: 16),
                          Text('No enrolled courses yet.',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Browse courses to get started.',
                              style: GoogleFonts.dmSans(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: AppColor.white.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SvgPicture.asset(
                                        "assets/icons/Frame 1000002079.svg"),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          course.title ?? 'Course',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/Component 26.svg"),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  course.category ?? '',
                                  style: GoogleFonts.dmSans(
                                    color: AppColor.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        course.title ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 18.sp,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/material-symbols_star (1).svg"),
                                        Text(
                                          '${course.rating ?? 0}',
                                          style: GoogleFonts.dmSans(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 20,
                                          backgroundImage: AssetImage(
                                              "assets/icons/Ellipse 6.png"),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.teacherId ?? 'Instructor',
                                              style: GoogleFonts.dmSans(
                                                color: AppColor.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              course.level ?? '',
                                              style: GoogleFonts.dmSans(
                                                color: AppColor.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(28),
                                        color: AppColor.red,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Continue",
                                              style: GoogleFonts.dmSans(
                                                fontSize: 14,
                                                color: AppColor.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SvgPicture.asset(
                                                "assets/icons/arrow.svg"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  backgroundColor: AppColor.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColor.red),
                                  value: 0.0,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Completion",
                                        style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w700)),
                                    Text("0%",
                                        style: GoogleFonts.dmSans(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
