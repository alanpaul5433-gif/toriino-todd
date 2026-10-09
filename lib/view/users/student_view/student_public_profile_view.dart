import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/model/user/public_user_model.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/my_taken_cousre_view.dart';

/// Student profile, built only from real API data.
///
/// * Without [studentId]: the signed-in student's own profile
///   (GET /users/profile, GET /courses/my-courses, GET /sessions?role=student).
/// * With [studentId]: what a teacher/mentor may see about that student via
///   GET /users/{studentId} - name, avatar, bio and only the courses/sessions
///   they share. A 403 is shown as a clear "not allowed" message.
///
/// Empty fields are hidden rather than shown as placeholders.
class StudentPublicProfileView extends StatefulWidget {
  final String? studentId;
  const StudentPublicProfileView({super.key, this.studentId});

  @override
  State<StudentPublicProfileView> createState() =>
      _StudentPublicProfileViewState();
}

class _StudentPublicProfileViewState extends State<StudentPublicProfileView> {
  late Future<UserProfileModel> _profileFuture;
  late Future<List<CourseModel>> _coursesFuture;
  late Future<List<SessionModel>> _sessionsFuture;
  late Future<List<dynamic>> _statsFuture;
  late Future<PublicUserModel> _studentFuture;

  String? get _studentId {
    final id = (widget.studentId ?? '').trim();
    return id.isEmpty ? null : id;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final studentId = _studentId;
    if (studentId != null) {
      _studentFuture = UserRepo()
          .getUserById(studentId)
          .then(
            (value) => PublicUserModel.fromJson(
              value is Map<String, dynamic> ? value : <String, dynamic>{},
            ),
          );
      return;
    }
    _profileFuture = UserRepo().getProfile().then(
      (value) => UserProfileModel.fromJson(
        value is Map<String, dynamic> ? value : <String, dynamic>{},
      ),
    );
    _coursesFuture = CourseRepo().getMyEnrolledCourses().then(
      (value) =>
          CourseListResponse.fromJson(
            value is Map<String, dynamic> ? value : <String, dynamic>{},
          ).courses,
    );
    _sessionsFuture = SessionRepo()
        .getSessions(role: 'student')
        .then(
          (value) =>
              SessionListResponse.fromJson(
                value is Map<String, dynamic> ? value : <String, dynamic>{},
              ).sessions,
        );
    _statsFuture = Future.wait<dynamic>([_coursesFuture, _sessionsFuture]);
  }

