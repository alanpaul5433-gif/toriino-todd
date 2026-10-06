import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/view/users/student_view/teacher_profile.dart';
import 'package:toriino_todd/viewmodel/controller/student/mentor_list_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseTecher extends StatelessWidget {
  const BrowseTecher({super.key});

  @override
  Widget build(BuildContext context) {
    final MentorListViewmodel vm = Get.put(MentorListViewmodel());
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                        ),
                        Text(
                          "Browse Teacher",
                          style: TextStyle(
                            color: AppColor.secconderyColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.backGroundColor.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/notification.svg'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.backGroundColor.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/menu.svg'),
                    ),
                  ),
                ],
              ),
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
                        fillColor: AppColor.backGroundColor.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/icons/filter.svg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Obx(() {
                  final state = vm.rxMentors.value;
                  if (state.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (state.status == Status.error) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          const Text('Could not load teachers', style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: vm.fetchMentors,
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }
                  final mentors = state.data?.mentors ?? [];
                  if (mentors.isEmpty) {
                    return const Center(
                      child: Text('No teachers found', style: TextStyle(color: Colors.white70)),
                    );
                  }
                  return ListView.builder(
                    itemCount: mentors.length,
                    itemBuilder: (context, index) => _MentorCard(mentor: mentors[index]),
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

class _MentorCard extends StatelessWidget {
  final MentorModel mentor;
  const _MentorCard({required this.mentor});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mentor.avatarUrl != null
                      ? CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(mentor.avatarUrl!),
                        )
                      : CircleAvatar(
                          radius: 35,
                          backgroundImage: const AssetImage("assets/icons/Frame 1171275882.png"),
                        ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mentor.rating != null)
                        Row(
                          children: [
                            SvgPicture.asset("assets/icons/material-symbols_star (1).svg"),
                            Text(
                              mentor.rating!.toStringAsFixed(1),
                              style: GoogleFonts.dmSans(
                                color: AppColor.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Text(
                        mentor.name ?? 'Mentor',
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        (mentor.expertise?.isNotEmpty == true)
                            ? '${mentor.expertise!.first} Mentor'
                            : 'Mentor',
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SvgPicture.asset("assets/icons/bitcoin-icons_verify-filled.svg"),
                ],
              ),
              const SizedBox(height: 10),
              if (mentor.bio != null)
                Text(
                  mentor.bio!,
                  style: GoogleFonts.dmSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              if (mentor.expertise != null && mentor.expertise!.isNotEmpty)
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: mentor.expertise!.take(3).map((tag) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColor.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                      child: Text(
                        tag,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColor.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sessions",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColor.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    mentor.totalSessions?.toString() ?? '--',
                    style: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeacherProfile()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppColor.red,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      spacing: 2,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "View Profile",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColor.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SvgPicture.asset("assets/icons/arrow.svg"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
