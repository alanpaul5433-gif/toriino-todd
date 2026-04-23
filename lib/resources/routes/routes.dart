import 'package:get/get.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';
import 'package:toriino_todd/view/users/student_view/home_view.dart';
import 'package:toriino_todd/view/auth/login_view.dart';
import 'package:toriino_todd/view/auth/role_selector_view.dart';
import 'package:toriino_todd/view/auth/sign_up_view.dart';
import 'package:toriino_todd/view/auth/splash_view.dart';

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