  Future<void> _refresh() async {
    setState(_load);
    if (_studentId != null) {
      await _studentFuture.catchError((_) => PublicUserModel());
      return;
    }
    await Future.wait<dynamic>([
      _profileFuture.catchError((_) => UserProfileModel()),
      _coursesFuture.catchError((_) => <CourseModel>[]),
      _sessionsFuture.catchError((_) => <SessionModel>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child:
              _studentId != null
                  ? _buildOtherStudent(context)
                  : ListView(
                    padding: EdgeInsets.all(Responsive.w(2)),
                    children: [
                      _buildAppBar(context),
                      SizedBox(height: Responsive.h(2)),
                      _buildProfileSection(),
                      SizedBox(height: Responsive.h(2)),
                      const Divider(color: Colors.grey),
                      SizedBox(height: Responsive.h(2)),
                      _buildStatsRow(),
                      SizedBox(height: Responsive.h(2)),
                      _buildCourseList(context),
                    ],
                  ),
        ),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    final drawer =
        Get.isRegistered<CustomDrawerController>()
            ? Get.find<CustomDrawerController>()
            : null;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
                SizedBox(width: Responsive.w(2)),
                Text(
                  'Student Profile',
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
        if (drawer != null)
          GestureDetector(
            onTap: drawer.toggleDrawer,
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
    );
  }

  // ── Another student (teacher/mentor viewing) ─────────

  Widget _buildOtherStudent(BuildContext context) {
    return FutureBuilder<PublicUserModel>(
      future: _studentFuture,
      builder: (context, snapshot) {
        final children = <Widget>[_buildAppBar(context)];
        if (snapshot.connectionState == ConnectionState.waiting) {
          children.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is ForbiddenException) {
            children.add(
              _messageBox(
                Icons.lock_outline,
                'You can only view students you teach or have a session with',
              ),
            );
          } else if (error is NotFoundException) {
            children.add(
              _messageBox(
                Icons.person_off_outlined,
                'This student could not be found.',
              ),
            );
          } else {
            children.add(_errorBox(Utils.errorMessage(error)));
          }
        } else {
          final s = snapshot.data ?? PublicUserModel();
          children.addAll([
            SizedBox(height: Responsive.h(2)),
            _buildStudentHeader(s),
            SizedBox(height: Responsive.h(2)),
            const Divider(color: Colors.grey),
            SizedBox(height: Responsive.h(1)),
            _sectionTitle('Shared Courses'),
            SizedBox(height: Responsive.h(1)),
            if (s.sharedCourses.isEmpty)
              _emptyText('No shared courses')
            else
              for (final c in s.sharedCourses)
                Padding(
                  padding: EdgeInsets.only(bottom: Responsive.h(1.5)),
                  child: _buildSharedCourseCard(c),
                ),
            SizedBox(height: Responsive.h(2)),
            _sectionTitle('Sessions Together'),
            SizedBox(height: Responsive.h(1)),
            if (s.sharedSessions.isEmpty)
              _emptyText('No sessions together')
            else
              for (final session in s.sharedSessions)
                Padding(
                  padding: EdgeInsets.only(bottom: Responsive.h(1.5)),
                  child: _buildSharedSessionCard(session),
                ),
          ]);
        }
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(Responsive.w(2)),
          children: children,
        );
      },
    );
  }

  Widget _buildStudentHeader(PublicUserModel s) {
    final avatar = s.avatarUrl ?? '';
    final name = s.name ?? '';
    final bio = s.bio ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: Responsive.w(10),
              backgroundColor: AppColor.secconderyColor,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child:
                  avatar.isEmpty
                      ? Icon(
                        Icons.person,
                        color: AppColor.white,
                        size: Responsive.w(10),
                      )
                      : null,
            ),
            SizedBox(width: Responsive.w(3)),
            if (name.isNotEmpty)
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.20,
                  ),
                ),
              ),
          ],
        ),
        if (bio.isNotEmpty) ...[
          SizedBox(height: Responsive.h(2)),
          Text(
            bio,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: Responsive.textScaleFactor * 12,
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSharedCourseCard(SharedCourseModel c) {
    final thumb = c.thumbnail ?? '';
    final status = (c.enrollmentStatus ?? '').toLowerCase();
    final progress = c.progress?.clamp(0, 100);
    final enrolled = _formatDate(c.enrolledAt);
    return Container(
      padding: EdgeInsets.all(Responsive.w(3)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumb.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumb,
                width: Responsive.w(16),
                height: Responsive.w(16),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: Responsive.w(3)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((c.title ?? '').isNotEmpty)
                  Text(
                    c.title!,
                    style: TextStyle(
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.textScaleFactor * 15,
                    ),
                  ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _chip(
                    status == 'completed'
                        ? 'Completed'
                        : status == 'active'
                        ? 'In progress'
                        : _capitalize(status),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 6,
                            backgroundColor: AppColor.white.withValues(
                              alpha: 0.15,
                            ),
                            color: AppColor.red,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(2)),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (enrolled != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Enrolled $enrolled',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedSessionCard(SharedSessionModel session) {
    final heading = session.title ?? session.topic ?? '';
    final topic =
        (session.title != null && session.topic != null) ? session.topic! : '';
    final when = _formatDateTime(session.dateTime);
    final status = session.status ?? '';
    final duration = session.duration ?? '';
    final type = session.sessionType ?? '';
    final meta = <String>[
      if (when != null) when,
      if (duration.isNotEmpty) '$duration min',
      if (type.isNotEmpty) _capitalize(type),
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.w(3)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heading.isNotEmpty ? heading : 'Session',
                  style: TextStyle(
                    color: AppColor.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.textScaleFactor * 15,
                  ),
                ),
              ),
              if (status.isNotEmpty) _chip(_capitalize(status)),
            ],
          ),
          if (topic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              topic,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta.join(' · '),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.rethinkSans(
      color: AppColor.white,
      fontSize: Responsive.textScaleFactor * 16,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _emptyText(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );

  Widget _messageBox(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String? _formatDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null ? null : DateFormat('d MMM yyyy').format(d.toLocal());
  }

  static String? _formatDateTime(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    return d == null
        ? null
        : DateFormat('d MMM yyyy, h:mm a').format(d.toLocal());
  }

  // ── Profile ──────────────────────────────────────────

  Widget _buildProfileSection() {
    return FutureBuilder<UserProfileModel>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _errorBox(Utils.errorMessage(snapshot.error));
        }
        final p = snapshot.data ?? UserProfileModel();
        final name = (p.name ?? '').trim();
        final avatar = (p.avatarUrl ?? '').trim();
        final education = (p.educationLevel ?? '').trim();
        final bio = (p.bio ?? '').trim();
        final language = (p.language ?? '').trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: Responsive.w(10),
                  backgroundColor: AppColor.secconderyColor,
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child:
                      avatar.isEmpty
                          ? Icon(
                            Icons.person,
                            color: AppColor.white,
                            size: Responsive.w(10),
                          )
                          : null,
                ),
                SizedBox(width: Responsive.w(3)),
                if (name.isNotEmpty)
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
              ],
            ),
            if (education.isNotEmpty) ...[
              SizedBox(height: Responsive.h(2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Education Level', style: _labelStyle()),
                  Flexible(
                    child: Text(
                      education,
                      textAlign: TextAlign.end,
                      style: _labelStyle(),
                    ),
                  ),
                ],
              ),
            ],
            if (bio.isNotEmpty) ...[
              SizedBox(height: Responsive.h(2)),
              Text(
                bio,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 12,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ],
            if (language.isNotEmpty) ...[
              SizedBox(height: Responsive.h(2)),
              Row(
                children: [
                  SvgPicture.asset("assets/icons/mic.svg"),
                  SizedBox(width: Responsive.w(1)),
                  Flexible(
                    child: Text(
                      language,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  TextStyle _labelStyle() => GoogleFonts.dmSans(
    color: Colors.white,
    fontSize: Responsive.textScaleFactor * 12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.20,
  );

  // ── Stats ────────────────────────────────────────────

  Widget _buildStatsRow() {
    return FutureBuilder<List<dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        String inProgress = '…', booked = '…', completed = '…';
        if (snapshot.connectionState != ConnectionState.waiting) {
          if (snapshot.hasError) {
            inProgress = booked = completed = '–';
          } else {
            final courses = snapshot.data![0] as List<CourseModel>;
            final sessions = snapshot.data![1] as List<SessionModel>;
            final done = courses.where((c) => c.isCompleted).length;
            inProgress = _twoDigits(courses.length - done);
            completed = _twoDigits(done);
            booked = _twoDigits(
              sessions
                  .where(
                    (s) =>
                        !const {
                          'cancelled',
                          'canceled',
                        }.contains((s.status ?? '').toLowerCase()),
                  )
                  .length,
            );
          }
        }
        return Row(
          children: [
            Expanded(child: _buildStatCard('Courses in Progress', inProgress)),
            SizedBox(width: Responsive.w(2)),
            Expanded(child: _buildStatCard('Sessions Booked', booked)),
            SizedBox(width: Responsive.w(2)),
            Expanded(child: _buildStatCard('Courses Completed', completed)),
          ],
        );
      },
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Widget _buildStatCard(String title, String value) {
    return Container(
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
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: Responsive.textScaleFactor * 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
            SizedBox(height: Responsive.h(1)),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: GoogleFonts.rethinkSans(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Courses ──────────────────────────────────────────

  Widget _buildCourseList(BuildContext context) {
    return FutureBuilder<List<CourseModel>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _errorBox(Utils.errorMessage(snapshot.error));
        }
        final courses = snapshot.data ?? const <CourseModel>[];
        if (courses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No courses yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final course in courses)
              Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(2)),
                child: _buildCourseCard(context, course),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final title = (course.title ?? '').trim();
    final duration = (course.duration ?? '').trim();
    final teacher = (course.teacherName ?? '').trim();
    final rating = course.rating;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(2.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Responsive.h(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (course.price != null) ...[
                      SvgPicture.asset(
                        "assets/icons/Frame 1000002079.svg",
                        colorFilter: ColorFilter.mode(
                          AppColor.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: Responsive.w(1)),
                      Text(
                        _priceLabel(course.price!),
                        style: TextStyle(
                          color: AppColor.white,
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.textScaleFactor * 14,
                        ),
                      ),
                    ],
                    if (course.isCompleted) ...[
                      SizedBox(width: Responsive.w(2)),
                      _chip('Completed'),
                    ],
                  ],
                ),
                GestureDetector(
                  onTap: () => _courseDetailsSheet(context, course),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(3),
                        vertical: Responsive.h(1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Details",
                            style: TextStyle(
                              fontSize: Responsive.textScaleFactor * 14,
                              color: AppColor.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: Responsive.w(1)),
                          SvgPicture.asset(
                            "assets/icons/arrow.svg",
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (duration.isNotEmpty) ...[
              SizedBox(height: Responsive.h(1)),
              Text(
                "Duration: $duration",
                style: TextStyle(
                  color: AppColor.white,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.textScaleFactor * 14,
                ),
              ),
            ],
            if (title.isNotEmpty) ...[
              SizedBox(height: Responsive.h(1)),
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.textScaleFactor * 20,
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (teacher.isNotEmpty || (rating != null && rating > 0)) ...[
              SizedBox(height: Responsive.h(1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (teacher.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: Responsive.sp(22),
                            backgroundColor: AppColor.secconderyColor,
                            child: Icon(Icons.person, color: AppColor.white),
                          ),
                          SizedBox(width: Responsive.w(2)),
                          Flexible(
                            child: Text(
                              teacher,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColor.white,
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.textScaleFactor * 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (rating != null && rating > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColor.white,
                          size: Responsive.sp(16),
                        ),
                        SizedBox(width: Responsive.w(1)),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.textScaleFactor * 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _priceLabel(double price) =>
      price <= 0 ? 'Free' : '\$${price.toStringAsFixed(2)}';

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColor.white.withValues(alpha: 0.15),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () => setState(_load),
            child: const Text('Retry', style: TextStyle(color: AppColor.red)),
          ),
        ],
      ),
    );
  }

  /// Real details of a course the student is already enrolled in, with an
  /// action that opens the course's lessons.
  void _courseDetailsSheet(BuildContext context, CourseModel course) {
    final rows = <MapEntry<String, String>>[
      if ((course.teacherName ?? '').isNotEmpty)
        MapEntry('Teacher', course.teacherName!),
      if ((course.category ?? '').isNotEmpty)
        MapEntry('Course Category', course.category!),
      if ((course.level ?? '').isNotEmpty) MapEntry('Level', course.level!),
      if ((course.duration ?? '').isNotEmpty)
        MapEntry('Course Duration', course.duration!),
      if ((course.language ?? '').isNotEmpty)
        MapEntry('Language', course.language!),
      if (course.rating != null && course.rating! > 0)
        MapEntry('Rating', course.rating!.toStringAsFixed(1)),
      if (course.price != null) MapEntry('Price', _priceLabel(course.price!)),
      if ((course.enrollmentStatus ?? '').isNotEmpty)
        MapEntry('Status', course.isCompleted ? 'Completed' : 'In progress'),
    ];
    final description = (course.description ?? '').trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: AppColor.primaryColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: Responsive.w(5),
              right: Responsive.w(5),
              top: Responsive.h(3),
              bottom: Responsive.h(2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (course.title ?? '').trim().isNotEmpty
                            ? course.title!.trim()
                            : 'Course details',
                        style: TextStyle(
                          color: AppColor.white,
                          fontSize: Responsive.textScaleFactor * 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: Icon(Icons.close, color: AppColor.white),
                    ),
                  ],
                ),
                if (rows.isNotEmpty) ...[
                  SizedBox(height: Responsive.h(1)),
                  const Divider(color: Colors.grey),
                  for (final row in rows) ...[
                    SizedBox(height: Responsive.h(1)),
                    _buildCourseInfoRow(row.key, row.value),
                  ],
                ],
                if (description.isNotEmpty) ...[
                  SizedBox(height: Responsive.h(2)),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 12,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ],
                SizedBox(height: Responsive.h(3)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed:
                        (course.courseId ?? '').isEmpty
                            ? null
                            : () async {
                              Navigator.pop(sheetContext);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => MyTakenCousreView(course: course),
                                ),
                              );
                              // The course may have been marked completed.
                              if (mounted) setState(_load);
                            },
                    child: const Text('Open course'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(width: Responsive.w(2)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.textScaleFactor * 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
