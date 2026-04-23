import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/teacher/add_lessons_view.dart';
import 'package:toriino_todd/view/users/teacher/teacher_bottom_nav_bar.dart';
import 'package:toriino_todd/view/users/teacher/teacher_home_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AddLessonView extends StatefulWidget {
  const AddLessonView({super.key});

  @override
  State<AddLessonView> createState() => _AddLessonViewState();
}

class _AddLessonViewState extends State<AddLessonView> {
  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: ListView(
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 2,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: SvgPicture.asset(
                            "assets/icons/Arrow - Right 3.svg",
                          ),
                        ),
                        SizedBox(width: Responsive.w(1)),
                        Text(
                          'Add Lessons',
                          style: GoogleFonts.rethinkSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                    circularIcon("assets/icons/robotic.svg"),
                  ],
                ),
                CourseContentWidget(),
                CourseContentWidget(),
                CourseContentWidget(),
                CourseContentWidget(),
                CourseContentWidget(),
                GestureDetector(
                  onTap: () => _courseCompleteAlert(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColor.primaryColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Colors.white),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        SvgPicture.asset("assets/icons/plus-sign.svg"),
                        Text(
                          'Add Lesson',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: AppColor.white,
                            fontSize: Responsive.textScaleFactor * 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(22)),
                GestureDetector(
                  onTap: () => _courseCompleteAlert(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColor.red,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Colors.red),
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
                          'Publish Course',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: AppColor.white,
                            fontSize: Responsive.textScaleFactor * 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _courseCompleteAlert(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/icons/checkmark-circle-02.svg"),
              SizedBox(height: Responsive.h(1)),
              Text(
                "Your Course is Live!",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Responsive.h(1)),
              Text(
                textAlign: TextAlign.center,
                "Your course is now available for students to discover and purchase. You can boost it for more visibility anytime.",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 16,
                ),
              ),
              SizedBox(height: Responsive.h(5)),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeacherBottomNavBar()),
                  );
                  Utils.toastMassage("Session booked Successful");
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Got It",
                            style: GoogleFonts.dmSans(
                              fontSize: Responsive.textScaleFactor * 14,
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
              ),
            ],
          ),
        ),
      );
    },
  );
}
