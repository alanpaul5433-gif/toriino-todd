import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordView extends StatefulWidget {
 const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final ValueNotifier<bool> _obsecureOldPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obsecureNewPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obsecureConfirmPassword = ValueNotifier<bool>(
    true,
  );

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode oldPasswordFocus = FocusNode();
  final FocusNode newPasswordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode saveFoucs = FocusNode();
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving) return;
    final oldPw = oldPasswordController.text;
    final newPw = newPasswordController.text;
    final confirmPw = confirmPasswordController.text;
    if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      Utils.toastMassage('Please fill in all password fields');
      return;
    }
    if (newPw != confirmPw) {
      Utils.toastMassage('New passwords do not match');
      return;
    }
    if (newPw == oldPw) {
      Utils.toastMassage('New password must be different from the current one');
      return;
    }
    setState(() => _saving = true);
    final result = await AuthService.changePassword(
      oldPassword: oldPw,
      newPassword: newPw,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final ok = result['success'] == true;
    Utils.toastMassage(
      (result['message'] as String?) ??
          (ok ? 'Password changed successfully' : 'Password change failed'),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  void dispose() {
    _obsecureOldPassword.dispose();
    _obsecureNewPassword.dispose();
    _obsecureConfirmPassword.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              spacing: 10,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        "assets/icons/Arrow - Right 3 (1).svg",
                      ),
                    ),
                    SizedBox(width: Responsive.w(1)),
                    Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: Responsive.textScaleFactor * 24,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number and a special character (e.g. !\$@%).',
                  style: TextStyle(fontSize: 16, color: AppColor.white),
                ),

                ValueListenableBuilder(
                  valueListenable: _obsecureOldPassword,
                  builder: (context, value, child) {
                    return TextFormField(
                      style: TextStyle(color: AppColor.white),
                      controller: oldPasswordController,
                      focusNode: oldPasswordFocus,
                      cursorColor: AppColor.red,
                      cursorErrorColor: AppColor.red,
                      obscureText: _obsecureOldPassword.value,
                      obscuringCharacter: "*",
                      decoration: InputDecoration(
                        focusColor: AppColor.white,
                        filled: true,
                        fillColor: AppColor.white.withValues(alpha: 0.08),
                        hintText: "Old Password",
                        hintStyle: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.normal,
                          fontSize: Responsive.sp(15),
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
                          padding: EdgeInsets.all(Responsive.w(3)),
                          child: SvgPicture.asset(
                            "assets/icons/lock-password (3).svg",
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _obsecureOldPassword.value =
                                !_obsecureOldPassword.value;
                          },
                          child: Icon(
                            _obsecureOldPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:
                                _obsecureOldPassword.value
                                    ? AppColor.white
                                    : AppColor.red,
                            size: Responsive.sp(20),
                          ),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        Utils.fieldFoucsChange(
                          context,
                          oldPasswordFocus,
                          newPasswordFocus,
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _obsecureNewPassword,
                  builder: (context, value, child) {
                    return TextFormField(
                      style: TextStyle(color: AppColor.white),
                      controller: newPasswordController,
                      focusNode: newPasswordFocus,
                      cursorColor: AppColor.red,
                      cursorErrorColor: AppColor.red,
                      obscureText: _obsecureNewPassword.value,
                      obscuringCharacter: "*",
                      decoration: InputDecoration(
                        focusColor: AppColor.white,
                        filled: true,
                        fillColor: AppColor.white.withValues(alpha: 0.08),
                        hintText: "New Password",
                        hintStyle: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.normal,
                          fontSize: Responsive.sp(15),
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
                          padding: EdgeInsets.all(Responsive.w(3)),
                          child: SvgPicture.asset(
                            "assets/icons/lock-password (3).svg",
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _obsecureNewPassword.value =
                                !_obsecureNewPassword.value;
                          },
                          child: Icon(
                            _obsecureNewPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:
                                _obsecureNewPassword.value
                                    ? AppColor.white
                                    : AppColor.red,
                            size: Responsive.sp(20),
                          ),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        Utils.fieldFoucsChange(
                          context,
                          newPasswordFocus,
                          confirmPasswordFocus,
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _obsecureConfirmPassword,
                  builder: (context, value, child) {
                    return TextFormField(
                      style: TextStyle(color: AppColor.white),
                      controller: confirmPasswordController,
                      focusNode: confirmPasswordFocus,
                      cursorColor: AppColor.red,
                      cursorErrorColor: AppColor.red,
                      obscureText: _obsecureConfirmPassword.value,
                      obscuringCharacter: "*",
                      decoration: InputDecoration(
                        focusColor: AppColor.white,
                        filled: true,
                        fillColor: AppColor.white.withValues(alpha: 0.08),
                        hintText: "Confirm Password",
                        hintStyle: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.normal,
                          fontSize: Responsive.sp(15),
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
                          padding: EdgeInsets.all(Responsive.w(3)),
                          child: SvgPicture.asset(
                            "assets/icons/lock-password (3).svg",
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _obsecureConfirmPassword.value =
                                !_obsecureConfirmPassword.value;
                          },
                          child: Icon(
                            _obsecureConfirmPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:
                                _obsecureConfirmPassword.value
                                    ? AppColor.white
                                    : AppColor.red,
                            size: Responsive.sp(20),
                          ),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        Utils.fieldFoucsChange(
                          context,
                          confirmPasswordFocus,
                          saveFoucs,
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _saving ? null : _submit,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: AppColor.red,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                _saving ? "Saving..." : "Save",
                                style: GoogleFonts.dmSans(
                                  fontSize: Responsive.textScaleFactor*16,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SvgPicture.asset("assets/icons/arrow.svg"),
                            ],
                          ),
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
