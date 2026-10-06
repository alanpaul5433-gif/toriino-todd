import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/edit_mentor_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_home_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorPrivateProfileView extends StatelessWidget {
  const MentorPrivateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    final MentorHomeViewmodel profileVm = Get.find<MentorHomeViewmodel>();
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Profile',
                        style: GoogleFonts.rethinkSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/icons/time.svg'),
                      ),
                    ),
                    SizedBox(width: Responsive.w(2)),

                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationsScreen(),
                            ),
                          ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/notification.svg',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(2)),
                    GestureDetector(
                      onTap:
                          customDrawerController
                              .advancedDrawerController
                              .toggleDrawer,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset('assets/icons/menu.svg'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(1)),

                //Profile Pic Name Domain and Share Icon
                SizedBox(height: Responsive.h(2)),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        CircleAvatar(
                          radius: Responsive.w(10),
                          backgroundImage: AssetImage(
                            "assets/icons/Ellipse 6 (1).png",
                          ),
                        ),
                        SizedBox(width: Responsive.w(2)),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Obx(() {
                                  final profile = profileVm.rxProfile.value.data;
                                  return Text(
                                    profile?.name ?? '',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 18,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  );
                                }),
                                SizedBox(width: Responsive.w(2)),

                                SvgPicture.asset(
                                  'assets/icons/bitcoin-icons_verify-filled (1).svg',
                                ),
                              ],
                            ),
                            Obx(() {
                              profileVm.rxProfile.value; // reactive trigger
                              return Text(
                                'Mentor Profile',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: Responsive.textScaleFactor * 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.20,
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),

                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.white.withValues(alpha: 0.08),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/icons/share.svg'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Industry',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      ),
                    ),

                    Obx(() {
                      final profile = profileVm.rxProfile.value.data;
                      final industry = (profile?.interests?.isNotEmpty == true)
                          ? profile!.interests!.first
                          : '--';
                      return Text(
                        industry,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.20,
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Years of Experience',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      ),
                    ),

                    Obx(() {
                      final profile = profileVm.rxProfile.value.data;
                      return Text(
                        profile?.experience ?? '--',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.20,
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                Obx(() {
                  final profile = profileVm.rxProfile.value.data;
                  final bio = (profile?.bio != null && profile!.bio!.isNotEmpty)
                      ? profile.bio!
                      : 'No bio yet. Tap Edit Profile to add one.';
                  return Text(
                    bio,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 12,
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  );
                }),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Obx(() {
                      final profile = profileVm.rxProfile.value.data;
                      final loc = (profile?.location != null && profile!.location!.isNotEmpty)
                          ? profile.location!
                          : (profile?.email != null ? profile!.email! : '—');
                      return Row(
                        children: [
                          SvgPicture.asset("assets/icons/mic.svg"),
                          Text(
                            loc,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 10,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ],
                      );
                    }),

                    Obx(() {
                      final profile = profileVm.rxProfile.value.data;
                      final rate = profile?.hourlyRate != null
                          ? '\$${profile!.hourlyRate!.toStringAsFixed(0)}/hr'
                          : '--';
                      return Text(
                        rate,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.20,
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditMentorProfileView(),
                        ),
                      ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColor.white),
                      color: AppColor.primaryColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: Responsive.padding(top: 1, bottom: 1),
                      child: Center(
                        child: Text(
                          'Edit Profile',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                //Divider
                Row(children: [Expanded(child: Divider())]),

                SizedBox(height: Responsive.h(2)),

                Text(
                  'Expertise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),

                //Skill cipsviewview
                Obx(() {
                  final profile = profileVm.rxProfile.value.data;
                  final chips = (profile?.interests != null && profile!.interests!.isNotEmpty)
                      ? profile.interests!
                      : <String>['--'];
                  return Wrap(
                    spacing: 5,
                    runSpacing: 10,
                    children: chips
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.40),
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intro Video',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.red,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(3),
                          vertical: Responsive.h(0.8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Edit',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 10,
                                fontWeight: FontWeight.w700,
                                height: 1.80,
                              ),
                            ),
                            SizedBox(width: Responsive.w(1)),
                            SvgPicture.asset(
                              "assets/icons/iconamoon_edit-fill.svg",
                              width: Responsive.w(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                //video view
                // Container(
                //   height: 100,
                //   width: double.infinity,
                //   color: AppColor.red,
                // ),
                SvgPicture.asset("assets/icons/Frame 1410120834.svg"),
                SizedBox(height: Responsive.h(2)),

                //reivew and viewa all
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reviews',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'View all',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                //comments card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 9,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 9,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: ShapeDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              "assets/icons/Ellipse 6.png",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 3,
                                        children: [
                                          Text(
                                            '--',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.30,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '15 Days Ago',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 325,
                              child: Text(
                                "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 9,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 9,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: ShapeDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              "assets/icons/Ellipse 6.png",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 3,
                                        children: [
                                          Text(
                                            '--',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.30,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 13,
                                                height: 13,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '15 Days Ago',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 325,
                              child: Text(
                                "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
