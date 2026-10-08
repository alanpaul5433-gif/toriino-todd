import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';

class OtpVerificationView extends StatefulWidget {
  final String email;
  final String name;
  final String role;

  /// The password just used to sign up. Kept in memory only, so the user can be signed in
  /// right after the code is confirmed (set-role needs a signed-in session).
  final String? password;

  const OtpVerificationView({
    super.key,
    required this.email,
    required this.name,
    required this.role,
    this.password,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resendCooldown = false;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_loading) return; // auto-submit on the 6th digit and the Verify button can race
    if (_otpCode.length < 6) {
      Utils.toastMassage("Please enter the 6-digit code");
      return;
    }
    setState(() => _loading = true);
    final result = await AuthService.confirmSignUp(
      email: widget.email,
      code: _otpCode,
    );

    if (result['success'] != true) {
      if (mounted) setState(() => _loading = false);
      Utils.toastMassage(result['message'] ?? "Verification failed");
    } else {
      // Confirming the code does not sign the user in. Sign in now so the role screen has
      // tokens for POST /auth/set-role; otherwise send the user to login with a clear message.
      final password = widget.password;
      final signIn = password == null || password.isEmpty
          ? const <String, dynamic>{'success': false}
          : await AuthService.signIn(email: widget.email, password: password);
      if (!mounted) return;
      if (signIn['success'] == true) {
        Utils.toastMassage("Email verified successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      } else {
        Utils.toastMassage("Email verified. Please log in to choose your role.");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => Loginview()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown) return;
    setState(() {
      _resendCooldown = true;
      _cooldownSeconds = 60;
    });
    final email = widget.email;
    final result = await AuthService.resendSignUpCode(email: email);
    if (!mounted) return;
    if (result['success'] == true) {
      Utils.toastMassage('Verification code resent');
    } else {
      Utils.toastMassage(result['message'] ?? 'Resend failed');
    }
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() => _resendCooldown = false);
      }
    });
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
                          text: _resendCooldown
                              ? "Resend in ${_cooldownSeconds}s"
                              : "Resend",
                          style: TextStyle(
                            color: _resendCooldown
                                ? AppColor.white.withValues(alpha: 0.4)
                                : AppColor.red,
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
