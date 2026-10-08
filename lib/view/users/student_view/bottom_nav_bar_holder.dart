// main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/common_view/Privacy_policy_view.dart';
import 'package:toriino_todd/view/users/student_view/ai_tutor_view.dart';
import 'package:toriino_todd/view/users/student_view/home_view.dart';
import 'package:toriino_todd/view/users/student_view/browse_mentor.dart';
import 'package:toriino_todd/view/users/student_view/course_view.dart';
import 'package:toriino_todd/view/users/student_view/settings.dart';
import 'package:toriino_todd/view/users/student_view/sessions.dart';
import 'package:toriino_todd/view/users/student_view/student_private_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/support_view.dart';
import 'package:toriino_todd/services/session_reset.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final CustomDrawerController _customDrawerController = Get.put(
    CustomDrawerController(),
  );

  DateTime? _lastBackPressTime;

  final List<Widget> _pages = [
    HomeView(),
    CourseView(),
    BrowseMentor(),
    SessionsView(),
    AiTutorView(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: AppColor.red),
      ),
      controller: _customDrawerController.advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      childDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      drawer: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          child: ListTileTheme(
            textColor: Colors.white,
            iconColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SvgPicture.asset("assets/icons/TORIINO.svg"),
                ),
                const SizedBox(height: 20),

                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    _customDrawerController.changeIndex(0);
                  },
                  leading: SvgPicture.asset("assets/icons/home.svg"),
                  title: const Text('Home'),
                ),
                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StudentProfile()),
                    );
                  },
                  leading: SvgPicture.asset("assets/icons/user-edit.svg"),
                  title: const Text('Profile'),
                ),
                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Settings(),
                      ),
                    );
                  },
                  leading: SvgPicture.asset("assets/icons/settings.svg"),
                  title: const Text('Settings'),
                ),
                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PrivacyPolicyView()),
                    );
                  },
                  leading: Icon(Icons.description, color: Colors.white),
                  title: const Text('Terms & Conditions'),
                ),
                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SupportView()),
                    );
                  },
                  leading: SvgPicture.asset(
                    "assets/icons/customer-service.svg",
                  ),
                  title: const Text('Help & Support'),
                ),

                Semantics(
                  label: 'Logout',
                  button: true,
                  child: ListTile(
                    onTap: () async {
                      _customDrawerController.advancedDrawerController
                          .hideDrawer();
                      // Signs out and clears every cached per-user controller (UAT H5).
                      await SessionReset.logOut(context);
                    },
                    leading: SvgPicture.asset("assets/icons/logout.svg"),
                    title: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) _onWillPop();
      },
        child: Scaffold(
          body: Obx(() => _pages[_customDrawerController.currentIndex.value]),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  void _onWillPop() {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Press back again to exit',
            style: TextStyle(fontSize: Responsive.textScaleFactor * 12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBottomNavBar() {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: _customDrawerController.currentIndex.value,
        onTap: (index) => _customDrawerController.changeIndex(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColor.primaryColor,
        selectedItemColor: AppColor.white,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/home.svg"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/books.svg"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/presentation_2657896 2.svg"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/mentoring.svg"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/robotic.svg"),
            label: '',
          ),
        ],
      ),
    );
  }
}
