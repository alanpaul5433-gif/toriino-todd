import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';

class GernernalException extends StatefulWidget {
  final VoidCallback onPressed;
  const GernernalException({super.key, required this.onPressed});

  @override
  State<GernernalException> createState() => GernernalExceptionState();
}

class GernernalExceptionState extends State<GernernalException> {
  final height = Get.height;
  final width = Get.width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_rounded,
            color: AppColor.primaryColor,
            size: height * 0.05,
          ),
          SizedBox(height: height * 0.025),

          Text(
            "general_exception".tr,
            style: TextStyle(
              color: AppColor.primaryColor,
              fontSize: height * 0.020,
            ),
          ),
          SizedBox(height: height * 0.05),
          GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              alignment: Alignment.center,
              height: height * 0.05,
              width: width * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColor.primaryColor,
              ),
              child: Text(
                "Retry",
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
