import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 16,
              children: [
                Row(
                  spacing: 2,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                    ),
                    Text(
                      'Terms & Conditions',
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
                Text(
                  '1. Acceptance of Terms\n\nBy accessing or using the Torino platform, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DM Sans', fontWeight: FontWeight.w400, height: 1.67),
                ),
                Text(
                  '2. User Accounts\n\nYou are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate information during registration. Torino reserves the right to suspend accounts that violate these terms.',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DM Sans', fontWeight: FontWeight.w400, height: 1.67),
                ),
                Text(
                  '3. Platform Use\n\nTorino connects students, teachers, and mentors. You agree not to misuse the platform, share inappropriate content, or engage in fraudulent activity. Sessions booked through the platform must be conducted professionally.',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DM Sans', fontWeight: FontWeight.w400, height: 1.67),
                ),
                Text(
                  '4. Payments & Refunds\n\nAll payments are processed securely through Stripe. Refund eligibility is subject to the cancellation policy stated at the time of booking. Torino takes a platform fee on each transaction.',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DM Sans', fontWeight: FontWeight.w400, height: 1.67),
                ),
                Text(
                  '5. Privacy\n\nYour data is stored securely on AWS. We do not sell your personal information to third parties. By using Torino you consent to our data collection practices as described in our Privacy Policy.\n\nLast updated: October 2026',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DM Sans', fontWeight: FontWeight.w400, height: 1.67),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
