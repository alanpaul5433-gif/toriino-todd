import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';

class NotificationSettingView extends StatefulWidget {
  const NotificationSettingView({super.key});

  @override
  State<NotificationSettingView> createState() =>
      _NotificationSettingViewState();
}

class _NotificationSettingViewState extends State<NotificationSettingView> {
  // Notification preferences are not stored anywhere yet (push needs Firebase, which is not
  // configured). The switches used to flip and silently reset; now they stay off and say so
  // (UAT Round 4b M3).
  final bool _cancelation = false;
  final bool _pushNotifications = false;
  final bool _booking = false;
  final bool _sessionReminder = false;
  final bool _enableDisable = false;
  final bool _passwordChange = false;

  void _notAvailable() =>
      Utils.toastMassage('Notification preferences are not available yet.');
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
                    // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>MainWrapper())),
                    child: SvgPicture.asset(
                      "assets/icons/Arrow - Right 3 (1).svg",
                    ),
                  ),
                  SizedBox(width: Responsive.w(2)),
                  Text(
                    'Notification Settings',
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
                label: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (_) => _notAvailable(),
              ),
              _buildSwitchField(
                label: 'Booking',
                value: _booking,
                onChanged: (_) => _notAvailable(),
              ),
              _buildSwitchField(
                label: 'Session Reminder',
                value: _sessionReminder,
                onChanged: (_) => _notAvailable(),
              ),
              _buildSwitchField(
                label: 'Enable/Disable Email Alerts',
                value: _enableDisable,
                onChanged: (_) => _notAvailable(),
              ),
              _buildSwitchField(
                label: 'Password Change Alert',
                value: _passwordChange,
                onChanged: (_) => _notAvailable(),
              ),
              _buildSwitchField(
                label: 'Cancellation',
                value: _cancelation,
                onChanged: (_) => _notAvailable(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSwitchField({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: AppColor.white.withValues(alpha: 0.08),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.20,
                ),
              ),
            ),
          ),
          Switch(
            splashRadius: 9.5,
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColor.white,
            activeTrackColor: AppColor.red,
          ),
        ],
      ),
    ),
  );
}
