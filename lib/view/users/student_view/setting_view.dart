import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';

class NotificationSettingView extends StatefulWidget {
  const NotificationSettingView({super.key});

  @override
  State<NotificationSettingView> createState() =>
      _NotificationSettingViewState();
}

class _NotificationSettingViewState extends State<NotificationSettingView> {
  bool _cancelation = false;
  bool _pushNotifications = false;
  bool _booking = false;
  bool _sessionReminder = false;
  bool _enableDisable = false;
  bool _passwordChange = false;
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
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
              _buildSwitchField(
                label: 'Booking',
                value: _booking,
                onChanged: (value) {
                  setState(() {
                    _booking = value;
                  });
                },
              ),
              _buildSwitchField(
                label: 'Session Reminder',
                value: _sessionReminder,
                onChanged: (value) {
                  setState(() {
                    _sessionReminder = value;
                  });
                },
              ),
              _buildSwitchField(
                label: 'Enable/Disable Email Alerts',
                value: _enableDisable,
                onChanged: (value) {
                  setState(() {
                    _enableDisable = value;
                  });
                },
              ),
              _buildSwitchField(
                label: 'Password Change Alert',
                value: _passwordChange,
                onChanged: (value) {
                  setState(() {
                    _passwordChange = value;
                  });
                },
              ),
              _buildSwitchField(
                label: 'Cancellation',
                value: _cancelation,
                onChanged: (value) {
                  setState(() {
                    _cancelation = value;
                  });
                },
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
