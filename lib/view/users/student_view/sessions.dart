import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/live_session/live_session_screen.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/view/users/student_view/review.dart';
import 'package:toriino_todd/viewmodel/controller/student/session_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionsView extends StatelessWidget {
  SessionsView({super.key});

  final SessionViewmodel sessionController = Get.put(SessionViewmodel());

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // GestureDetector(
                        //   onTap: () => Navigator.pop(context),
                        //   child: SvgPicture.asset(
                        //     width: Responsive.w(6),
                        //     height: Responsive.w(6),
                        //     "assets/icons/Arrow - Right 3.svg",
                        //   ),
                        // ),
                        Text(
                          "Sessions",
                          style: TextStyle(
                            color: AppColor.secconderyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.textScaleFactor * 20,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/icons/notification.svg',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () {
                      return customDrawerController.toggleDrawer();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/icons/menu.svg'),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              Flexible(
                child: Obx(() {
                  final response = sessionController.rxSessions.value;
                  if (response.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (response.status == Status.error) {
                    return Center(child: Text('Error loading sessions', style: TextStyle(color: AppColor.white)));
                  }
                  final sessions = response.data?.sessions ?? [];
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note_outlined, color: Colors.white38, size: 56),
                          SizedBox(height: 16),
                          Text(
                            'No sessions yet.',
                            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Book a session with a mentor to get started.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: AppColor.white.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColor.red.withValues(alpha: 0.3),
                                        child: Icon(Icons.person, color: AppColor.white),
                                      ),
                                      SizedBox(width: 10),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sessions[index].topic ?? 'Session',
                                            style: GoogleFonts.dmSans(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            sessions[index].status ?? 'scheduled',
                                            style: GoogleFonts.dmSans(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColor.white.withValues(alpha: 0.12),
                                    ),
                                    child: Text(
                                      sessions[index].status ?? 'scheduled',
                                      style: GoogleFonts.dmSans(
                                        color: AppColor.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
                                sessions[index].dateTime ?? '',
                                style: GoogleFonts.dmSans(
                                  fontSize: Responsive.sp(16),
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                spacing: 4,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Type",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12.sp,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        sessions[index].topic ?? '--',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12.sp,
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
                                          fontSize: 12.sp,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${sessions[index].duration ?? 60} min",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12.sp,
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
                                          fontSize: 12.sp,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '--',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12.sp,
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
                                          fontSize: 12.sp,
                                          color: AppColor.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '--',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12.sp,
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
                                spacing: 4,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: (sessions[index].status == 'scheduled' || sessions[index].status == 'active')
                                          ? () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => LiveSessionScreen(
                                                    sessionId: sessions[index].sessionId ?? '',
                                                    isMentor: false,
                                                  ),
                                                ),
                                              )
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(28),
                                          color: (sessions[index].status == 'scheduled' || sessions[index].status == 'active')
                                              ? AppColor.red
                                              : AppColor.white.withValues(alpha: 0.2),
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
                                                (sessions[index].status == 'scheduled' || sessions[index].status == 'active')
                                                    ? "Join Session"
                                                    : "Completed",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: Responsive.sp(12),
                                                  color: AppColor.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (sessions[index].status == 'scheduled' || sessions[index].status == 'active')
                                                SvgPicture.asset("assets/icons/arrow.svg"),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // assets/icons/bubble-chat.svg
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
                              // Rate Session button — only for completed sessions
                              if (sessions[index].status == 'completed') ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => showSubmitReviewSheet(
                                    context,
                                    targetId: sessions[index].sessionId ?? sessions[index].mentorId ?? '',
                                    targetType: 'mentor',
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: AppColor.red.withValues(alpha: 0.6),
                                      ),
                                      color: AppColor.red.withValues(alpha: 0.12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 16.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.star_border, color: AppColor.red, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Rate Session",
                                            style: GoogleFonts.dmSans(
                                              fontSize: Responsive.sp(12),
                                              color: AppColor.red,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
