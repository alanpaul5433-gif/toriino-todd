import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/widgets/components/drop_down_text.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherEarinigView extends StatelessWidget {
  const TeacherEarinigView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 1, right: 1, top: 1),
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Earnings',
                              style: GoogleFonts.rethinkSans(
                                color: Colors.white,
                                fontSize: Responsive.sp(12),
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.20,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/presentation_2657896 2.svg',
                          ),
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
                  // In your build method:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // Align to right if needed
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColor.red,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: Responsive.padding(
                            left: 1.5,
                            right: 1.5,
                            top: 0.5,
                            bottom: 0.5,
                          ),
                          child: Text(
                            'Withdraw',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.sp(10),
                              // fontSize: Responsive.textScaleFactor * 12,
                              fontWeight: FontWeight.w700,
                              height: 1.80,
                            ),
                          ),
                        ),
                      ),
                      SortByDropdown(),
                    ],
                  ),

                  // Or as a standalone widget:

                  //this Mouth ,Total Withdrawn
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColor.white.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Column(
                              spacing: Responsive.h(1),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Month',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.sp(10),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                                Text(
                                  '\$320.00',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 25,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(1)),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColor.white.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Column(
                              spacing: Responsive.h(1),

                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Withdrawn',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                       fontSize: Responsive.sp(10),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                                Text(
                                  '\$-120.00',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 25,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.h(1)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Remaining Balance',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                    Text(
                                      '\$540.00',
                                      style: GoogleFonts.rethinkSans(
                                        color: Colors.white,
                                        fontSize:
                                            Responsive.textScaleFactor * 25,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(1)),

                  Text(
                    'Recent Sessions History',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                  SizedBox(height: Responsive.h(1)),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 10,
                    itemBuilder: ((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColor.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColor.white.withValues(
                                                alpha: 0.20,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: SvgPicture.asset(
                                                "assets/icons/Vector (10).svg",
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: Responsive.w(1)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Session with Jamie Dunn ',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Responsive
                                                          .textScaleFactor *
                                                      12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                '1hr',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Responsive
                                                          .textScaleFactor *
                                                      12,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '-\$130',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.rethinkSans(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 25,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
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
