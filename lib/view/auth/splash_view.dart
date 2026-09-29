import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_bottom_nav_bar.dart';
import 'package:toriino_todd/view/users/student_view/bottom_nav_bar_holder.dart';
import 'package:toriino_todd/view/users/teacher/teacher_bottom_nav_bar.dart';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      _goTo(Loginview());
      return;
    }

    final prefs = UsersPrefrence();
    final role = await prefs.getUserRole();

    if (role == 'Mentor') {
      _goTo(MentorBottomNavBar());
    } else if (role == 'Teacher') {
      _goTo(TeacherBottomNavBar());
    } else if (role == 'Student') {
      _goTo(MainWrapper());
    } else {
      // Logged in but no role stored — send to role selection
      _goTo(const RoleSelectionScreen());
    }
  }

  void _goTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/Frame 1.svg",
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.02),
              SvgPicture.asset(
                "assets/images/TORIINO.svg",
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
