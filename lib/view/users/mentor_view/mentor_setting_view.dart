import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/student_view/setting_view.dart'
    show NotificationSettingView;
import 'package:google_fonts/google_fonts.dart';

class MentorSettingView extends StatelessWidget {
  const MentorSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              spacing: 10,
              children: [
                SizedBox(height: Responsive.h(2)),
                Row(
                  children: [
                    SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
                    SizedBox(width: Responsive.w(2)),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Rethink Sans',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),
            
                _buildSwitchField(
                  path: 'assets/icons/setting.svg',
                  text: 'Subscription',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationSettingView(),
                      ),
                    );
                  },
                ),
                _buildSwitchField(
                  path: 'assets/icons/notification.svg',
                  text: 'Notifications',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationSettingView(),
                      ),
                    );
                  },
                ),
                _buildSwitchField(
                  path: 'assets/icons/lock-password (3).svg',
                  text: 'Change Password',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationSettingView(),
                      ),
                    );
                  },
                ),
                _buildSwitchField(
                  path: 'assets/icons/language-circle.svg',
                  text: 'Change Language',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationSettingView(),
                      ),
                    );
                  },
                ),
                _buildSwitchField(
                  path: 'assets/icons/document-validation.svg',
                  text: 'Privacy Policy',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationSettingView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildSwitchField({
  required VoidCallback ontap,
  required String path,
  required String text,
}) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: Responsive.padding(left: 3, right: 3, top: 2, bottom: 2),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.white.withValues(alpha: 0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(path),
              ),
            ),
            SizedBox(width: Responsive.w(2)),
            Text(
              text,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: Responsive.textScaleFactor * 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
