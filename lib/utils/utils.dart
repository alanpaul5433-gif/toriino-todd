import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';

class Utils {
  static void fieldFoucsChnage(
    BuildContext context,
    FocusNode current,
    FocusNode nextfoucs,
  ) {
    current.unfocus();
    FocusScope.of(context).requestFocus(nextfoucs);
  }
  static void fieldFoucsChange(
    BuildContext context,
    FocusNode current,
    FocusNode nextFoucs,
  ) {
    current.unfocus();
    FocusScope.of(context).requestFocus(nextFoucs);
  }
  static toastMassage(String meassage) {
    Fluttertoast.showToast(
      msg: meassage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: AppColor.primaryColor,
      textColor: AppColor.white,
      fontSize: 16.0,
    );
  }

  static toastMassageCenter(String meassage) {
    Fluttertoast.showToast(
      // webBgColor: [AppColor.primaryColor,AppColor.white],
      msg: meassage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: AppColor.primaryColor,
      textColor: AppColor.white,
      fontSize: 16.0,
    );
  }

  // static void flushBarErrorMassage(String message, BuildContext context) {
  //   showFlushbar(
  //     context: context,
  //     flushbar: Flushbar(
  //       forwardAnimationCurve: Curves.decelerate,
  //       reverseAnimationCurve: Curves.easeInOut,
  //       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //       padding: const EdgeInsets.all(15),
  //       //backgroudColors
  //       message: message,
  //       borderRadius: BorderRadius.circular(20),
  //       backgroundColor: AppColor.red,
  //       title: "Error",
  //       titleColor: AppColor.white,
  //       messageColor: AppColor.black,
  //       positionOffset: 20,
  //       flushbarPosition: FlushbarPosition.TOP,
  //       icon: Icon(Icons.error, size: 28, color: Colors.white),
  //       duration: Duration(seconds: 3),
  //     )..show(context),
  //   );
  // }

  static snackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.white,
      colorText: AppColor.primaryColor,
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColor.primaryColor,
        size: 30,
      ),
    );
  }
}
