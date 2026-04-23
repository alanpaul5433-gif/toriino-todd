import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/view/auth/login_view.dart';

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
    await Future.delayed(const Duration(milliseconds: 500));
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Loginview()
        ),
        // RoutesName.loginview
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive values
    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // final iconSize = screenWidth * 0.6; // 60% of screen width

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
