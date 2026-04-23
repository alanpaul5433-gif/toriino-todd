import 'dart:async';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';

class SplashServices {
  UsersPrefrence usersPrefrence = UsersPrefrence();

  void isLogin() {
    usersPrefrence.getUser().then((token) {
      if (token == null || token.isEmpty) {
        Timer(
          const Duration(seconds: 3),
          () => Get.offAllNamed(RoutesName.loginview),
        );
      } else {
        Timer(
          const Duration(seconds: 3),
          () => Get.offAllNamed(RoutesName.homeview),
        );
      }
    });
  }
}
