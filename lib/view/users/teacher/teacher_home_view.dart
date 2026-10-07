import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/view/users/teacher/create_coure_view.dart';
import 'package:toriino_todd/view/users/teacher/edit_coure_view.dart';
import 'package:toriino_todd/view/users/teacher/teacher_subcribption.dart';
import 'package:toriino_todd/view/users/teacher/teacher_cousre_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_home_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_course_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherHomeView extends StatelessWidget {
  TeacherHomeView({super.key});

  final TeacherHomeViewmodel teacherController = Get.put(TeacherHomeViewmodel());

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: Obx(() {
        final allLoading =
            teacherController.rxProfile.value.status == Status.loading &&
            teacherController.rxCourses.value.status == Status.loading &&
            teacherController.rxEarnings.value.status == Status.loading;
        if (allLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 2, right: 2, top: 2),
          child: ListView(
            padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Obx(() {
                              final avatarUrl = teacherController.rxProfile.value.data?.avatarUrl;
                              return CircleAvatar(
                                radius: 24,
                                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl) as ImageProvider
                                    : const AssetImage('assets/icons/Ellipse 6.png'),
                              );
                            }),
                            SizedBox(width: Responsive.wp(1)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final profile = teacherController.rxProfile.value;
                                  final name = profile.status == Status.success ? profile.data?.name ?? 'Teacher' : 'Teacher';
                                  return Text(
                                  'Hi $name',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: Responsive.sp(12),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.30,
                                  ),
                                );
                                }),
                                Text(
                                  'Teacher',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: Responsive.sp(10),
                                    fontWeight: FontWeight.w400,
                                    height: 1.60,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/presentation_2657896 2.svg',
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.wp(2)),

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
                      SizedBox(width: Responsive.wp(2)),
                      Semantics(
                        label: 'Open menu',
                        button: true,
                        child: GestureDetector(
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
                      ),
                    ],
                  ),

                  Obx(() {
                    final coursesState = teacherController.rxCourses.value;
                    final courses = coursesState.data?.courses ?? [];
                    final totalCourses = courses.length;
                    final totalEnrollments = courses.fold<int>(0, (sum, c) => sum + (c.enrollmentCount ?? 0));
                    final avgRating = courses.isEmpty ? 0.0 : courses.fold<double>(0, (sum, c) => sum + (c.rating ?? 0)) / courses.length;
                    final hasData = coursesState.data != null;
                    return Row(
                      spacing: 6,
                      children: [
                        bloc(title: "Total Courses", value: hasData ? totalCourses.toString() : '--', context: context),
                        bloc(title: "Total Enrollments", value: hasData ? totalEnrollments.toString() : '--', context: context),
                        bloc(title: "Average Rating", value: hasData ? avgRating.toStringAsFixed(1) : '--', context: context),
                      ],
                    );
                  }),

                  Obx(() {
                    final sessionsState = teacherController.rxSessions.value;
                    final sessions = sessionsState.data?.sessions ?? [];
                    final upcoming = sessions.where((s) => s.status == 'scheduled').length;
                    final hasData = sessionsState.data != null;
                    return Row(
                    spacing: 6,
                    children: [
                      bloc(
                        title: "Upcoming Sessions",
                        value: hasData ? upcoming.toString() : '--',
                        context: context,
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: Responsive.hp(12),
                          decoration: BoxDecoration(
                            color: AppColor.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 3,
                              right: 4,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Earnings',
                                        style: GoogleFonts.dmSans(
                                          color: AppColor.white,
                                          fontSize: Responsive.textScaleFactor * 12,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.20,
                                        ),
                                      ),
                                      Spacer(),
                                      Obx(() {
                                        final earningsState = teacherController.rxEarnings.value;
                                        final total = earningsState.data?.totalEarnings;
                                        final label = total != null ? '\$${total.toStringAsFixed(2)}' : '--';
                                        return Row(
                                          children: [
                                            Text(
                                              label,
                                              style: GoogleFonts.dmSans(
                                                color: AppColor.white,
                                                fontSize: Responsive.sp(16),
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: -0.30,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: SizedBox(
                                    width: 178,
                                    height: 43,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 122,
                                          top: 10.75,
                                          child: Container(
                                            width: 11,
                                            height: 11,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFE73121),
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  width: 1.50,
                                                  color: Colors.white,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(39),
                                              ),
                                              shadows: [
                                                BoxShadow(
                                                  color: Color(0x7FE73121),
                                                  blurRadius: 7.10,
                                                  offset: Offset(0, 1),
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 143.42,
                                          top: 0,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            spacing: 3,
                                            children: [
                                              Text(
                                                'Month',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: 3,
                                          top: 0,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            spacing: 3,
                                            children: [
                                              Text(
                                                '+1.5 ',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                  }),

                  AuthButton(
                    buttontext: "Create New Course",
                    loading: false,
                    onPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateCoureView()),
                      );
                    },
                  ),
                  SizedBox(height: Responsive.hp(1)),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: Responsive.padding(
                        left: 2,
                        right: 2,
                        bottom: 2,
                        top: 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Reach More Students',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ),
                              SvgPicture.asset(
                                "assets/icons/bitcoin-icons_verify-filled.svg",
                              ),
                            ],
                          ),
                          Text(
                            'Get featured in search and recommendations. Reach more students.',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.sp(10),
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                          SizedBox(height: Responsive.hp(2)),

                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherSubcribption(),
                                  ),
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFE73121),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    'Boost Now',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  SvgPicture.asset("assets/icons/arrow.svg"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.hp(2)),

                  Text(
                    'Upcoming Sessions',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                  SizedBox(height: Responsive.hp(2)),
                  test(context),
                  SizedBox(height: Responsive.hp(2)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Uploaded Courses',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.sp(14),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),

                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherCousreView())),
                        child: Row(
                          children: [
                            Text(
                              'View all',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.sp(10),
                                fontWeight: FontWeight.w400,
                                height: 1.60,
                              ),
                            ),
                            SvgPicture.asset(
                              "assets/icons/eva_arrow-up-fill.svg",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.hp(2)),

                  Obx(() {
                    final coursesState = teacherController.rxCourses.value;
                    final courses = coursesState.data?.courses ?? [];
                    if (courses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            coursesState.data == null ? 'Loading courses...' : 'No courses yet',
                            style: GoogleFonts.dmSans(color: AppColor.white.withValues(alpha: 0.6)),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      itemBuilder: (ctx, index) {
                        return recentSessionsHistoryCard(ctx, courses[index]);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
      }),
    );
  }
}

void _courseCompleteAlert(BuildContext context, [CourseModel? course]) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      bool isDeleting = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: AppColor.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset("assets/icons/bin.svg"),
                  SizedBox(height: Responsive.hp(1)),
                  Text(
                    "Delete this course?",
                    style: TextStyle(
                      color: AppColor.white,
                      fontSize: Responsive.textScaleFactor * 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.hp(1)),
                  Text(
                    textAlign: TextAlign.center,
                    "Are you sure you want to delete '${course?.title ?? 'this course'}'? This action cannot be undone.",
                    style: TextStyle(
                      color: AppColor.white,
                      fontSize: Responsive.textScaleFactor * 16,
                    ),
                  ),
                  SizedBox(height: Responsive.hp(5)),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isDeleting
                              ? null
                              : () async {
                                  if (course?.courseId == null) {
                                    Navigator.pop(dialogContext);
                                    Utils.toastMassage(
                                        "Cannot delete: course ID missing");
                                    return;
                                  }
                                  setDialogState(() => isDeleting = true);
                                  try {
                                    await CourseRepo()
                                        .deleteCourse(course!.courseId!);
                                    Navigator.pop(dialogContext);
                                    Utils.toastMassage(
                                        "Course deleted successfully");
                                    final vm = Get.isRegistered<
                                            TeacherCourseViewmodel>()
                                        ? Get.find<TeacherCourseViewmodel>()
                                        : null;
                                    vm?.fetchMyCourses();
                                  } catch (e) {
                                    setDialogState(() => isDeleting = false);
                                    Utils.toastMassage(
                                        "Error deleting course: $e");
                                  }
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: AppColor.red,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Center(
                                child: isDeleting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text(
                                        "Confirm",
                                        style: GoogleFonts.dmSans(
                                          fontSize:
                                              Responsive.textScaleFactor * 14,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.wp(4)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogContext);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: AppColor.white.withValues(alpha: 0.20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Center(
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.dmSans(
                                    fontSize: Responsive.textScaleFactor * 14,
                                    color: AppColor.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget test(BuildContext context) {
  // Responsive.init(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: const AssetImage("assets/icons/Ellipse 6 (1).png"),
                      ),
                      SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "--",
                            style: GoogleFonts.dmSans(
                              fontSize: Responsive.sp(10),
                              color: AppColor.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Student",
                            style: GoogleFonts.dmSans(
                              fontSize: Responsive.sp(10),

                              color: AppColor.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/material-symbols_star (1).svg",
                    ),
                    Text(
                      "--",
                      style: GoogleFonts.dmSans(
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(children: [Expanded(child: Divider(thickness: 1))]),
            Text(
              "14 May, 3:00 PM – 4:00 PM",
              style: GoogleFonts.dmSans(
                fontSize: Responsive.sp(18),
                color: AppColor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Type",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Group",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Duration",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "1hr",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seats Left",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "2-5",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Language",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "English / Arabic",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.sp(10),
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(children: [Expanded(child: Divider(thickness: 1))]),
            SizedBox(height: Responsive.hp(1)),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        spacing: 2,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Start Session",
                            style: GoogleFonts.dmSans(
                              fontSize: Responsive.sp(12),
                              color: AppColor.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SvgPicture.asset("assets/icons/arrow.svg"),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.wp(2)),
                // assets/icons/bubble-chat.svg
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppColor.white.withValues(alpha: 0.20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset("assets/icons/bubble-chat.svg"),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.hp(1)),
          ],
        ),
      ),
    ),
  );
}

Widget recentSessionsHistoryCard(BuildContext context, [CourseModel? course]) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                circularIcon("assets/icons/book.svg",),
                SizedBox(width: Responsive.wp(2)),
                Text(
                  course?.category?.toUpperCase() ?? 'COURSE',
                  style: GoogleFonts.dmSans(
                    color: AppColor.white,
                    fontSize: Responsive.sp(10),
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
            Text(
              course?.status == 'published' ? 'Published' : (course?.status ?? 'Draft'),
              style: GoogleFonts.dmSans(
                color: AppColor.white,
                fontSize: Responsive.sp(10),
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
            SizedBox(height: Responsive.hp(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    course?.title ?? 'Untitled Course',
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.sp(20),
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (course?.rating != null)
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/material-symbols_star (1).svg",
                      ),
                      Text(
                        course!.rating!.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontSize: Responsive.sp(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: Responsive.hp(1)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    EditCoureView(course: course ?? CourseModel())),
                          );
                          if (result == true) {
                            final vm = Get.isRegistered<TeacherCourseViewmodel>()
                                ? Get.find<TeacherCourseViewmodel>()
                                : null;
                            vm?.fetchMyCourses();
                          }
                        },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 5,
                        children: [
                          Text(
                            'Edit',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.20,
                            ),
                          ),
                          SvgPicture.asset("assets/icons/vector.svg"),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.wp(2)),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _courseCompleteAlert(context, course),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE73121),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 5,
                        children: [
                          Text(
                            'Delete',
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
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget circularIcon(String image) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColor.white.withValues(alpha: 0.20)),
      shape: BoxShape.circle,
      // color: AppColor.white.withValues(alpha: 0.01),
    ),
    child: Padding(
      padding: Responsive.padding(top: 3, bottom: 3, right: 3, left: 3),
      child: Center(child: SvgPicture.asset(image)),
    ),
  );
}

Widget bloc({
  required String title,
  required String value,
  Color? backgroundColor,
  Color? textColor,
  IconData? icon,
  double? height,
  EdgeInsets? margin,
  required BuildContext context,
}) {
  return Expanded(
    child: Padding(
      padding: margin ?? Responsive.padding(left: 0, right: 0, bottom: 1, top: 1),
      child: Container(
        height: height ?? Responsive.hp(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor ?? AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: textColor ?? Colors.white,
                        fontSize: Responsive.sp(8),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      size: Responsive.sp(14),
                      color: textColor ?? Colors.white,
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                      color: textColor ?? Colors.white,
                      fontSize: Responsive.sp(18),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
