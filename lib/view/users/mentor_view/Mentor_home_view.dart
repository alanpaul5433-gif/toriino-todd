import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/Mentor_Subcirption_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_private_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_home_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';
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
            padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MentorPrivateProfileView(),
                                ),
                              ),
                          child: Row(
                            children: [
                              Obx(() {
                                final avatarUrl = mentorController.rxProfile.value.data?.avatarUrl;
                                return CircleAvatar(
                                  radius: Responsive.sp(20),
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl) as ImageProvider
                                      : const AssetImage("assets/icons/Ellipse 6 (1).png"),
                                );
                              }),
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
                          Semantics(
                            label: 'Open menu',
                            button: true,
                            child: GestureDetector(
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
                          ),
                        ],
                      ),
                    ],
                  ),

                  Obx(() {
                    final sessionsState = mentorController.rxSessions.value;
                    final sessions = sessionsState.data?.sessions ?? [];
                    final totalSessions = sessions.length;
                    final upcoming = sessions.where((s) => s.status == 'scheduled').length;
                    final hasData = sessionsState.data != null;
                    return Row(
                      spacing: 6,
                      children: [
                        bloc(title: "Total Sessions", value: hasData ? totalSessions.toString() : '--'),
                        bloc(title: "Upcoming Sessions", value: hasData ? upcoming.toString() : '--'),
                        bloc(title: "Average Rating", value: mentorController.rxProfile.value.data?.rating?.toStringAsFixed(1) ?? '--'),
                      ],
                    );
                  }),
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
                              Obx(() {
                                final earningsState = mentorController.rxEarnings.value;
                                final total = earningsState.data?.totalEarnings;
                                final label = total != null ? '\$${total.toStringAsFixed(2)}' : '--';
                                return Text(
                                  label,
                                  style: GoogleFonts.dmSans(
                                    color: AppColor.white,
                                    fontSize: Responsive.sp(18),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                );
                              }),
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
                              Flexible(
                                child: Text(
                                  'Stand out with a Verified Badge',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: Responsive.sp(14),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ),
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
                  Obx(() {
                    final sessionsState = mentorController.rxSessions.value;
                    final upcoming = (sessionsState.data?.sessions ?? [])
                        .where((s) => s.status == 'scheduled')
                        .toList();
                    if (upcoming.isEmpty) return const SizedBox.shrink();
                    return test(context, sessionId: upcoming.first.sessionId ?? '');
                  }),
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

                  Obx(() {
                    final sessionsState = mentorController.rxSessions.value;
                    final sessions = sessionsState.data?.sessions ?? [];
                    if (sessions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            sessionsState.data == null ? 'Loading sessions...' : 'No session history yet',
                            style: GoogleFonts.dmSans(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, index) => recentSessionsHistoryCard(ctx, session: sessions[index]),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget test(BuildContext context, {String sessionId = ''}) {
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
                    backgroundImage: const AssetImage("assets/icons/Ellipse 6.png"),
                  ),
                  SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student",
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
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Type",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Group",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColor.white),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Duration",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "1hr",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColor.white),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Seats Left",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "2-5",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColor.white),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Language",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "English / Arabic",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 12,
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(children: [Expanded(child: Divider(thickness: 1))]),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.toNamed(
                    RoutesName.liveSession,
                    arguments: {'sessionId': sessionId, 'isMentor': true},
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
}

Widget recentSessionsHistoryCard(BuildContext context, {SessionModel? session}) {
  final studentLabel = session?.studentId ?? 'Student';
  final dateLabel = session?.dateTime ?? '--';
  final durationLabel = session?.duration != null ? '${session!.duration}min' : '1hr';
  final statusLabel = session?.status ?? '--';
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
                            studentLabel,
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
                      statusLabel,
                      style: GoogleFonts.rethinkSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 14,
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
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateLabel,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Duration",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        durationLabel,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seats Left",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "2-5",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColor.white),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Language",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "English / Arabic",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


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
