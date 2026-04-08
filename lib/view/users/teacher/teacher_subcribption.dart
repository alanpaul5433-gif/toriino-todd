import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/utils/utils.dart';
import 'package:getxmvvm/view/users/teacher/teacher_bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherSubcribption extends StatelessWidget {
  const TeacherSubcribption({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 1, right: 1, bottom: 1, top: 1),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap:
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherBottomNavBar(),
                                ),
                              ),
                          child: Text(
                            'Skip',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                        SvgPicture.asset("assets/icons/bitcoin-icons.svg"),
                      ],
                    ),
                  ],
                ),

                Text(
                  'Stand Out. Get Featured',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
                SizedBox(height: Responsive.h(1)),
                Text(
                  'Boost your profile with a verified badge to appear as a top mentor and gain more students',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 12,
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                SizedBox(height: Responsive.h(1)),
                subscribeCard(
                  "assets/icons/cube_box.svg",
                  "Monthly Plan",
                  "9.99/",
                  "Month",
                  "Appear on homepage featured mentors",
                  "Rank higher in search",
                  "Increased student trust",
                  "Access analytics about visibility",
                  () {
                    Utils.toastMassage("Subscription activated successfully!");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => TeacherBottomNavBar()),
                    );
                  },
                  context,
                ),
                SizedBox(height: Responsive.h(1)),
                subscribeCard(
                  "assets/icons/mdi_gold.svg",
                  "Quarterly Plan (Save 17%)",
                  "9.99/",
                  "6 Month",
                  "Appear on homepage featured mentors",
                  "Rank higher in search",
                  "Increased student trust",
                  "Access analytics about visibility",
                  () {
                    Utils.toastMassage("Subscription activated successfully!");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => TeacherBottomNavBar()),
                    );
                  },
                  context,
                ),
                SizedBox(height: Responsive.h(1)),
                subscribeCard(
                  "assets/icons/bxs_diamond.svg",
                  "Annual Plan (Best Value)",
                  "9.99/",
                  "Yearly",
                  "Appear on homepage featured mentors",
                  "Rank higher in search",
                  "Increased student trust",
                  "Access analytics about visibility",
                  () {
                    Utils.toastMassage("Subscription activated successfully!");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => TeacherBottomNavBar()),
                    );
                  },
                  context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget subscribeCard(
  String image,
  String plantype,
  String price,
  String duration,
  String feature1,
  String feature2,
  String feature3,
  String feature4,
  VoidCallback ontap,
  BuildContext context,
) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: Responsive.padding(left: 2, right: 2, bottom: 2, top: 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(image),
                    Text(
                      plantype,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '\$ $price',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                      TextSpan(
                        text: duration,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            SizedBox(height: Responsive.h(1)),
            //Divider
            Row(children: [Expanded(child: Divider())]),
            SizedBox(height: Responsive.h(1)),
            dottedText(feature1),
            dottedText(feature2),
            dottedText(feature3),
            dottedText(feature4), SizedBox(height: Responsive.h(1)),

            subcribebutton(),
          ],
        ),
      ),
    ),
  );
}

Widget dottedText(String text) {
  return SizedBox(
    width: double.infinity,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: ShapeDecoration(
            color: const Color(0xFFD9D9D9),
            shape: OvalBorder(),
          ),
        ),
        Text(
          text,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontWeight: FontWeight.w400,
            height: 1.80,
          ),
        ),
      ],
    ),
  );
}

Widget subcribebutton() {
  return Container(
    padding: Responsive.padding(top: 0.5, bottom: 0.5),
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColor.red,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Subscribe Now",
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.20,
          ),
        ),
        SizedBox(width: Responsive.w(1)),
        SvgPicture.asset("assets/icons/arrow.svg"),
      ],
    ),
  );
}
