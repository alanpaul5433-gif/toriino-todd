import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/session_reset.dart';

/// Shown when an admin account signs in to the mobile app. Admins have no in-app role
/// (they are managed by the Cognito Admins group), so they must never see the role picker:
/// choosing a role there could only fail. The admin tools live in the web panel.
class AdminNoticeView extends StatefulWidget {
  const AdminNoticeView({super.key});

  @override
  State<AdminNoticeView> createState() => _AdminNoticeViewState();
}

class _AdminNoticeViewState extends State<AdminNoticeView> {
  bool _loggingOut = false;

  Future<void> _logOut() async {
    setState(() => _loggingOut = true);
    await SessionReset.logOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: AppColor.red, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Admin account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rethinkSans(fontSize: 28, color: AppColor.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please use the admin web panel. The mobile app is for students, teachers and mentors.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rethinkSans(fontSize: 16, color: AppColor.white),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _loggingOut ? null : _logOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.red,
                    foregroundColor: AppColor.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: _loggingOut
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Log out', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
