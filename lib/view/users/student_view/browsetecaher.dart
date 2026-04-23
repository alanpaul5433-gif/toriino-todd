import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/view/users/student_view/teacher_profile.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseTecher extends StatelessWidget {
  const BrowseTecher({super.key});

  @override
  Widget build(BuildContext context) {
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
                      children: [
                        GestureDetector(
                          onTap: ()=>Navigator.pop(context),
                          child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg")),
                        Column(
                          children: [
                            Text(
                              "Browse Teacher",
                              style: TextStyle(
                                color: AppColor.secconderyColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "Search by name, topic, or skill",
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/filter.svg'),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: AssetImage(
                                      "assets/icons/Frame 1171275882.png",
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 10,
                                    children: [
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

                                      Text(
                                        "Giana Rhiel Madsen",
                                        style: GoogleFonts.dmSans(
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "UI/UX Teacher",
                                        style: GoogleFonts.dmSans(
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SvgPicture.asset(
                                    "assets/icons/bitcoin-icons_verify-filled.svg",
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              Text(
                                "Passionate English trainer with 8+ years of experience helping global students build fluency and confidence.",
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                spacing: 5,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: BoxBorder.all(
                                        color: AppColor.white,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "Design",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: BoxBorder.all(
                                        color: AppColor.white,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "Frontend",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: BoxBorder.all(
                                        color: AppColor.white,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "UI UX",
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
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Available Courses",
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: AppColor.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    "03",
                                    style: GoogleFonts.dmSans(
                                      color: AppColor.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeacherProfile(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "View Profile",
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
