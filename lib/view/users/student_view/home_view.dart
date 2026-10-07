import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/student_stats.dart';
import 'package:toriino_todd/view/subscriptions/plans_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_public_profile.dart';
import 'package:toriino_todd/view/users/student_view/availability_view.dart';
import 'package:toriino_todd/view/users/student_view/browsetecaher.dart';
import 'package:toriino_todd/view/users/student_view/course_view.dart';
import 'package:toriino_todd/view/users/student_view/my_taken_cousre_view.dart';
import 'package:toriino_todd/view/users/student_view/mycourse_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/view/users/student_view/student_private_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/teacher_profile.dart';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';
import 'package:toriino_todd/viewmodel/controller/student/home_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/subscription/subscription_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/widgets/components/custom_recent_quiz.dart';
import 'package:toriino_todd/widgets/custom_button.dart';
import 'package:toriino_todd/widgets/custom_ongoing_widget_card.dart';
import 'package:toriino_todd/widgets/custom_recommended_mentors.dart';
import 'package:toriino_todd/widgets/custom_recommended_teacher.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  UsersPrefrence usersPrefrence = UsersPrefrence();
  final HomeViewmodel homeController = Get.put(HomeViewmodel());
  final SubscriptionViewModel subscriptionVm =
      Get.isRegistered<SubscriptionViewModel>()
          ? Get.find<SubscriptionViewModel>()
          : Get.put(SubscriptionViewModel());

  @override
  void initState() {
    super.initState();
    // Premium state comes only from GET /subscriptions/me.
    subscriptionVm.fetchMe();
  }

  void _openPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlansView()),
    ).then((_) => subscriptionVm.fetchMe(silent: true));
  }

  static String? _firstNonEmpty(List<String>? values) {
    for (final v in values ?? const <String>[]) {
      if (v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String? _hourly(MentorModel m) =>
      m.hourlyRate == null ? null : '${formatMoney(m.hourlyRate!)}/hr';

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: Padding(
            padding: Responsive.padding(left: 2, right: 2, bottom: 1, top: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentProfile(),
                                ),
                              );
                            },
                            child: Obx(() {
                              final avatarUrl = homeController.rxProfile.value.data?.avatarUrl;
                              final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                              return CircleAvatar(
                                backgroundColor: AppColor.white.withValues(alpha: 0.15),
                                foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                onForegroundImageError: hasAvatar ? (_, __) {} : null,
                                child: Icon(Icons.person, color: AppColor.white),
                              );
                            }),
                          ),
                          SizedBox(width: 10.w),
                          Flexible(
                            child: Obx(() {
                              final profile = homeController.rxProfile.value;
                              final name = (profile.data?.name ?? '').trim();
                              final userId = (profile.data?.userId ?? '').trim();
                              final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty ? "Hi $name" : "Hi",
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      color: AppColor.secconderyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.sp(10),
                                    ),
                                  ),
                                  if (shortId.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => Clipboard.setData(ClipboardData(text: userId)),
                                      child: Row(
                                        spacing: Responsive.w(1),
                                        children: [
                                          Text(
                                            "ID: $shortId",
                                            style: GoogleFonts.dmSans(
                                              color: AppColor.secconderyColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: Responsive.sp(10),
                                            ),
                                          ),
                                          SvgPicture.asset('assets/icons/copy.svg'),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                          SizedBox(width: 8.w),
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
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: Responsive.padding(
                            left: 2,
                            right: 2,
                            bottom: 2,
                            top: 2,
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/notification.svg',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(2)),
                    Semantics(
                      label: 'Open menu',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          return customDrawerController.toggleDrawer();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.backGroundColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              bottom: 2,
                              top: 2,
                            ),
                            child: SvgPicture.asset('assets/icons/menu.svg'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Real stats: my-courses enrollment status + non-cancelled
                // sessions. A box is hidden when its data failed to load.
                Obx(() {
                  final myCourses = homeController.rxMyCourses.value;
                  final sessions = homeController.rxSessions.value;
                  final courses = myCourses.status == Status.success
                      ? myCourses.data?.courses
                      : null;
                  final sessionList = sessions.status == Status.success
                      ? sessions.data?.sessions
                      : null;
                  final boxes = <Widget>[
                    if (courses != null)
                      _statBox(
                        'Courses in\nProgress',
                        StudentStats.coursesInProgress(courses),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MycourseView()),
                        ),
                      ),
                    if (sessionList != null)
                      _statBox(
                        'Sessions\nBooked',
                        StudentStats.sessionsBooked(sessionList),
                        onTap: () => customDrawerController.changeIndex(1),
                      ),
                    if (courses != null)
                      _statBox(
                        'Courses\nCompleted',
                        StudentStats.coursesCompleted(courses),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MycourseView()),
                        ),
                      ),
                  ];
                  if (boxes.isEmpty) return const SizedBox.shrink();
                  return Row(spacing: Responsive.w(2), children: boxes);
                }),
                SizedBox(height: Responsive.h(1)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: AppColor.white.withValues(alpha: 0.1),
                  ),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ask the AI Tutor 24/7",
                            style: GoogleFonts.dmSans(
                              color: AppColor.secconderyColor,
                              fontSize: Responsive.sp(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Get instant academic help, practice quizzes,\nexplanations powered by AI.",
                            style: GoogleFonts.dmSans(
                              color: AppColor.secconderyColor,
                              fontSize: Responsive.sp(12),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Obx(() {
                            final me = subscriptionVm.rxMe.value.data;
                            final premium = me?.premium == true;
                            return CustomButton(
                              key: const Key('home_premium_button'),
                              width: 191.w,
                              backgroundColor: premium
                                  ? AppColor.white.withValues(alpha: 0.2)
                                  : AppColor.red,
                              textColor: AppColor.secconderyColor,
                              text: premium
                                  ? 'Premium active'
                                  : 'Upgrade to Premium',
                              onTap: _openPlans,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(1)),

                // Ongoing course: the student's first not-completed enrollment.
                Obx(() {
                  final state = homeController.rxMyCourses.value;
                  final ongoing = (state.data?.courses ?? [])
                      .where((c) => !c.isCompleted)
                      .toList();
                  if (state.status != Status.success || ongoing.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final course = ongoing.first;
                  return Padding(
                    padding: EdgeInsets.only(bottom: Responsive.h(1)),
                    child: OngoingCourseCard(
                      headerText: 'Ongoing Course',
                      courseTitle: (course.title ?? '').trim().isNotEmpty
                          ? course.title!.trim()
                          : 'Course',
                      duration: course.duration,
                      mentorName: course.teacherName,
                      rating: course.rating,
                      progress: course.enrollmentProgress,
                      continuetocousre: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MyTakenCousreView(course: course)),
                        );
                      },
                    ),
                  );
                }),

                // Recommended mentor: real data of the first mentor.
                Obx(() {
                  final mentorsResponse = homeController.rxMentors.value;
                  final mentors = mentorsResponse.status == Status.success
                      ? (mentorsResponse.data?.mentors ?? const <MentorModel>[])
                      : const <MentorModel>[];
                  if (mentors.isEmpty) return const SizedBox.shrink();
                  final mentor = mentors.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        'Recommended Mentors',
                        onViewAll: () => customDrawerController.changeIndex(2),
                      ),
                      CustomRecommendedMentors(
                        avatarUrl: mentor.avatarUrl,
                        name: (mentor.name ?? '').trim().isNotEmpty
                            ? mentor.name!.trim()
                            : 'Mentor',
                        role: _firstNonEmpty(mentor.expertise),
                        rating: mentor.rating,
                        description: mentor.bio,
                        languages: mentor.language,
                        pricePerHour: _hourly(mentor),
                        onViewProfileTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MentorPublicProfile(mentor: mentor)));
                        },
                        onBookSessionTap: (mentor.userId ?? '').isEmpty
                            ? null
                            : () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AvailabilityView(
                                  mentorId: mentor.userId!,
                                  mentorName: mentor.name ?? '',
                                )));
                              },
                      ),
                      SizedBox(height: Responsive.h(1)),
                    ],
                  );
                }),

                // Recommended teacher: real data of the next listed mentor;
                // hidden when there is none.
                Obx(() {
                  final mentorsResponse = homeController.rxMentors.value;
                  final mentors = mentorsResponse.status == Status.success
                      ? (mentorsResponse.data?.mentors ?? const <MentorModel>[])
                      : const <MentorModel>[];
                  if (mentors.length < 2) return const SizedBox.shrink();
                  final teacher = mentors[1];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        'Recommended Teachers',
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BrowseTecher()),
                        ),
                      ),
                      CustomRecommendedTeacher(
                        avatarUrl: teacher.avatarUrl,
                        name: (teacher.name ?? '').trim().isNotEmpty
                            ? teacher.name!.trim()
                            : 'Teacher',
                        role: _firstNonEmpty(teacher.expertise),
                        rating: teacher.rating,
                        description: teacher.bio,
                        languages: teacher.language,
                        pricePerHour: _hourly(teacher),
                        onViewProfileTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfile(teacherId: teacher.userId ?? '')));
                        },
                      ),
                    ],
                  );
                }),

                // Upcoming sessions from GET /sessions?role=student.
                Obx(() {
                  final state = homeController.rxSessions.value;
                  if (state.status != Status.success) {
                    return const SizedBox.shrink();
                  }
                  final upcoming =
                      StudentStats.upcoming(state.data?.sessions ?? const []);
                  if (upcoming.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        'Upcoming Session',
                        large: true,
                        onViewAll: () => customDrawerController.changeIndex(3),
                      ),
                      for (final s in upcoming.take(2))
                        CustomRecentQuizCard(
                          title: _sessionTitle(s),
                          subtitle: DateFormat('EEE, d MMM • h:mm a')
                              .format(DateTime.parse(s.dateTime!).toLocal()),
                          icon: 'assets/icons/alarm.svg',
                          iconBackgroundColor: AppColor.backGroundColor,
                          arrowColor: AppColor.secconderyColor,
                          firstIconBgColor: AppColor.backGroundColor,
                          onTap: () => customDrawerController.changeIndex(3),
                        ),
                    ],
                  );
                }),

                Obx(() {
                  final coursesResponse = homeController.rxCourses.value;
                  if (coursesResponse.status == Status.success && coursesResponse.data != null && coursesResponse.data!.courses.isNotEmpty) {
                    final course = coursesResponse.data!.courses[0];
                    final price = course.displayPrice;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Popular Courses',
                          large: true,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CourseView()),
                          ),
                        ),
                        SizedBox(height: Responsive.h(1)),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: AppColor.white.withValues(alpha: 0.1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                            child: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (price != null)
                                      Row(children: [
                                        SvgPicture.asset("assets/icons/money-03 (1).svg"),
                                        Text(
                                          price <= 0 ? "FREE" : formatMoney(price, course.pricing?.currency),
                                          style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor),
                                        ),
                                      ])
                                    else
                                      const SizedBox.shrink(),
                                    CustomButton(backgroundColor: AppColor.red, width: Responsive.w(30), text: "Enroll", onTap: () { showCourseEnrollSheet(context, course); }),
                                  ],
                                ),
                                if ((course.duration ?? '').isNotEmpty)
                                  Text("Duration: ${course.duration}", style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                if ((course.title ?? '').trim().isNotEmpty)
                                  Text(course.title!.trim(), style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 22, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(children: [
                                        if ((course.teacherName ?? '').isNotEmpty) ...[
                                          CircleAvatar(radius: 16, backgroundColor: AppColor.red, child: Icon(Icons.person, color: AppColor.white, size: 18)),
                                          SizedBox(width: 10.w),
                                        ],
                                        Flexible(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            if ((course.teacherName ?? '').isNotEmpty)
                                              Text(course.teacherName!, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                            if ((course.category ?? '').isNotEmpty)
                                              Text(course.category!, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                            if ((course.level ?? '').isNotEmpty)
                                              Text(course.level!, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                          ]),
                                        ),
                                      ]),
                                    ),
                                    if ((course.rating ?? 0) > 0)
                                      Row(children: [
                                        Icon(Icons.star, color: AppColor.white, size: Responsive.textScaleFactor * 16),
                                        SizedBox(width: 4.w),
                                        Text(course.rating!.toStringAsFixed(1), style: GoogleFonts.dmSans(color: AppColor.white, fontSize: Responsive.textScaleFactor * 16)),
                                      ]),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _sessionTitle(SessionModel s) {
    final topic = (s.topic ?? '').trim();
    final mentor = (s.mentorName ?? '').trim();
    final base = topic.isNotEmpty
        ? topic
        : (s.isGroup ? 'Group session' : '1-on-1 session');
    return mentor.isNotEmpty ? '$base with $mentor' : base;
  }

  Widget _statBox(String title, int value, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColor.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Padding(
            padding: Responsive.padding(left: 2, right: 2, top: 1, bottom: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.sp(10))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(value.toString().padLeft(2, '0'), style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.textScaleFactor * 20)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {required VoidCallback onViewAll, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: AppColor.white,
            fontSize: large ? Responsive.textScaleFactor * 19 : Responsive.sp(14),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: [
              Text(
                "View All",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: AppColor.white,
                  fontSize: Responsive.sp(10),
                ),
              ),
              SvgPicture.asset("assets/icons/eva_arrow-up-fill.svg"),
            ],
          ),
        ),
      ],
    );
  }
}
