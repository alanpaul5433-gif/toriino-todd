import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buttonLarge(BuildContext context, String text) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: AppColor.red,
    ),
    child: Padding(
      padding: Responsive.padding(left: 1, right: 1, top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: Responsive.textScaleFactor*12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.20,
            ),
          ),
          SvgPicture.asset("assets/icons/arrow.svg"),
        ],
      ),
    ),
  );
}
