import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';
import 'package:toriino_todd/view/auth/admin_notice_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/view/auth/sign_up_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_bottom_nav_bar.dart';
import 'package:toriino_todd/services/fcm_service.dart';
import 'package:toriino_todd/view/users/student_view/bottom_nav_bar_holder.dart';
import 'package:toriino_todd/view/users/teacher/teacher_bottom_nav_bar.dart';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';
import 'package:toriino_todd/services/analytics_service.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:google_fonts/google_fonts.dart';

class Loginview extends StatefulWidget {
  const Loginview({super.key});

  @override
  State<Loginview> createState() => _LoginviewState();
}

class _LoginviewState extends State<Loginview> {
  final ValueNotifier<bool> _obsecurePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FocusNode emailFoucsNode = FocusNode();
  FocusNode passwordFoucsNode = FocusNode();
  FocusNode sumbitFoucsNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordFoucsNode.dispose();
    emailFoucsNode.dispose();
    _obsecurePassword.dispose();
    _loading.dispose();
  }

  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty) {
      Utils.toastMassage("Please Enter Email First");
      return;
    }
    if (!_looksLikeEmail(emailController.text)) {
      Utils.toastMassage("Please enter a valid email address");
      return;
    }
    if (passwordController.text.isEmpty) {
      Utils.toastMassage("Please Enter Password First");
      return;
    }
    if (passwordController.text.length < 8) {
      Utils.toastMassage("Password must be at least 8 characters");
      return;
    }

    _loading.value = true;
    final result = await AuthService.signIn(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    _loading.value = false;

    if (result['success'] == true) {
      Utils.toastMassage("Login successful!");
      AnalyticsService.logLogin();
      if (!mounted) return;
      // Always persist the role fresh from the JWT token to avoid stale state
      final jwtRole = (result['role'] as String?)?.toLowerCase();
      if (jwtRole != null) {
        await UsersPrefrence().saveUserRole(jwtRole);
      }
      final savedRole = jwtRole ?? (await UsersPrefrence().getUserRole())?.toLowerCase();
      if (!mounted) return;
      try { Get.find<CustomDrawerController>().changeIndex(0); } catch (_) {}
      FcmService.registerAfterLogin();
      if (savedRole == 'admin') {
        // Admins use the web panel; never offer them the role picker.
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminNoticeView()));
      } else if (savedRole == 'student') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainWrapper()));
      } else if (savedRole == 'mentor') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MentorBottomNavBar()));
      } else if (savedRole == 'teacher') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherBottomNavBar()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
      }
    } else {
      Utils.toastMassage(result['message'] ?? "Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive class
    Responsive.init(context);
    // final authViewmodel = Provider.of<AuthViewmodel>(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(5), // 5% of screen width
            vertical: Responsive.h(2), // 2% of screen height
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Responsive.h(2)), // 2% of screen height
                SvgPicture.asset(
                  "assets/images/login.svg",
                  width: Responsive.w(25), // 50% of screen width
                ),
                SizedBox(height: Responsive.h(2)),
                Text(
                  "Welcome Back!",
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(25), // Responsive font size
                  ),
                ),
                SizedBox(height: Responsive.h(1)),
                Text(
                  "Log in to explore about our app",
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.normal,
                    fontSize: Responsive.sp(10.5),
                  ),
                ),
                SizedBox(height: Responsive.h(3)),
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
                      passwordFoucsNode,
                    );
                  },
                ),
                SizedBox(height: Responsive.h(3)),
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
                            size: Responsive.textScaleFactor * 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: Responsive.h(1.5)),
                GestureDetector(
                  // The whole row is tappable, not only the glyphs of the text (UAT L2).
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _showForgotPasswordBottomSheet(context, emailController);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: Responsive.w(5)),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(10),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(2.5)),
                ValueListenableBuilder<bool>(
                  valueListenable: _loading,
                  builder: (context, isLoading, _) => AuthButton(
                    buttontext: "Login",
                    loading: isLoading,
                    onPress: _handleLogin,
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                    child: Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        text: "New here? ",
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: Responsive.sp(12),
                        ),
                        children: [
                          TextSpan(
                            text: "Create an account",
                            style: TextStyle(
                              color: AppColor.red,
                              fontSize: Responsive.sp(12),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Sginupview(),
                                      ),
                                    );
                                    // Navigator.pushReplacementNamed(
                                    //   context,
                                    //   RoutesName.signup,
                                    // );
                                  },
                          ),
                        ],
                      ),
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

bool _looksLikeEmail(String value) =>
    RegExp(r'^[^s@]+@[^s@]+.[^s@]{2,}$').hasMatch(value.trim());

void _showForgotPasswordBottomSheet(
  BuildContext context,
  TextEditingController email,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (context) {
      String? error; // shown under the field: a toast was hidden behind the sheet (UAT L3)
      bool sending = false;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> send() async {
            final value = email.text.trim();
            if (value.isEmpty || !_looksLikeEmail(value)) {
              setSheetState(() => error = value.isEmpty
                  ? 'Please enter your email'
                  : 'Please enter a valid email address');
              return;
            }
            setSheetState(() { error = null; sending = true; });
            final result = await AuthService.forgotPassword(email: value);
            if (!context.mounted) return;
            if (result['success'] == true) {
              Navigator.pop(context);
              Utils.toastMassage(result['message'] ?? "Reset code sent");
              Get.toNamed(RoutesName.resetPassword, arguments: {'email': value});
            } else {
              // Never report success when the request failed.
              setSheetState(() {
                sending = false;
                error = result['message'] ?? 'Could not send the reset code. Please try again.';
              });
            }
          }

          return Padding(
            // Keyboard inset plus the system navigation bar, so the button is never covered (UAT L4).
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).viewPadding.bottom,
              left: Responsive.w(5),
              right: Responsive.w(5),
              top: Responsive.h(3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Forgot Password?",
                  style: GoogleFonts.dmSans(
                    color: AppColor.white,
                    fontSize: Responsive.sp(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Enter your registered email address. We’ll send you a code to reset your password.",
                  style: GoogleFonts.dmSans(
                    color: AppColor.white,
                    fontSize: Responsive.sp(10),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                TextFormField(
                  style: TextStyle(color: AppColor.white),
                  controller: email,
                  cursorColor: AppColor.red,
                  cursorErrorColor: AppColor.red,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (error != null) setSheetState(() => error = null);
                  },
                  decoration: InputDecoration(
                    errorText: error,
                    errorStyle: GoogleFonts.dmSans(color: AppColor.red, fontSize: Responsive.sp(10)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                      borderSide: BorderSide(color: AppColor.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(Responsive.w(3)),
                      child: SvgPicture.asset("assets/icons/mail-02.svg"),
                    ),
                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    hintText: "Email Address",
                    hintStyle: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontWeight: FontWeight.normal,
                      fontSize: Responsive.sp(15),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                AuthButton(
                  buttontext: "Send Reset Code",
                  onPress: sending ? () {} : send,
                  loading: sending,
                ),
                SizedBox(height: Responsive.h(2)),
              ],
            ),
          );
        },
      );
    },
  );
}
