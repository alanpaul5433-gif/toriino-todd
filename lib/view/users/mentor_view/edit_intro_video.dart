import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/widgets/intro_video_upload_section.dart';
import 'package:google_fonts/google_fonts.dart';

class EditIntroVideo extends StatefulWidget {
  /// The currently saved intro video, if any.
  final String? currentUrl;

  const EditIntroVideo({super.key, this.currentUrl});

  @override
  State<EditIntroVideo> createState() => _EditIntroVideoState();
}

class _EditIntroVideoState extends State<EditIntroVideo> {
  bool _busy = false;
  String? _savedUrl;

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
                  GestureDetector(
                    onTap:
                        _busy ? null : () => Navigator.pop(context, _savedUrl),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
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

              IntroVideoUploadSection(
                currentUrl: widget.currentUrl,
                onBusyChanged: (v) => setState(() => _busy = v),
                onSaved: (url) => setState(() => _savedUrl = url),
              ),
              Spacer(),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap:
                        _busy ? null : () => Navigator.pop(context, _savedUrl),
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
