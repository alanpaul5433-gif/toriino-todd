import 'package:get/get.dart';
import 'package:getxmvvm/resources/routes/routes_name.dart';
import 'package:getxmvvm/view/users/student_view/home_view.dart';
import 'package:getxmvvm/view/auth/login_view.dart';
import 'package:getxmvvm/view/auth/role_selector_view.dart';
import 'package:getxmvvm/view/auth/sign_up_view.dart';
import 'package:getxmvvm/view/auth/splash_view.dart';

class AppRoutes {
  static appRoutes() => [
    GetPage(
      name: RoutesName.splashview,
      page: () => SplashView(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.loginview,
      page: () => Loginview(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.role,
      page: () => RoleSelectionScreen(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.signup,
      page: () => Sginupview(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: RoutesName.homeview,
      page: () => HomeView(),
      transitionDuration: const Duration(milliseconds: 200),
      transition: Transition.rightToLeft,
    ),
  ];
}
