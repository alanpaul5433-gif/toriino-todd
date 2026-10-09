import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/subscriptions/plans_view.dart';
import 'package:toriino_todd/view/users/common_view/privacy_policy_view.dart';
import 'package:toriino_todd/view/users/student_view/change_password_view.dart';
import 'package:toriino_todd/view/users/student_view/setting_view.dart'
    show NotificationSettingView;
import 'package:toriino_todd/services/session_reset.dart';

/// Confirm-then-delete flow shared by the student/teacher and mentor
/// settings screens. The user must type DELETE before the destructive
/// button is enabled. DELETE /users/account removes both the Cognito user
/// and the profile record; only a 2xx is treated as success.
Future<void> confirmAndDeleteAccount(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (deleted != true || !context.mounted) return;

  // Account is gone server-side: same reset as Logout (session + cached controllers).
  await SessionReset.logOut(context, message: 'Your account has been deleted.');
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmCtrl = TextEditingController();
  bool _deleting = false;
  String? _error;

  bool get _confirmed => _confirmCtrl.text.trim() == 'DELETE';

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await UserRepo().deleteAccount();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = Utils.errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.primaryColor,
      title: const Text(
        'Delete Account',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account and all your data. This action cannot be undone.\n\nType DELETE to confirm.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            enabled: !_deleting,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'DELETE',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: (_confirmed && !_deleting) ? _delete : null,
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                )
              : Text(
                  'Delete permanently',
                  style: TextStyle(
                    color: _confirmed ? Colors.red : Colors.red.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 10,
            children: [
              SizedBox(height: Responsive.h(2)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
                  ),
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
              // Plans for the signed-in user's role (student or teacher), or "Plans coming soon".
              _buildSwitchField(
                path: 'assets/icons/setting.svg',
                text: 'Subscription',
                ontap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlansView()),
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
                    MaterialPageRoute(builder: (_) => ChangePasswordView()),
                  );
                },
              ),
              _buildSwitchField(
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
              _buildSwitchField(
                path: 'assets/icons/document-validation.svg',
                text: 'Privacy Policy',
                ontap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacyPolicyView()),
                  );
                },
              ),
              _buildSwitchField(
                path: 'assets/icons/lock-password (3).svg',
                text: 'Delete Account',
                ontap: () => confirmAndDeleteAccount(context),
                isDestructive: true,
              ),
            ],
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
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 12,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
