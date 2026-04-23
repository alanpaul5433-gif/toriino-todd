import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/Mentor_Subcirption_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_private_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/view/users/student_view/student_public_profile_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_home_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorHomeView extends StatelessWidget {
  MentorHomeView({super.key});

  final MentorHomeViewmodel mentorController = Get.put(MentorHomeViewmodel());

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 2, right: 2, top: 2),
          child: ListView(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MentorPrivateProfileView(),
                              ),
                            ),
                        child: Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: Responsive.sp(20),
                                backgroundImage: AssetImage(
                                  "assets/icons/Ellipse 6 (1).png",
                                ),
                              ),
                              SizedBox(width: Responsive.wp(1)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(() {
                                    final profile = mentorController.rxProfile.value;
                                    final name = profile.status == Status.success ? profile.data?.name ?? 'Mentor' : 'Mentor';
                                    return Text(
                                    'Hi $name',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.sp(10),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.30,
                                    ),
                                  );
                                  }),
                                  Text(
                                    'Mentor',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.sp(10),
                                      fontWeight: FontWeight.w400,
                                      height: 1.60,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.backGroundColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: SvgPicture.asset('assets/icons/time.svg'),
                            ),
                          ),
                          SizedBox(width: Responsive.wp(2)),

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
                                padding: const EdgeInsets.all(6.0),
                                child: SvgPicture.asset(
                                  'assets/icons/notification.svg',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: Responsive.wp(2)),
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
                                padding: const EdgeInsets.all(6.0),
                                child: SvgPicture.asset(
                                  'assets/icons/menu.svg',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    spacing: 6,
                    children: [
                      bloc(
                        title: "Total Sessions",
                        value: "26",
                     
                      ),
                      bloc(
                        title: "Upcoming Sessions",
                        value: "03",
                       
                      ),
                      bloc(
                        title: "Average Rating",
                        value: "4.8",
                      
                      ),
                      // bloc("Total Sessions Taken", "26"),
                      // bloc("Upcoming Sessions", "03"),
                      // bloc("Average Rating", "4.8"),
                    ],
                  ),
                  SizedBox(height: Responsive.hp(2)),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Total Earnings',
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontSize: Responsive.sp(10),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.20,
                                ),
                              ),
                              Text(
                                '\$540.00',
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontSize: Responsive.sp(18),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 178,
                          height: 43,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 122,
                                top: 10.75,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFE73121),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 1.50,
                                        color: Colors.white,
                                      ),
                                      borderRadius: BorderRadius.circular(39),
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: Color(0x7FE73121),
                                        blurRadius: 7.10,
                                        offset: Offset(0, 1),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 143.42,
                                top: 0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 3,
                                  children: [
                                    Text(
                                      'Month',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 3,
                                top: 0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 3,
                                  children: [
                                    Text(
                                      '+1.5 ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w700,
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
                  SizedBox(height: Responsive.hp(2)),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: Responsive.padding(
                        left: 2,
                        right: 2,
                        bottom: 2,
                        top: 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Stand out with a Verified Badge',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: Responsive.sp(14),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.30,
                                ),
                              ),
                              Spacer(),
                              SvgPicture.asset(
                                "assets/icons/bitcoin-icons_verify-filled.svg",
                              ),
                            ],
                          ),
                          Text(
                            'Boost your profile and get listed as a featured mentor to increase your bookings.',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                          SizedBox(height: Responsive.hp(2)),

                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MentorSubcirptionView(),
                                  ),
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFE73121),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    'Boost Now',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  SvgPicture.asset("assets/icons/arrow.svg"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.hp(2)),

                  Text(
                    'Upcoming Sessions',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                  SizedBox(height: Responsive.hp(2)),
                  test(context),
                  SizedBox(height: Responsive.hp(2)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Sessions History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),

                      Row(
                        children: [
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
                          SvgPicture.asset(
                            "assets/icons/eva_arrow-up-fill.svg",
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.hp(2)),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: ((context, index) {
                      return recentSessionsHistoryCard(context);
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget test(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: AppColor.white.withValues(alpha: 0.08),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage("assets/images/michel.png"),
                  ),
                  SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Michel",
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Student",
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    "assets/icons/material-symbols_star (1).svg",
                  ),
                  Text(
                    "4.8",
                    style: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(children: [Expanded(child: Divider(thickness: 1))]),
          Text(
            "4 May, 3:00 PM – 4:00 PM",
            style: GoogleFonts.dmSans(
              fontSize: Responsive.textScaleFactor * 20,
              color: AppColor.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          Row(
            spacing: 4,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Type",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Group",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: AppColor.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Duration",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "1hr",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: AppColor.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Seats Left",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "2-5",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: AppColor.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Language",
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "English / Arabic",
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(children: [Expanded(child: Divider(thickness: 1))]),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppColor.red,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Session",
                          style: GoogleFonts.dmSans(
                            fontSize: Responsive.textScaleFactor * 14,
                            color: AppColor.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: Responsive.wp(2)),

                        SvgPicture.asset("assets/icons/arrow.svg"),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.wp(2)),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColor.white.withValues(alpha: 0.20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset("assets/icons/bubble-chat.svg"),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.hp(2)),
        ],
      ),
    ),
  );
  // return Container(
  //   padding: const EdgeInsets.all(15),
  //   decoration: ShapeDecoration(
  //     color: Colors.white.withValues(alpha: 0.08),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //   ),
  //   child: Column(
  //     mainAxisSize: MainAxisSize.min,
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     spacing: 10,
  //     children: [
  //       Container(
  //         width: 323,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           mainAxisAlignment: MainAxisAlignment.start,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           spacing: 15,
  //           children: [
  //             Container(
  //               width: double.infinity,
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 spacing: 12,
  //                 children: [
  //                   Container(
  //                     width: double.infinity,
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       spacing: 61,
  //                       children: [
  //                         GestureDetector(
  //                           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>StudentPublicProfileView())),
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.min,
  //                             mainAxisAlignment: MainAxisAlignment.start,
  //                             crossAxisAlignment: CrossAxisAlignment.center,
  //                             spacing: 10,
  //                             children: [
  //                               CircleAvatar(
  //                                 backgroundImage: AssetImage(
  //                                   "assets/images/michel.png",
  //                                 ),
  //                               ),
  //                               Column(
  //                                 mainAxisSize: MainAxisSize.min,
  //                                 mainAxisAlignment: MainAxisAlignment.start,
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   SizedBox(
  //                                     width: 44,
  //                                     child: Text(
  //                                       'Michel',
  //                                       style: TextStyle(
  //                                         color: Colors.white,
  //                                         fontSize: 12,
  //                                         fontFamily: 'DM Sans',
  //                                         fontWeight: FontWeight.w700,
  //                                         letterSpacing: -0.20,
  //                                       ),
  //                                     ),
  //                                   ),
  //                                   SizedBox(
  //                                     width: 44,
  //                                     child: Text(
  //                                       'Student',
  //                                       style: TextStyle(
  //                                         color: Colors.white,
  //                                         fontSize: 12,
  //                                         fontFamily: 'DM Sans',
  //                                         fontWeight: FontWeight.w400,
  //                                         letterSpacing: -0.20,
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Container(
  //                     width: double.infinity,
  //                     decoration: ShapeDecoration(
  //                       shape: RoundedRectangleBorder(
  //                         side: BorderSide(
  //                           width: 1,
  //                           strokeAlign: BorderSide.strokeAlignCenter,
  //                           color: Colors.white.withValues(alpha: 0.20),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     mainAxisAlignment: MainAxisAlignment.end,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     // spacing: 2,
  //                     children: [
  //                       Text(
  //                         '10 May, 3:00 PM – 4:00 PM',
  //                         style: GoogleFonts.rethinkSans(
  //                           color: Colors.white,
  //                           fontSize: Responsive.textScaleFactor*25,
  //                           fontWeight: FontWeight.w500,
  //                           letterSpacing: -0.30,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   Container(
  //                     width: double.infinity,
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       spacing: 19,
  //                       children: [
  //                         Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           mainAxisAlignment: MainAxisAlignment.start,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           spacing: 5,
  //                           children: [
  //                             SizedBox(
  //                               width: 35,
  //                               child: Text(
  //                                 'Type',
  //                                 style: GoogleFonts.dmSans(
  //                                   color: Colors.white,
  //                                   fontSize: Responsive.textScaleFactor*12,
  //                                   fontWeight: FontWeight.w700,
  //                                 ),
  //                               ),
  //                             ),
  //                             SizedBox(
  //                               width: 35,
  //                               child: Text(
  //                                 'Group',
  //                                 style: GoogleFonts.dmSans(
  //                                   color: Colors.white,
  //                                   fontSize: Responsive.textScaleFactor*12,
  //                                   fontWeight: FontWeight.w400,
  //                                   letterSpacing: -0.20,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         Container(
  //                           transform:
  //                               Matrix4.identity()
  //                                 ..translate(0.0, 0.0)
  //                                 ..rotateZ(1.57),
  //                           width: 35,
  //                           decoration: ShapeDecoration(
  //                             shape: RoundedRectangleBorder(
  //                               side: BorderSide(
  //                                 width: 1,
  //                                 strokeAlign: BorderSide.strokeAlignCenter,
  //                                 color: Colors.white.withValues(alpha: 0.20),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                         Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           mainAxisAlignment: MainAxisAlignment.start,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           spacing: 5,
  //                           children: [
  //                             SizedBox(
  //                               width: 51,
  //                               child: Text(
  //                                 'Duration',
  //                                 style: GoogleFonts.dmSans(
  //                                   color: Colors.white,
  //                                   fontSize:Responsive.textScaleFactor* 12,
  //                                   fontWeight: FontWeight.w700,
  //                                 ),
  //                               ),
  //                             ),
  //                             SizedBox(
  //                               width: 51,
  //                               child: Text(
  //                                 '1hr',
  //                                 style: GoogleFonts.dmSans(
  //                                   color: Colors.white,
  //                                   fontSize: Responsive.textScaleFactor*12,
  //                                   fontWeight: FontWeight.w400,
  //                                   letterSpacing: -0.20,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         Container(
  //                           transform:
  //                               Matrix4.identity()
  //                                 ..translate(0.0, 0.0)
  //                                 ..rotateZ(1.57),
  //                           width: 35,
  //                           decoration: ShapeDecoration(
  //                             shape: RoundedRectangleBorder(
  //                               side: BorderSide(
  //                                 width: 1,
  //                                 strokeAlign: BorderSide.strokeAlignCenter,
  //                                 color: Colors.white.withValues(alpha: 0.20),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                         Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           mainAxisAlignment: MainAxisAlignment.start,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           spacing: 5,
  //                           children: [
  //                             Text(
  //                               'Seats Left',
  //                               style: GoogleFonts.dmSans(
  //                                 color: Colors.white,
  //                                 fontSize: Responsive.textScaleFactor*12,
  //                                 fontWeight: FontWeight.w700,
  //                               ),
  //                             ),
  //                             SizedBox(
  //                               width: 60,
  //                               child: Text(
  //                                 '2-5',
  //                                 style: GoogleFonts.dmSans(
  //                                   color: Colors.white,
  //                                   fontSize: Responsive.textScaleFactor*12,
  //                                   fontWeight: FontWeight.w400,
  //                                   letterSpacing: -0.20,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         Container(
  //                           transform:
  //                               Matrix4.identity()
  //                                 ..translate(0.0, 0.0)
  //                                 ..rotateZ(1.57),
  //                           width: 35,
  //                           decoration: ShapeDecoration(
  //                             shape: RoundedRectangleBorder(
  //                               side: BorderSide(
  //                                 width: 1,
  //                                 strokeAlign: BorderSide.strokeAlignCenter,
  //                                 color: Colors.white.withValues(alpha: 0.20),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                         Column(
  //                           mainAxisSize: MainAxisSize.min,
  //                           mainAxisAlignment: MainAxisAlignment.start,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           spacing: 5,
  //                           children: [
  //                             Text(
  //                               'Language',
  //                               style: GoogleFonts.dmSans(
  //                                 color: Colors.white,
  //                                 fontSize: Responsive.textScaleFactor*12,
  //                                 fontWeight: FontWeight.w700,
  //                               ),
  //                             ),
  //                             Text(
  //                               'English / Arabic',
  //                               style: GoogleFonts.dmSans(
  //                                 color: Colors.white,
  //                                 fontSize: Responsive.textScaleFactor*12,
  //                                 fontWeight: FontWeight.w400,
  //                                 letterSpacing: -0.20,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Container(
  //                     width: double.infinity,
  //                     decoration: ShapeDecoration(
  //                       shape: RoundedRectangleBorder(
  //                         side: BorderSide(
  //                           width: 1,
  //                           strokeAlign: BorderSide.strokeAlignCenter,
  //                           color: Colors.white.withValues(alpha: 0.20),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Container(
  //               width: double.infinity,
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 spacing: 10,
  //                 children: [
  //                   Expanded(
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 18,
  //                         vertical: 8,
  //                       ),
  //                       decoration: ShapeDecoration(
  //                         color: AppColor.red,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(40),
  //                         ),
  //                       ),
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         crossAxisAlignment: CrossAxisAlignment.center,
  //                         spacing: 8,
  //                         children: [
  //                           Row(
  //                             children: [
  //                               Text(
  //                                 'Start Session',
  //                                 textAlign: TextAlign.center,
  //                                 style: GoogleFonts.dmSans(
  //                                   color: Colors.white,
  //                                   fontSize:Responsive.textScaleFactor* 14,
  //                                   fontWeight: FontWeight.w500,
  //                                   letterSpacing: -0.20,
  //                                 ),
  //                               ),
  //                               SizedBox(width: Responsive.wp(2)),
  //                               SvgPicture.asset("assets/icons/arrow.svg"),
  //                             ],
  //                           ),
  //                           Container(
  //                             transform:
  //                                 Matrix4.identity()
  //                                   ..translate(0.0, 0.0)
  //                                   ..rotateZ(1.57),
  //                             height: 18,
  //                             clipBehavior: Clip.antiAlias,
  //                             decoration: BoxDecoration(),
  //                             child: Stack(),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   Container(
  //                     width: 34,
  //                     height: 34,
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 18,
  //                       vertical: 16,
  //                     ),
  //                     clipBehavior: Clip.antiAlias,
  //                     decoration: ShapeDecoration(
  //                       color: Colors.white.withValues(alpha: 0.20),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(40),
  //                       ),
  //                     ),
  //                     child: SvgPicture.asset("assets/icons/bubble-chat.svg"),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   ),
  // );
}

Widget recentSessionsHistoryCard(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Responsive.hp(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentPublicProfileView(),
                        ),
                      ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage("assets/images/michel.png"),
                      ),
                      SizedBox(width: Responsive.wp(2)),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Alfredo Workman",
                            style: GoogleFonts.dmSans(
                              color: AppColor.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Student",
                            style: GoogleFonts.dmSans(
                              color: AppColor.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '+\$30',
                      style: GoogleFonts.rethinkSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 25,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.30,
                      ),
                    ),
                    SizedBox(width: Responsive.wp(2)),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: AppColor.white.withValues(alpha: 0.08),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset("assets/icons/bubble-chat.svg"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(children: [Expanded(child: Divider(thickness: 1))]),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Type",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Group",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Duration",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "1hr",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Seats Left",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "2-5",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Language",
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "English / Arabic",
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Widget bloc(String text, String value) {
//   return Expanded(
//     child: Padding(
//       padding: Responsive.padding(left: 1, right: 1, bottom: 1, top: 1),
//       child: Container(
//         height: Responsive.hp(12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(22),
//           color: AppColor.white.withValues(alpha: 0.08),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(4.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 text,
//                 style: GoogleFonts.dmSans(
//                   color: Colors.white,
//                   fontSize: Responsive.sp(10),
//                   fontWeight: FontWeight.w400,
//                   letterSpacing: -0.20,
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Text(
//                     value,
//                     textAlign: TextAlign.right,
//                     style: GoogleFonts.dmSans(
//                       color: Colors.white,
//                       fontSize: Responsive.sp(20),
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: -0.30,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

Widget bloc({
  required String title,
  required String value,
  Color? backgroundColor,
  Color? textColor,
  IconData? icon,
  double? height,
  EdgeInsets? margin,
}) {
  return Expanded(
    child: Padding(
      padding: margin ?? Responsive.padding(left: 0, right: 0, bottom: 1, top: 1),
      child: Container(
        height: height ?? Responsive.hp(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor ?? AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: textColor ?? Colors.white,
                        fontSize: Responsive.sp(8),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      size: Responsive.sp(14),
                      color: textColor ?? Colors.white,
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                      color: textColor ?? Colors.white,
                      fontSize: Responsive.sp(18),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
