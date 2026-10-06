import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/otp_verification_view.dart';
import 'package:toriino_todd/services/analytics_service.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:toriino_todd/widgets/radio_button.dart';
import 'package:google_fonts/google_fonts.dart';

class Sginupview extends StatefulWidget {
  const Sginupview({super.key});

  @override
  State<Sginupview> createState() => _SginupviewState();
}

class _SginupviewState extends State<Sginupview> {
  final ValueNotifier<bool> _obsecurePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);
  bool _termsAccepted = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FocusNode nameFoucsNode = FocusNode();
  FocusNode emailFoucsNode = FocusNode();
  FocusNode phoneFoucsNode = FocusNode();
  FocusNode passwordFoucsNode = FocusNode();
  FocusNode sumbitFoucsNode = FocusNode();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    nameFoucsNode.dispose();
    emailFoucsNode.dispose();
    phoneFoucsNode.dispose();
    passwordFoucsNode.dispose();
    sumbitFoucsNode.dispose();
    _obsecurePassword.dispose();
    _loading.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_termsAccepted) {
      Utils.toastMassage("Please accept the Terms & Privacy to continue");
      return;
    }
    if (nameController.text.isEmpty) {
      Utils.toastMassage("Please enter your full name");
      return;
    }
    if (emailController.text.isEmpty) {
      Utils.toastMassage("Please enter your email");
      return;
    }
    if (passwordController.text.isEmpty) {
      Utils.toastMassage("Please enter a password");
      return;
    }
    if (passwordController.text.length < 8) {
      Utils.toastMassage("Password must be at least 8 characters");
      return;
    }

    _loading.value = true;
    final result = await AuthService.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
    );
    _loading.value = false;

    if (result['success'] == true) {
      Utils.toastMassage("Account created! Please verify your email.");
      AnalyticsService.logSignUp(role: 'Student');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationView(
            email: emailController.text.trim(),
            name: nameController.text.trim(),
            role: 'Student',
          ),
        ),
      );
    } else {
      Utils.toastMassage(result['message'] ?? "Sign up failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive class

    // final ValueChanged<bool> value;
    Responsive.init(context);
    // final authViewmodel = Provider.of<AuthViewmodel>(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(3), // 5% of screen width
            vertical: Responsive.h(2), // 2% of screen height
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Responsive.h(2)), // 2% of screen height
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      "assets/images/login.svg",
                      width: Responsive.w(25), // 50% of screen width
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(1)),
                Text(
                  "Create Your Account",
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w900,
                    fontSize: Responsive.sp(25), // Responsive font size
                  ),
                ),
                SizedBox(height: Responsive.h(0.5)),
                Text(
                  "Create your account to explore about our app",
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.normal,
                    fontSize: Responsive.sp(10.5),
                  ),
                ),
                SizedBox(height: Responsive.h(3)),
                TextFormField(
                  style: TextStyle(color: AppColor.white),
                  controller: nameController,
                  focusNode: nameFoucsNode,
                  cursorColor: AppColor.red,
                  cursorErrorColor: AppColor.red,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.w(12),
                      ), // 6% of width
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(Responsive.w(4)), // 2% of width
                      child: SvgPicture.asset(
                        "assets/icons/user-multiple-02.svg",
                      ),
                    ),
                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    hintText: "Full Name",
                    hintStyle: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontWeight: FontWeight.normal,
                      fontSize: Responsive.textScaleFactor * 14,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    Utils.fieldFoucsChange(
                      context,
                      nameFoucsNode,
                      emailFoucsNode,
                    );
                  },
                ),
                SizedBox(height: Responsive.h(1)),
                //
                TextFormField(
                  style: TextStyle(color: AppColor.white),
                  controller: emailController,
                  focusNode: emailFoucsNode,
                  cursorColor: AppColor.red,
                  cursorErrorColor: AppColor.red,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.w(12),
                      ), // 6% of width
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(Responsive.w(4)), // 2% of width
                      child: SvgPicture.asset("assets/icons/mail-02.svg"),
                    ),
                    filled: true,

                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    hintText: "Email Address",
                    hintStyle: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontWeight: FontWeight.normal,
                      fontSize: Responsive.textScaleFactor * 14,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    Utils.fieldFoucsChange(
                      context,
                      emailFoucsNode,
                      phoneFoucsNode,
                    );
                  },
                ),
                SizedBox(height: Responsive.h(1)),
                //
                TextFormField(
                  style: TextStyle(color: AppColor.white),
                  controller: phoneController,
                  focusNode: phoneFoucsNode,
                  cursorColor: AppColor.red,
                  cursorErrorColor: AppColor.red,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.w(12),
                      ), // 6% of width
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(Responsive.w(4)), // 2% of width
                      child: SvgPicture.asset("assets/icons/call.svg"),
                    ),
                    filled: true,

                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    hintText: "Phone Number",
                    hintStyle: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontWeight: FontWeight.normal,
                      fontSize: Responsive.textScaleFactor * 14,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    Utils.fieldFoucsChange(
                      context,
                      phoneFoucsNode,
                      passwordFoucsNode,
                    );
                  },
                ),

                SizedBox(height: Responsive.h(1)),
                ValueListenableBuilder(
                  valueListenable: _obsecurePassword,
                  builder: (context, value, child) {
                    return TextFormField(
                      style: TextStyle(color: AppColor.white),
                      controller: passwordController,
                      focusNode: passwordFoucsNode,
                      cursorColor: AppColor.red,
                      cursorErrorColor: AppColor.red,
                      obscureText: _obsecurePassword.value,
                      obscuringCharacter: "*",
                      decoration: InputDecoration(
                        focusColor: AppColor.white,
                        filled: true,
                        fillColor: AppColor.white.withValues(alpha: 0.08),
                        hintText: "Password",
                        hintStyle: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.normal,
                          fontSize: Responsive.textScaleFactor * 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                          borderSide: BorderSide(color: AppColor.red),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                          borderSide: BorderSide(color: AppColor.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColor.focusedBorder),
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(Responsive.w(4)),
                          child: SvgPicture.asset(
                            "assets/icons/lock-password (3).svg",
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _obsecurePassword.value = !_obsecurePassword.value;
                          },
                          child: Icon(
                            _obsecurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColor.white,
                            size: Responsive.sp(14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: Responsive.h(1.5)),
                Row(
                  spacing: 5,
                  children: [
                    TickRadioButton(
                      value: _termsAccepted,
                      onChanged: (v) => setState(() => _termsAccepted = v),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Agree to',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                          TextSpan(
                            text: ' Terms & Privacy',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: Responsive.h(1.5)),
                ValueListenableBuilder<bool>(
                  valueListenable: _loading,
                  builder: (context, isLoading, _) => AuthButton(
                    buttontext: "Sign Up",
                    loading: isLoading,
                    onPress: _handleSignUp,
                  ),
                ),
                SizedBox(height: Responsive.h(4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        text: "Have an account? ",
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: Responsive.sp(12),
                        ),
                        children: [
                          TextSpan(
                            text: "Login here",
                            style: TextStyle(
                              color: AppColor.red,
                              fontSize: Responsive.sp(12),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigator.pushReplacementNamed(
                                    //   context,
                                    //   RoutesName.loginview,
                                    // );
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Loginview(),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
