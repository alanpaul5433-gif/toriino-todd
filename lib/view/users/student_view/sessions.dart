import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/getx_controllers/advanceddrawercontroller.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/student_view/notification_view.dart';
import 'package:getxmvvm/viewmodel/controller/student/session_viewmodel.dart';
import 'package:getxmvvm/data/response/status.dart';
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
                                        backgroundImage: AssetImage(
                                          "assets/icons/Ellipse 6.png",
                                        ),
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
                                        "Group",
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
                                        "2-5",
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
                                        "English / Arabic",
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
                                      // onTap:
                                      // () => Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder:
                                      //         (_) => AvailabilityScreen(),
                                      //   ),
                                      // ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          color: AppColor.red,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Reschedule",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: Responsive.sp(12),
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
