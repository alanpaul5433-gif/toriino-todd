import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:toriino_todd/widgets/radio_button.dart';
// social_button removed — social login not implemented yet
import 'package:google_fonts/google_fonts.dart';

class Sginupview extends StatefulWidget {
  const Sginupview({super.key});

  @override
  State<Sginupview> createState() => _SginupviewState();
}

class _SginupviewState extends State<Sginupview> {
  final ValueNotifier<bool> _obsecurePassword = ValueNotifier<bool>(true);
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
    super.dispose();
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
                      borderSide: BorderSide(color: AppColor.red),
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
                      borderSide: BorderSide(color: AppColor.red),
                      borderRadius: BorderRadius.circular(Responsive.w(12)),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(Responsive.w(4)), // 2% of width
                      child: SvgPicture.asset("assets/icons/mail-02.svg"),
                    ),
                    filled: true,

                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    hintText: "Email Adress",
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
                      borderSide: BorderSide(color: AppColor.red),
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
                          borderSide: BorderSide(color: AppColor.red),
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
                    TickRadioButton(value: true),
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
                AuthButton(
                  buttontext: "Sign Up",
                  loading: false,
                  onPress: () {
                    if (emailController.text.isEmpty) {
                      Utils.toastMassage("Please Enter Email First");
                    } else if (passwordController.text.isEmpty) {
                      Utils.toastMassage("Please Enter Password First");
                    } else if (passwordController.text.length < 8) {
                      Utils.toastMassage("Please Enter 8 digits");
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoleSelectionScreen(),
                        ),
                      );
                      // Navigate to

                      // Map<String, String> headr = {
                      //   "x-api-key": "reqres-free-v1",
                      // };
                      // Map data = {
                      //   'email': emailController.text.toString(),
                      //   'password': passwordController.text.toString(),
                      // };
                      // // authViewmodel.loginApi(data, headr, context);
                    }
                  },
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
