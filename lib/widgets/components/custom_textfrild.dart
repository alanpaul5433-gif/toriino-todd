
import 'package:flutter/material.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';

class EditProfileTextfeild extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final FocusNode focusNode;
  // final FocusNode currentfocusNode;
  final FocusNode nextfocusNode;

  const EditProfileTextfeild({
    super.key,
    required this.text,
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
        
        filled: true,
        fillColor: AppColor.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.focusedBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.red),
          borderRadius: BorderRadius.circular(28),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
        label: Text(
          text,
          style: TextStyle( color: AppColor.white),
        ),
      ),
      onFieldSubmitted: (value) {
        Utils.fieldFoucsChange(context, focusNode, nextfocusNode);
      },
    );
  }
}
