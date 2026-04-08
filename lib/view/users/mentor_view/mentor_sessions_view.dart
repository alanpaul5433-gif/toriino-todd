import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/getx_controllers/advanceddrawercontroller.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/mentor_view/mentor_availability.dart';
import 'package:getxmvvm/view/users/student_view/notification_view.dart';
import 'package:getxmvvm/widgets/components/drop_down_text.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorSessionsView extends StatelessWidget {
  const MentorSessionsView({super.key});

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
                              'Sessions',
                              style: GoogleFonts.rethinkSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 20,
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
                                  'Total Sessions Taken',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '56',
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
                      SizedBox(width: Responsive.w(4)),
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
                                  'Upcoming Sessions',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '02',
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
                    'Upcoming Sessions',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                  SizedBox(height: Responsive.h(1)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: AssetImage(
                                        "assets/images/michel.png",
                                      ),
                                    ),
                                    SizedBox(width: 10),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                            Row(
                              children: [
                                Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                            Text(
                              "4 May, 3:00 PM – 4:00 PM",
                              style: GoogleFonts.dmSans(
                                fontSize: Responsive.textScaleFactor * 25,
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
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Group",
                                      style: GoogleFonts.dmSans(
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColor.white,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Duration",
                                      style: GoogleFonts.dmSans(
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "1hr",
                                      style: GoogleFonts.dmSans(
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColor.white,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Seats Left",
                                      style: GoogleFonts.dmSans(
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "2-5",
                                      style: GoogleFonts.dmSans(
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        color: AppColor.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColor.white,
                                ),
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
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
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
                                Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => MentorAvailability(),
                                          ),
                                        ),
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
                                          spacing: 2,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Start Session",
                                              style: GoogleFonts.dmSans(
                                                fontSize: 14,
                                                color: AppColor.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SvgPicture.asset(
                                              "assets/icons/arrow.svg",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: Responsive.w(2)),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    color: AppColor.white.withValues(
                                      alpha: 0.20,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SvgPicture.asset(
                                      "assets/icons/bubble-chat.svg",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // Align to right if needed
                    children: [
                      Text(
                        'Recent History',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                      SortByDropdown(),
                    ],
                  ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 10,
                    itemBuilder: ((context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
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
                                SizedBox(height: Responsive.h(1)),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: AssetImage(
                                            "assets/images/michel.png",
                                          ),
                                        ),
                                        SizedBox(width: Responsive.w(2)),

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                        Text(
                                          '+\$30',
                                          style: GoogleFonts.rethinkSans(
                                            color: Colors.white,
                                            fontSize:
                                                Responsive.textScaleFactor * 25,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.30,
                                          ),
                                        ),
                                        SizedBox(width: Responsive.w(2)),

                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            color: AppColor.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SvgPicture.asset(
                                              "assets/icons/bubble-chat.svg",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(child: Divider(thickness: 1)),
                                  ],
                                ),
                                SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Type",
                                          style: GoogleFonts.dmSans(
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Group",
                                          style: GoogleFonts.dmSans(
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: AppColor.white,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Duration",
                                          style: GoogleFonts.dmSans(
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "1hr",
                                          style: GoogleFonts.dmSans(
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: AppColor.white,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Seats Left",
                                          style: GoogleFonts.dmSans(
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "2-5",
                                          style: GoogleFonts.dmSans(
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: AppColor.white,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: Responsive.h(1)),
                              ],
                            ),
                          ),
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
