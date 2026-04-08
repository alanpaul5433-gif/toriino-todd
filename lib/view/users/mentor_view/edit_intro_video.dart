import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class EditIntroVideo extends StatelessWidget {
  const EditIntroVideo({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 1, right: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Responsive.h(1)),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                ],
              ),
              SizedBox(height: Responsive.h(1)),

              Text(
                'Edit Intro Video',
                style: TextStyle(
                  fontSize: 30,
                  color: AppColor.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: Responsive.h(10)),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.circular(28),
                  color: AppColor.white.withValues(alpha: 0.08),
                ),
                child: Padding(
                  padding: Responsive.padding(top: 7, bottom: 7),
                  child: Column(
                    children: [
                      SvgPicture.asset("assets/icons/upload-circle.svg"),
                      Text(
                        'Formats, MOV, MP3, MP4',
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontSize: Responsive.textScaleFactor * 8,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.h(1)),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.circular(28),
                  color: AppColor.red,
                ),
                child: Padding(
                  padding: Responsive.padding(top: 2, bottom: 2),
                  child: Center(
                    child: SvgPicture.asset("assets/icons/camera-add.svg"),
                  ),
                ),
              ),
              SizedBox(height: Responsive.h(1)),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadiusDirectional.circular(28),
                  color: AppColor.primaryColor,
                  border: Border.all(color: AppColor.red),
                ),
                child: Padding(
                  padding: Responsive.padding(top: 2, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/icons/IC_cross.svg"),  SizedBox(width: Responsive.w(2)),
                      Text(
                        'Upload a video',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                          SvgPicture.asset("assets/icons/arrow.svg"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),  SizedBox(height: Responsive.h(4)),
            ],
          ),
        ),
      ),
    );
  }
}
