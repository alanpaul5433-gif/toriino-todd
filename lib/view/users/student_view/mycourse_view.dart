import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class MycourseView extends StatelessWidget {
  const MycourseView({super.key});

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
                      color: AppColor.backGroundColor.withValues(alpha:0.1),
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
                      color: AppColor.backGroundColor.withValues(alpha:0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/menu.svg'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              Flexible(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: ((context, index) {
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
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/Frame 1000002079.svg",
                                  ),
                                  Text(
                                    "Course 01",
                                    style: GoogleFonts.dmSans(
                                      color: AppColor.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/Component 26.svg",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              Text(
                                "Last seen 2 days ago",
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "UI/UX Design Basics",
                                    style: GoogleFonts.dmSans(
                                      fontSize: 25.sp,
                                      color: AppColor.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/material-symbols_star (1).svg",
                                      ),
                                      Text(
                                        "4.8",
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: AssetImage(
                                          "assets/icons/Ellipse 6.png",
                                        ),
                                      ),
                                      SizedBox(width: 10),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Chance Calzoni",
                                            style: GoogleFonts.dmSans(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "Mentor",
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
                                      borderRadius: BorderRadius.circular(28),
                                      color: AppColor.red,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 16.0,
                                      ),
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
                                            "assets/icons/arrow.svg",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10),
                              LinearProgressIndicator(
                                backgroundColor:
                                    AppColor.white, // Background color
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColor.red,
                                ), // Progress color
                                value: 0.5, // Set progress to 50%
                              ),
                              SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Completion",
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: AppColor.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "78 %",
                                    style: GoogleFonts.dmSans(
                                      color: AppColor.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
