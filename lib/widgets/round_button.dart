import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RoundButton extends StatefulWidget {
  final Color baseColor;
  final Color textcolor;
  final String title;
  final bool isloading;
  final double width;
  final double height;
  final VoidCallback onpress;

  const RoundButton({
    super.key,
    required this.baseColor,
    required this.onpress,
    required this.textcolor,
    required this.isloading,
    required this.title,
    required this.height,
    required this.width,
  });

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onpress,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.baseColor,
        ),
        child:
            widget.isloading
                ? Center(
                  child: Text(
                    widget.title,
                    style: TextStyle(color: widget.textcolor),
                  ),
                )
                : Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white,
                    size: widget.height * 0.5,
                  ),
                ),
      ),
    );
  }
}
