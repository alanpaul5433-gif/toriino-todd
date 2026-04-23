import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';

class CustomRecentQuizCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color arrowColor;
  final Color firstIconBgColor;
  final bool showTrailingArrow;
  final bool showIcon;

  const CustomRecentQuizCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = '',
    this.iconBackgroundColor = const Color(0xFF7B61FF),
    this.iconColor = Colors.white,
    this.arrowColor = const Color(0xFF7B61FF),
    this.firstIconBgColor = const Color(0xFF7B61FF),
    this.showTrailingArrow = true,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor,
            // textColor.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Optional leading icon
              if (showIcon)
                Container(
                  width: 42.w,
                  height: 42.h,
                  padding: EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: AppColor.white),
                    color: firstIconBgColor,

                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset("assets/icons/alarm.svg"),
                ),

              if (showIcon) SizedBox(width: 12.w),

              // Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColor.secconderyColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColor.secconderyColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Optional trailing arrow
              if (showTrailingArrow)
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 42.w, // your desired width
                    height: 36.h, // your desired height
                    decoration: BoxDecoration(
                      color: arrowColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        20.r,
                      ), // <- rounded corners
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: arrowColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
