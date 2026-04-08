import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/teacher/add_lessons_view.dart';
import 'package:getxmvvm/view/users/teacher/teacher_home_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AddLessons extends StatefulWidget {
  const AddLessons({super.key});

  @override
  State<AddLessons> createState() => _AddLessonsState();
}

class _AddLessonsState extends State<AddLessons> {
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
                      children: [
                        SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                        SizedBox(width: Responsive.w(1)),
                        Text(
                          'Create New Course',
                          style: GoogleFonts.rethinkSans(
                            color: Colors.white,
                            fontSize:Responsive.textScaleFactor* 18,
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: ShapeDecoration(
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
                    children: [SvgPicture.asset("assets/icons/plus-sign.svg"),
                      Text(
                        'Add Lesson',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontSize:Responsive.textScaleFactor* 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
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
