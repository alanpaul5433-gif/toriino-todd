import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback ontap;
  const SocialButton({super.key, required this.iconPath, required this.ontap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        height: Responsive.h(6), // 6% of screen height
        width: Responsive.w(25), // 20% of screen width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Responsive.w(5.5)),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.w(3)),
          child: SvgPicture.asset(iconPath),
        ),
      ),
    );
  }
}
