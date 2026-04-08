import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/widgets/custom_button.dart';

class CustomRecommendedTeacher extends StatelessWidget {
  final String imagePath;
  final String name;
  final String role;
  final double rating;
  final String description;
  final String languages;
  final String pricePerHour;
  final VoidCallback onViewProfileTap;
  final VoidCallback onBookSessionTap;
  final String headerText;

  const CustomRecommendedTeacher({
    super.key,
    required this.imagePath,
    required this.name,
    required this.role,
    required this.rating,
    required this.description,
    required this.languages,
    required this.pricePerHour,
    required this.onViewProfileTap,
    required this.onBookSessionTap,
    required this.headerText,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Container(
      padding: EdgeInsets.all(15.r),
      margin: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text

          // Top Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(
                  imagePath,
                  width: Responsive.sp(52),
                  height: Responsive.sp(52),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12.w),

              // Name, Rating, Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColor.white,
                          size: Responsive.textScaleFactor * 16,
                        ),
                        SizedBox(width: Responsive.w(1)),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.textScaleFactor * 16,
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                      ),
                    ),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.settings_outlined, color: Colors.white70, size: 18.sp),
            ],
          ),

          SizedBox(height: 12.h),

          // Description
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColor.white, fontSize: 12.sp),
          ),

          SizedBox(height: 12.h),

          // Language + Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.language, color: AppColor.white, size: 16.sp),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        languages,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColor.white),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                pricePerHour,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColor.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onTap: onViewProfileTap,
                  icon: Icons.arrow_forward,
                  text: "View Profile",
                  backgroundColor: const Color(0xFFE73121),
                ),
              ),

              // SizedBox(width: 10.w),
              // Expanded(
              //   child: CustomButton(
              //     onTap: onBookSessionTap,
              //     // icon: Icons.arrow_forward,
              //     text: "Book Session",
              //     backgroundColor: Color.fromRGBO(255, 255, 255, 0.2),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
