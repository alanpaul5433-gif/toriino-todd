import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:toriino_todd/config/app_config.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help & Support. There is no support-ticket backend, so the app does not pretend to file
/// tickets: it shows the support email (AppConfig.supportEmail) and opens the mail app.
/// Until the client provides that address, it says support contact is not available yet.
/// (Replaces a hard-coded sample ticket and a form that "submitted" without any API call —
/// UAT Round 4b H1.)
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  static const String _email = AppConfig.supportEmail;

  Future<void> _emailSupport() async {
    final uri = Uri(scheme: 'mailto', path: _email, queryParameters: {'subject': 'Torino app support'});
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) {
      await Clipboard.setData(const ClipboardData(text: _email));
      Utils.toastMassage('No email app found. Address copied: $_email');
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hasEmail = _email.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
                  SizedBox(width: Responsive.w(1)),
                  Text(
                    "Help & Support",
                    style: TextStyle(
                      fontSize: Responsive.textScaleFactor * 24,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.support_agent, color: AppColor.red, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      hasEmail ? 'Contact us' : 'Support contact coming soon',
                      style: TextStyle(color: AppColor.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasEmail
                          ? 'Email us at $_email and we will get back to you.'
                          : 'In-app support is not available yet. A support email address will be added here soon.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                    if (hasEmail) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _emailSupport,
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Email support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.red,
                          foregroundColor: AppColor.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
