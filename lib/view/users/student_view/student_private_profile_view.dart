import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/student_stats.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/edit_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/my_taken_cousre_view.dart';
import 'package:toriino_todd/view/users/student_view/review.dart';
import 'package:toriino_todd/viewmodel/controller/student/profile_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final ProfileViewmodel profileVm = Get.put(ProfileViewmodel());
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/icons/Arrow - Right 3 (1).svg",
                                ),
                                SizedBox(width: Responsive.w(2)),
                                Text(
                                  'Your Profile',
                                  style: GoogleFonts.rethinkSans(
                                    color: AppColor.white,
                                    fontSize: Responsive.textScaleFactor * 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                              ],
                            ),
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
                              'assets/icons/notification.svg',
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(2)),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     color: AppColor.backGroundColor.withValues(
                        //       alpha: 0.1,
                        //     ),
                        //   ),
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(8.0),
                        //     child: SvgPicture.asset('assets/icons/menu.svg'),
                        //   ),
                        // ),
                      ],
                    ),
                    //Profile Pic Name Domain and Share Icon
                    SizedBox(height: Responsive.h(2)),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() {
                              final avatarUrl = profileVm.rxProfile.value.data?.avatarUrl;
                              final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                              return CircleAvatar(
                                radius: Responsive.w(10),
                                backgroundColor: AppColor.white.withValues(alpha: 0.15),
                                foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                onForegroundImageError: hasAvatar ? (_, __) {} : null,
                                child: Icon(Icons.person, color: AppColor.white, size: Responsive.w(10)),
                              );
                            }),
                            SizedBox(width: Responsive.w(2)),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Obx(() {
                                  final profile = profileVm.rxProfile.value.data;
                                  return Text(
                                    profile?.name ?? '',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 18,
                                      fontWeight: FontWeight.w600,
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
                    Obx(() {
                      final edu = (profileVm.rxProfile.value.data?.educationLevel ?? '').trim();
                      if (edu.isEmpty) return const SizedBox.shrink();
                      final style = GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Education Level', style: style),
                          Flexible(
                            child: Text(edu,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: style),
                          ),
                        ],
                      );
                    }),
                    SizedBox(height: Responsive.h(2)),

                    Obx(() {
                      final profile = profileVm.rxProfile.value.data;
                      final bio = profile?.bio ?? '';
                      if (bio.isEmpty) return const SizedBox.shrink();
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
                    Obx(() {
                      final lang = (profileVm.rxProfile.value.data?.language ?? '').trim();
                      if (lang.isEmpty) return const SizedBox.shrink();
                      return Row(
                        children: [
                          SvgPicture.asset("assets/icons/mic.svg"),
                          Flexible(
                            child: Text(
                              lang,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.20,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    SizedBox(height: Responsive.h(2)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentEditProfileView(),
                          ),
                        );
                      },

                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColor.white),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Edit Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.h(2)),
                    //Divider
                    const Row(children: [Expanded(child: Divider())]),
                    SizedBox(height: Responsive.h(2)),
                    const _StudentStatsRow(),
                    SizedBox(height: Responsive.h(2)),


                    //review and view all
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final uid = profileVm.rxProfile.value.data?.userId ?? '';
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ReviewView(
                                targetId: uid,
                                targetType: 'student',
                              )),
                            );
                          },
                          child: Text(
                            'View all',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 10,
                              fontWeight: FontWeight.w400,
                              height: 1.60,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),

                    SizedBox(height: Responsive.h(2)),
                    Text(
                      'My Enrolled Courses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: Responsive.h(2)),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: _EnrolledCoursesSection()),
          ],
        ),
      ),
    );
  }
}

/// The signed-in student's real enrollments (GET /courses/my-courses).
/// Tapping a course opens its lessons in [MyTakenCousreView].
class _EnrolledCoursesSection extends StatefulWidget {
  const _EnrolledCoursesSection();

  @override
  State<_EnrolledCoursesSection> createState() =>
      _EnrolledCoursesSectionState();
}

