import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/widgets/custom_button.dart';

/// Recommended mentor/teacher card built from real server data. Every field
/// except [name] is optional and its row is hidden when absent; the avatar
/// falls back to a neutral icon.
class CustomRecommendedMentors extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? role;
  final double? rating;
  final String? description;
  final String? languages;
  final String? pricePerHour;
  final VoidCallback onViewProfileTap;

  /// When null the "Book Session" button is hidden.
  final VoidCallback? onBookSessionTap;

  const CustomRecommendedMentors({
    super.key,
    required this.name,
    required this.onViewProfileTap,
    this.avatarUrl,
    this.role,
    this.rating,
    this.description,
    this.languages,
    this.pricePerHour,
    this.onBookSessionTap,
  });

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final size = Responsive.sp(52);
    final avatar = (avatarUrl ?? '').trim();
    final fallback = Container(
      width: size,
      height: size,
      color: AppColor.white.withValues(alpha: 0.15),
      child: Icon(Icons.person, color: AppColor.white, size: size * 0.6),
    );
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: avatar.isEmpty
                    ? fallback
                    : Image.network(
                        avatar,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => fallback,
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rating != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppColor.white,
                            size: Responsive.textScaleFactor * 16,
                          ),
                          SizedBox(width: Responsive.w(1)),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],
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
                    if (_has(role))
                      Text(
                        role!.trim(),
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
            ],
          ),
          if (_has(description)) ...[
            SizedBox(height: 12.h),
            Text(
              description!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColor.white, fontSize: 12.sp),
            ),
          ],
          if (_has(languages) || _has(pricePerHour)) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _has(languages)
                      ? Row(
                          children: [
                            Icon(Icons.language,
                                color: AppColor.white, size: 16.sp),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                languages!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColor.white),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                if (_has(pricePerHour))
                  Text(
                    pricePerHour!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColor.white,
                      fontSize: 14.sp,
                    ),
                  ),
              ],
            ),
          ],
          SizedBox(height: 12.h),
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
              if (onBookSessionTap != null) ...[
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomButton(
                    onTap: onBookSessionTap!,
                    text: "Book Session",
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.2),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
