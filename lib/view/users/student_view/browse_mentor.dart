import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_public_profile.dart';
import 'package:toriino_todd/view/users/student_view/availability_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/viewmodel/controller/student/mentor_list_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseMentor extends StatelessWidget {
  BrowseMentor({super.key});

  final MentorListViewmodel mentorController = Get.put(MentorListViewmodel());

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
                        Column(
                          children: [
                            Text(
                              "Browse Mentor",
                              style: TextStyle(
                                color: AppColor.secconderyColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
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
              SizedBox(height: Responsive.h(1)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "Search by name, topic, or skill",
                        hintStyle: TextStyle(
                          color: AppColor.secconderyColor,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColor.secconderyColor,
                        ),
                        filled: true,
                        fillColor: AppColor.backGroundColor.withValues(
                          alpha: 0.1,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              Flexible(
                child: Obx(() {
                  final response = mentorController.rxMentors.value;
                  if (response.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (response.status == Status.error) {
                    return Center(child: Text('Error loading mentors', style: TextStyle(color: AppColor.white)));
                  }
                  final mentors = response.data?.mentors ?? [];
                  return ListView.builder(
                  itemCount: mentors.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColor.white.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              _MentorHeader(mentor: mentors[index]),
                              if ((mentors[index].bio ?? '').trim().isNotEmpty) ...[
                                SizedBox(height: 10),
                                Text(
                                  mentors[index].bio!.trim(),
                                  style: GoogleFonts.dmSans(
                                    color: AppColor.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: Responsive.sp(10),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if ((mentors[index].language ?? '').trim().isNotEmpty ||
                                  mentors[index].hourlyRate != null) ...[
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if ((mentors[index].language ?? '').trim().isNotEmpty)
                                      Flexible(
                                        child: Row(
                                          children: [
                                            SvgPicture.asset("assets/icons/mic.svg"),
                                            Flexible(
                                              child: Text(
                                                mentors[index].language!.trim(),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Responsive.textScaleFactor * 10,
                                                  fontFamily: 'DM Sans',
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    if (mentors[index].hourlyRate != null)
                                      Text(
                                        '${formatMoney(mentors[index].hourlyRate!)}/hr',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 12,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.20,
                                        ),
                                      ),
                                  ],
                                ),
                              ],

                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MentorPublicProfile(
                                                mentor: mentors[index],
                                              ),
                                            ),
                                          ),
                                      child: Container(
                                        width: double.infinity,
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
                                            spacing: 2,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "View Profile",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: Responsive.sp(10),
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
                                  SizedBox(width: Responsive.w(4)),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AvailabilityView(
                                                mentorId: mentors[index].userId ?? '',
                                                mentorName: mentors[index].name ?? '',
                                              ),
                                            ),
                                          ),

                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          color: AppColor.white.withValues(
                                            alpha: 0.08,
                                          ),
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
                                                "Book Session",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: Responsive.sp(10),
                                                  color: AppColor.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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

/// Avatar (network image or a neutral icon), rating, name and first expertise
/// — each shown only when the server sent it.
class _MentorHeader extends StatelessWidget {
  final MentorModel mentor;
  const _MentorHeader({required this.mentor});

  @override
  Widget build(BuildContext context) {
    final avatar = (mentor.avatarUrl ?? '').trim();
    final name = (mentor.name ?? '').trim();
    final expertise = (mentor.expertise ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final style = GoogleFonts.dmSans(
      color: AppColor.white,
      fontWeight: FontWeight.w500,
      fontSize: Responsive.sp(12),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: AppColor.white.withValues(alpha: 0.15),
          foregroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          onForegroundImageError: avatar.isNotEmpty ? (_, __) {} : null,
          child: Icon(Icons.person, color: AppColor.white, size: 32),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              if (mentor.rating != null)
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/material-symbols_star (1).svg",
                    ),
                    Text(mentor.rating!.toStringAsFixed(1), style: style),
                  ],
                ),
              if (name.isNotEmpty)
                Text(name, overflow: TextOverflow.ellipsis, style: style),
              if (expertise.isNotEmpty)
                Text(expertise.first,
                    overflow: TextOverflow.ellipsis, style: style),
            ],
          ),
        ),
      ],
    );
  }
}
