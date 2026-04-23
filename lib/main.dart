import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/resources/getx_localization/language.dart';
import 'package:toriino_todd/resources/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          theme: ThemeData(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: AppColor.red,
              selectionColor: AppColor.red.withValues(
                alpha: 0.5,
              ), // Changed from withValues to withOpacity
              selectionHandleColor: AppColor.red,
            ),
            // colorScheme: ColorScheme.fromSwatch(primarySwatch: AppColor.red),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          translations: Language(),

          ///urdu language
          // locale: Locale('ur','PK'),
          locale: Locale('en', 'US'),
          fallbackLocale: Locale('en', 'US'),
          // home: SplashView(),
          // RoleSelectionScreen(),
          getPages: AppRoutes.appRoutes(),
        );
      },
    );
  }
}
