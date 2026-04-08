import 'package:flutter/material.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AuthButton extends StatelessWidget {
  final String? buttontext;
  final bool loading;
  final VoidCallback onPress;
  const AuthButton({
    super.key,
    required this.buttontext,
    required this.loading,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: MediaQuery.sizeOf(context).width * 1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColor.red,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
            child:
                loading
                    ? CustomLoadingAnimation()
                    : Text(
                      buttontext.toString(),
                      style: GoogleFonts.dmSans(
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(12),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class CustomLoadingAnimation extends StatelessWidget {
  const CustomLoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: Colors.white,
      size: MediaQuery.sizeOf(context).height * 0.02,
    );
  }
}
