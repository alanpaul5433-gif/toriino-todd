import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.backgroundColor = AppColor.red,
    this.textColor = AppColor.white,
    this.width = double.infinity,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: width.w,
        // height: height.h/1.2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(40.r),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 👈 shrink to fit content
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: Responsive.sp(10),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (icon != null) ...[
                SizedBox(width: 8.w),
                Icon(icon, color: textColor, size: Responsive.textScaleFactor * 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
