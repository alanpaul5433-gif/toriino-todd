import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/common_view/privacy_policy_view.dart';
import 'package:toriino_todd/view/users/mentor_view/Mentor_Subcirption_view.dart' show MentorSubcirptionView;
import 'package:toriino_todd/view/users/student_view/change_password_view.dart';
import 'package:toriino_todd/view/users/student_view/settings.dart'
    show confirmAndDeleteAccount;
import 'package:toriino_todd/view/users/student_view/setting_view.dart'
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
                    const Text(
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
                _buildMentorSettingTile(
                  path: 'assets/icons/setting.svg',
                  text: 'Subscription',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MentorSubcirptionView(),
                      ),
                    );
                  },
                ),
                _buildMentorSettingTile(
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
                _buildMentorSettingTile(
                  path: 'assets/icons/lock-password (3).svg',
                  text: 'Change Password',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChangePasswordView()),
                    );
                  },
                ),
                _buildMentorSettingTile(
                  path: 'assets/icons/language-circle.svg',
                  text: 'Change Language',
                  ontap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColor.primaryColor,
                        title: const Text(
                          'Select Language',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ['English', 'Urdu', 'Arabic'].map((lang) =>
                            ListTile(
                              title: Text(
                                lang,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                // The app has no translations yet: say so instead of pretending the language changed (UAT M4).
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(lang == 'English'
                                      ? 'The app is in English.'
                                      : '$lang is not available yet. The app is in English for now.')),
                                );
                              },
                            ),
                          ).toList(),
                        ),
                      ),
                    );
                  },
                ),
                _buildMentorSettingTile(
                  path: 'assets/icons/document-validation.svg',
                  text: 'Privacy Policy',
                  ontap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PrivacyPolicyView()),
                    );
                  },
                ),
                _buildMentorSettingTile(
                  path: 'assets/icons/lock-password (3).svg',
                  text: 'Delete Account',
                  ontap: () => confirmAndDeleteAccount(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildMentorSettingTile({
  required VoidCallback ontap,
  required String path,
  required String text,
  bool isDestructive = false,
}) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDestructive
            ? Colors.red.withValues(alpha: 0.12)
            : AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: Responsive.padding(left: 3, right: 3, top: 2, bottom: 2),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColor.white.withValues(alpha: 0.08),
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
                color: isDestructive ? Colors.red : Colors.white,
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
