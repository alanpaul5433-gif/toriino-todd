import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/avabilty_view.dart';
import 'package:toriino_todd/widgets/intro_video_upload_section.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadVideo extends StatefulWidget {
  const UploadVideo({super.key});

  @override
  State<UploadVideo> createState() => _UploadVideoState();
}

class _UploadVideoState extends State<UploadVideo> {
  bool _busy = false;

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

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
              //   ],
              // ),
              SizedBox(height: Responsive.h(1)),

              Text(
                'Upload Video Intro',
                style: TextStyle(
                  fontSize: Responsive.textScaleFactor * 30,
                  color: AppColor.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: Responsive.h(10)),

              IntroVideoUploadSection(
                onBusyChanged: (v) => setState(() => _busy = v),
              ),
              Spacer(),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap:
                        _busy
                            ? null
                            : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AvailabilityScreen(),
                                ),
                              );
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
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(4)),
            ],
          ),
        ),
      ),
    );
  }
}
