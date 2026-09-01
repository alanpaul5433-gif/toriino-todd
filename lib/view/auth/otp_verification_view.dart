import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';

class OtpVerificationView extends StatefulWidget {
  final String email;
  final String name;
  final String role;

  const OtpVerificationView({
    super.key,
    required this.email,
    required this.name,
    required this.role,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      Utils.toastMassage("Please enter the 6-digit code");
      return;
    }
    setState(() => _loading = true);
    final result = await AuthService.confirmSignUp(
      email: widget.email,
      code: _otpCode,
    );
    setState(() => _loading = false);

    if (result['success'] == true) {
      Utils.toastMassage("Email verified successfully!");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } else {
      Utils.toastMassage(result['message'] ?? "Verification failed");
    }
  }

  Future<void> _resendCode() async {
    Utils.toastMassage("Resending code...");
    // Resend is handled by Cognito automatically on new sign up attempt
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(6),
            vertical: Responsive.h(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Responsive.h(4)),
              Text(
                "Verify Your Email",
                style: GoogleFonts.rethinkSans(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(24),
                ),
              ),
              SizedBox(height: Responsive.h(1)),
              Text(
                "We sent a 6-digit code to\n${widget.email}",
                style: GoogleFonts.dmSans(
                  color: AppColor.white.withValues(alpha: 0.7),
                  fontSize: Responsive.sp(12),
                ),
              ),
              SizedBox(height: Responsive.h(5)),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: Responsive.w(13),
                    height: Responsive.h(7),
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: Responsive.sp(20),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColor.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColor.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColor.red, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColor.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        if (i == 5 && val.isNotEmpty) _verifyOtp();
                      },
                    ),
                  );
                }),
              ),

              SizedBox(height: Responsive.h(5)),
              AuthButton(
                buttontext: "Verify",
                loading: _loading,
                onPress: _verifyOtp,
              ),
              SizedBox(height: Responsive.h(3)),
              Center(
                child: GestureDetector(
                  onTap: _resendCode,
                  child: Text.rich(
                    TextSpan(
                      text: "Didn't receive code? ",
                      style: TextStyle(
                        color: AppColor.white.withValues(alpha: 0.6),
                        fontSize: Responsive.sp(12),
                      ),
                      children: [
                        TextSpan(
                          text: "Resend",
                          style: TextStyle(
                            color: AppColor.red,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
