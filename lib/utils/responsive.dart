import 'package:flutter/material.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  static late double textScaleFactor;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    textScaleFactor = _mediaQueryData.textScaler.scale(1.0);
    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }

  //   static double sp(double size) {
//   // 375 is a common "base width" (like iPhone 11)
//   double baseWidth = 375.0;

//   // Scale size relative to screen width
//   double scaledSize = size * (screenWidth / baseWidth);

//   // Also respect user’s text scale settings
//   return scaledSize * textScaleFactor;
// }


  static double w(double percent) => screenWidth * (percent / 100);
  static double h(double percent) => screenHeight * (percent / 100);
  static double sp(double size) => (size * (screenWidth / 3)) / 100;
  static double wp(double percent) => screenWidth * (percent / 100);
  static double hp(double percent) => screenHeight * (percent / 100);

  static EdgeInsets padding({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.fromLTRB(wp(left), hp(top), wp(right), hp(bottom));
  }

  static EdgeInsets margin({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.fromLTRB(wp(left), hp(top), wp(right), hp(bottom));
  }

  static SizedBox height(double percent) => SizedBox(height: h(percent));
  static SizedBox width(double percent) => SizedBox(width: w(percent));
}
