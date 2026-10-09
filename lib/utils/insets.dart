import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Bottom padding for modal bottom sheets so their last button clears the system navigation
/// bar. A sheet's MediaQuery has no system padding, and on the test Samsung (Android 16,
/// 3-button nav) the window reports only a 28 px bottom inset while the buttons are drawn
/// about 90 px tall, so the reported inset alone left buttons underneath (UAT L4). Use the
/// larger of the window's inset and a 32 dp minimum.
double sheetBottomInset(BuildContext context) {
  final view = View.of(context);
  return math.max(view.viewPadding.bottom / view.devicePixelRatio, 32.0);
}
