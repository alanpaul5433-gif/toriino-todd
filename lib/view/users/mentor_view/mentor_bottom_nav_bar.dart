// main_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/common_view/Privacy_policy_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_home_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_home_viewmodel.dart';
import 'package:toriino_todd/view/users/mentor_view/earinig_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_private_profile_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_sessions_view.dart';
import 'package:toriino_todd/view/users/student_view/ai_tutor_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_availability.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_setting_view.dart';
import 'package:toriino_todd/view/users/student_view/support_view.dart';
import 'package:toriino_todd/services/session_reset.dart';

class MentorBottomNavBar extends StatefulWidget {
  const MentorBottomNavBar({super.key});

  @override
  State<MentorBottomNavBar> createState() => _MentorBottomNavBarState();
}

class _MentorBottomNavBarState extends State<MentorBottomNavBar> {
  final CustomDrawerController _customDrawerController = Get.put(
    CustomDrawerController(),
  );
  DateTime? _lastBackPressTime;

  final List<Widget> _pages = [
    MentorHomeView(),
    EarinigView(),
    MentorSessionsView(),
    MentorPrivateProfileView(),
    AiTutorView(tag: 'mentor'),
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
                Obx(() {
                  final vm = Get.find<MentorHomeViewmodel>();
                  final avatarUrl = vm.rxProfile.value.data?.avatarUrl;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                  );
                }),
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
                    _customDrawerController.changeIndex(3);
                  },
                  leading: SvgPicture.asset("assets/icons/user-edit.svg"),
                  title: const Text('Profile'),
                ),
                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    Get.to(() => const MentorAvailability());
                  },
                  leading: const Icon(Icons.event_available, color: Colors.white),
                  title: const Text('Availability'),
                ),
                ListTile(
                  onTap: () {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MentorSettingView(),
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

                ListTile(
                  onTap: () async {
                    _customDrawerController.advancedDrawerController
                        .hideDrawer();
                    // Signs out and clears every cached per-user controller (UAT H5).
                    await SessionReset.logOut(context);
                  },
                  leading: SvgPicture.asset("assets/icons/logout.svg"),
                  title: const Text('Logout'),
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
            icon: SvgPicture.asset("assets/icons/wallet.svg"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/presentation_2657896 2.svg"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/user-sharing.svg"),
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
