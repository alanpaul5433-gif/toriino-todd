import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';

class NotificationPermission extends StatefulWidget {
  const NotificationPermission({super.key});

  @override
  State<NotificationPermission> createState() => _NotificationPermissionState();
}

class _NotificationPermissionState extends State<NotificationPermission> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor:AppColor.primaryColor,
      appBar: AppBar(
       foregroundColor: AppColor.white,
        backgroundColor:AppColor.primaryColor,
        title: Text(
          "Notifications",
          style: TextStyle(
            color: AppColor.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(
          // horizontal: horizontalPadding.w,
          vertical: 41.h,
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: 375.h, maxHeight: 375.h),

          padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color:AppColor.primaryColor,

            borderRadius: BorderRadius.circular(19.r),
          ),
          child: Column(
            children: [
              NotificationTile(text: "Daily Study Reminder"),
              Row(children: [Expanded(child: Divider(color: AppColor.white))]),
              // CustomDivider(),
              NotificationTile(text: "Quiz Completion Reminder"),
              Row(children: [Expanded(child: Divider(color: AppColor.white))]),

              // CustomDivider(),
              NotificationTile(text: "New Content Updates"),
              Row(children: [Expanded(child: Divider(color: AppColor.white))]),

              // CustomDivider(),
              NotificationTile(text: "App Announcements"),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatefulWidget {
  final String text;
  // final String text;

  const NotificationTile({super.key, required this.text});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.text,
              style: TextStyle(
                color: AppColor.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            CustomSwitch(),
          ],
        ),
      ),
    );
  }
}

class CustomSwitch extends StatefulWidget {
  const CustomSwitch({super.key});

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  bool isSwitchOn = false;
  @override
  Widget build(BuildContext context) {
    return SwitchTheme(
      data: SwitchThemeData(
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),

        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColor.baseColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.all(Color(0xffEAEAEA)),
      ),
      child: Switch(
        activeThumbColor: AppColor.red,
        // activeTrackColor: AppColor.primaryColor,
        inactiveThumbColor: AppColor.primaryColor,
        splashRadius: 0, // optional: to prevent ripple on tap
        value: isSwitchOn,
        onChanged: (value) {
          setState(() {
            isSwitchOn = value;
          });
        },
      ),
    );
  }
}
