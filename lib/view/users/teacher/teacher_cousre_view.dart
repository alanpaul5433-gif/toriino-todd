import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/view/users/teacher/create_coure_view.dart';
import 'package:toriino_todd/view/users/teacher/teacher_home_view.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_course_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherCousreView extends StatelessWidget {
  const TeacherCousreView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    final courseVm = Get.isRegistered<TeacherCourseViewmodel>()
        ? Get.find<TeacherCourseViewmodel>()
        : Get.put(TeacherCourseViewmodel());
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 5,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'My Courses',
                            style: GoogleFonts.rethinkSans(
                              color: Colors.white,
                              fontSize: Responsive.sp(14),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.20,
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
                        child: SvgPicture.asset(
                          'assets/icons/presentation_2657896 2.svg',
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(2)),

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
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/notification.svg',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(2)),
                    GestureDetector(
                      onTap:
                          customDrawerController
                              .advancedDrawerController
                              .toggleDrawer,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset('assets/icons/menu.svg'),
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateCoureView()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColor.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 4,
                      children: [
                        SvgPicture.asset("assets/icons/plus-sign.svg"),
                        Text(
                          'Create New Course',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: Responsive.h(4)),
                Obx(() {
                  final state = courseVm.rxMyCourses.value;
                  final courses = state.data?.courses ?? [];
                  if (courses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          state.data == null ? 'Loading courses...' : 'No courses yet. Create your first!',
                          style: GoogleFonts.dmSans(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      return recentSessionsHistoryCard(context, courses[index]);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
