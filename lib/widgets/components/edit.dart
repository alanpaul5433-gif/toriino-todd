import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileTextfeild extends StatelessWidget {
  final String text;
  final String svgPath;
  final TextEditingController controller;
  final FocusNode focusNode;
  // final FocusNode currentfocusNode;
  final FocusNode nextfocusNode;

  const EditProfileTextfeild({
    super.key,
    required this.text,
    required this.svgPath,
    required this.controller,
    required this.focusNode,
    // required this.currentfocusNode,
    required this.nextfocusNode,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(color: AppColor.white),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(svgPath),
        ),
        hint: Text(
         text,
          style: GoogleFonts.dmSans(color: AppColor.white),
        ),

        filled: true,
        fillColor: AppColor.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.red),
          borderRadius: BorderRadius.circular(28),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
        // label: Text(text, style: TextStyle(color: AppColor.white)),
      ),
      onFieldSubmitted: (value) {
        Utils.fieldFoucsChange(context, focusNode, nextfocusNode);
      },
    );
  }
}
