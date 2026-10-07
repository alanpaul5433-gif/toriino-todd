import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/student_stats.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_private_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_home_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/widgets/session_student_card.dart';

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
                                final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                                return CircleAvatar(
                                  radius: Responsive.sp(20),
                                  backgroundColor: AppColor.white.withValues(alpha: 0.15),
                                  foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                  onForegroundImageError: hasAvatar ? (_, __) {} : null,
                                  child: Icon(Icons.person, color: AppColor.white),
                                );
                              }),
                              SizedBox(width: Responsive.wp(1)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(() {
                                    final profile = mentorController.rxProfile.value;
                                    final name = (profile.data?.name ?? '').trim();
                                    return Text(
                                    name.isNotEmpty ? 'Hi $name' : 'Hi',
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

                  // Real stats: GET /sessions?role=mentor and the profile
                  // rating. A box is hidden when its data is unavailable.
                  Obx(() {
                    final sessionsState = mentorController.rxSessions.value;
                    final sessions = sessionsState.status == Status.success
                        ? sessionsState.data?.sessions
                        : null;
                    final rating = mentorController.rxProfile.value.data?.rating;
                    final boxes = <Widget>[
                      if (sessions != null) ...[
                        bloc(title: "Total Sessions", value: StudentStats.sessionsBooked(sessions).toString()),
                        bloc(title: "Upcoming Sessions", value: StudentStats.upcoming(sessions).length.toString()),
                      ],
                      if (rating != null)
                        bloc(title: "Average Rating", value: rating.toStringAsFixed(1)),
                    ];
                    if (boxes.isEmpty) return const SizedBox.shrink();
                    return Row(spacing: 6, children: boxes);
                  }),
                  SizedBox(height: Responsive.hp(2)),

                  // Earnings exactly as GET /earnings returned them.
                  Obx(() {
                    final earningsState = mentorController.rxEarnings.value;
                    final e = earningsState.status == Status.success
                        ? earningsState.data
                        : null;
                    if (e == null) return const SizedBox.shrink();
                    final cells = <Widget>[
                      _earningsCell('Total Earnings', formatMoney(e.totalEarnings)),
                      if (e.availableBalance != null)
                        _earningsCell('Available Balance', formatMoney(e.availableBalance!)),
                    ];
                    return Container(
                      width: double.infinity,
                      padding: Responsive.padding(left: 2, right: 2, top: 1.5, bottom: 1.5),
                      decoration: BoxDecoration(
                        color: AppColor.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: cells),
                    );
                  }),
                  SizedBox(height: Responsive.hp(2)),

                  // "Verified Badge" promo removed: there is no verification feature.

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
                    final upcoming =
                        StudentStats.upcoming(sessionsState.data?.sessions ?? const []);
                    if (upcoming.isEmpty) return const SizedBox.shrink();
                    final next = upcoming.first;
                    final nextId = next.sessionId ?? '';
                    return SessionStudentCard(
                      session: next,
                      onStart: nextId.isEmpty
                          ? null
                          : () => Get.toNamed(
                                RoutesName.liveSession,
                                arguments: {'sessionId': nextId, 'isMentor': true},
                              ),
                    );
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
                    if (sessionsState.status == Status.loading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (sessionsState.status == Status.error) {
                      return const SizedBox.shrink();
                    }
                    if (sessions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No session history yet',
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

Widget _earningsCell(String label, String value) {
  return Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColor.white,
            fontSize: Responsive.sp(10),
            fontWeight: FontWeight.w400,
            letterSpacing: -0.20,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              color: AppColor.white,
              fontSize: Responsive.sp(18),
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget recentSessionsHistoryCard(BuildContext context, {SessionModel? session}) {
  if (session == null) return const SizedBox.shrink();
  return SessionStudentCard(session: session);
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