class _EnrolledCoursesSectionState extends State<_EnrolledCoursesSection> {
  late Future<List<CourseModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = CourseRepo().getMyEnrolledCourses().then(
          (value) => CourseListResponse.fromJson(
                  value is Map<String, dynamic> ? value : <String, dynamic>{})
              .courses,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  Utils.errorMessage(snapshot.error),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('Retry',
                      style: TextStyle(color: AppColor.red)),
                ),
              ],
            ),
          );
        }
        final courses = snapshot.data ?? const <CourseModel>[];
        if (courses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No enrolled courses yet',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }
        return Column(
          children: [
            for (final course in courses)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _card(context, course),
              ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, CourseModel course) {
    final title = (course.title ?? '').trim();
    final teacher = (course.teacherName ?? '').trim();
    final rating = course.rating ?? 0;
    final completed = course.isCompleted;
    final hasStatus = (course.enrollmentStatus ?? '').isNotEmpty;
    final progress =
        completed ? 100 : course.enrollmentProgress?.clamp(0, 100);
    final canOpen = (course.courseId ?? '').isNotEmpty;

    return GestureDetector(
      onTap: canOpen
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyTakenCousreView(course: course),
                ),
              );
              // The course may have been marked completed meanwhile.
              if (mounted) setState(_load);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : 'Untitled course',
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 18,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (rating > 0) ...[
                    SvgPicture.asset(
                      "assets/icons/material-symbols_star (1).svg",
                    ),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasStatus) ...[
                const SizedBox(height: 6),
                Text(
                  completed ? 'Completed' : 'In progress',
                  style: GoogleFonts.dmSans(
                    fontSize: Responsive.textScaleFactor * 12,
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (teacher.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColor.secconderyColor,
                            child: Icon(Icons.person, color: AppColor.white),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              teacher,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: AppColor.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  if (canOpen)
                    Container(
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
                          children: [
                            Text(
                              completed ? "Review" : "Continue",
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
                ],
              ),
              if (progress != null) ...[
                SizedBox(height: Responsive.h(2)),
                LinearProgressIndicator(
                  backgroundColor: AppColor.white.withValues(alpha: 0.23),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.white),
                  value: progress / 100,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Completion",
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColor.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      "$progress %",
                      style: GoogleFonts.dmSans(
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Real stat boxes: courses in progress / completed (GET /courses/my-courses,
/// `enrollment.status`) and sessions booked (GET /sessions?role=student,
/// excluding cancelled). A box is hidden when its data failed to load.
class _StudentStatsRow extends StatefulWidget {
  const _StudentStatsRow();

  @override
  State<_StudentStatsRow> createState() => _StudentStatsRowState();
}

class _StudentStatsRowState extends State<_StudentStatsRow> {
  List<CourseModel>? _courses;
  List<SessionModel>? _sessions;

  @override
  void initState() {
    super.initState();
    CourseRepo().getMyEnrolledCourses().then((value) {
      final list = CourseListResponse.fromJson(
              value is Map<String, dynamic> ? value : <String, dynamic>{})
          .courses;
      if (mounted) setState(() => _courses = list);
    }).catchError((_) {});
    SessionRepo().getSessions(role: 'student').then((value) {
      final list = SessionListResponse.fromJson(
              value is Map<String, dynamic> ? value : <String, dynamic>{})
          .sessions;
      if (mounted) setState(() => _sessions = list);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    final sessions = _sessions;
    final boxes = <Widget>[
      if (courses != null)
        _box('Courses in Progress', StudentStats.coursesInProgress(courses)),
      if (sessions != null)
        _box('Sessions Booked', StudentStats.sessionsBooked(sessions)),
      if (courses != null)
        _box('Courses Completed', StudentStats.coursesCompleted(courses)),
    ];
    if (boxes.isEmpty) return const SizedBox.shrink();
    return Row(spacing: 5, children: boxes);
  }

  Widget _box(String title, int value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 16,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.20,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 25,
                      fontFamily: 'Rethink Sans',
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
    );
  }
}
