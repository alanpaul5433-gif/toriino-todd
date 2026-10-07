import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/model/user/public_user_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/availability_view.dart';
import 'package:toriino_todd/view/users/student_view/course_view.dart';
import 'package:toriino_todd/widgets/intro_video_tile.dart';

/// Public profile of a teacher or mentor, built only from
/// GET /users/{teacherId}: name, avatar, title, bio, expertise/specialties,
/// language, rating, hourly rate, intro video and their published courses.
/// Empty fields are hidden rather than shown as placeholders.
class TeacherProfile extends StatefulWidget {
  final String teacherId;
  const TeacherProfile({super.key, required this.teacherId});

  @override
  State<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  late Future<PublicUserModel> _future;
  bool _openingCourse = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final id = widget.teacherId.trim();
    _future =
        id.isEmpty
            ? Future.error(NotFoundException('User not found'))
            : UserRepo()
                .getUserById(id)
                .then(
                  (value) => PublicUserModel.fromJson(
                    value is Map<String, dynamic> ? value : <String, dynamic>{},
                  ),
                );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future.catchError((_) => PublicUserModel());
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<PublicUserModel>(
            future: _future,
            builder: (context, snapshot) {
              final children = <Widget>[];
              String heading = 'Teacher Profile';
              if (snapshot.connectionState == ConnectionState.waiting) {
                children.add(
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else if (snapshot.hasError) {
                children.add(_errorBox(snapshot.error));
              } else {
                final p = snapshot.data ?? PublicUserModel();
                if ((p.role ?? '').toLowerCase() == 'mentor') {
                  heading = 'Mentor Profile';
                }
                children.addAll(_buildProfile(context, p));
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                children: [_buildAppBar(context, heading), ...children],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String heading) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          SvgPicture.asset(
            "assets/icons/Arrow - Right 3 (1).svg",
            width: Responsive.w(6),
            height: Responsive.w(6),
          ),
          SizedBox(width: Responsive.w(2)),
          Text(
            heading,
            style: GoogleFonts.rethinkSans(
              color: AppColor.white,
              fontSize: Responsive.textScaleFactor * 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.20,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfile(BuildContext context, PublicUserModel p) {
    final name = p.name ?? '';
    final avatar = p.avatarUrl ?? '';
    final subtitle = p.title ?? p.role ?? '';
    final bio = p.bio ?? '';
    final language = p.language ?? '';
    final rate = p.hourlyRate;
    final rating = p.rating;
    final reviews = p.reviewCount;
    final sessions = p.totalSessions;
    final isMentor = (p.role ?? '').toLowerCase() == 'mentor';

    final stats = <String>[
      if (rating != null && rating > 0)
        '★ ${rating.toStringAsFixed(1)}'
            '${reviews != null && reviews > 0 ? ' ($reviews review${reviews == 1 ? '' : 's'})' : ''}',
      if (sessions != null && sessions > 0)
        '$sessions session${sessions == 1 ? '' : 's'}',
    ];

    return [
      SizedBox(height: Responsive.h(2)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.30,
                    ),
                  ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    stats.join('  ·  '),
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: Responsive.textScaleFactor * 12,
                    ),
                  ),
                ],
              ],
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
      if (language.isNotEmpty || (rate != null && rate > 0)) ...[
        SizedBox(height: Responsive.h(2)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (language.isNotEmpty)
              Flexible(
                child: Row(
                  children: [
                    SvgPicture.asset("assets/icons/mic.svg"),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        language,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),
            if (rate != null && rate > 0)
              Text(
                '\$${rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2)}/hr',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ],
      const Divider(),
      if (p.expertise.isNotEmpty) ...[
        _sectionTitle('Expertise'),
        SizedBox(height: Responsive.h(1)),
        _chips(p.expertise),
        SizedBox(height: Responsive.h(2)),
      ],
      if (p.specialties.isNotEmpty) ...[
        _sectionTitle('Specialties'),
        SizedBox(height: Responsive.h(1)),
        _chips(p.specialties),
        SizedBox(height: Responsive.h(2)),
      ],
      if ((p.introVideoUrl ?? '').isNotEmpty) ...[
        _sectionTitle('Intro Video'),
        SizedBox(height: Responsive.h(1)),
        IntroVideoTile(url: p.introVideoUrl),
        SizedBox(height: Responsive.h(2)),
      ],
      if (isMentor) ...[
        _bookSessionButton(context, p),
        SizedBox(height: Responsive.h(2)),
      ],
      _sectionTitle('Courses'),
      SizedBox(height: Responsive.h(1)),
      if (p.courses.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'No published courses yet',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        )
      else
        for (final c in p.courses)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _courseCard(context, c),
          ),
      SizedBox(height: Responsive.h(2)),
    ];
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.dmSans(
      color: Colors.white,
      fontSize: Responsive.textScaleFactor * 12,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _chips(List<String> items) {
    return Wrap(
      spacing: 5,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              item,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ),
      ],
    );
  }

  /// Opens the real booking screen (mentor availability → session request).
  Widget _bookSessionButton(BuildContext context, PublicUserModel p) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AvailabilityView(
                    mentorId: p.userId ?? widget.teacherId,
                    mentorName: p.name ?? 'Mentor',
                    hourlyRate: p.hourlyRate ?? 0.0,
                  ),
            ),
          ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AppColor.red,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Book a session',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.20,
          ),
        ),
      ),
    );
  }

  Widget _courseCard(BuildContext context, PublicCourseModel c) {
    final thumb = c.thumbnail ?? '';
    final price = c.price;
    final duration = c.duration ?? '';
    final title = c.title ?? '';
    final meta = [
      if ((c.category ?? '').isNotEmpty) c.category!,
      if ((c.level ?? '').isNotEmpty) c.level!,
    ].join(' · ');
    final rating = c.rating;
    final canOpen = (c.courseId ?? '').isNotEmpty;

    return GestureDetector(
      onTap: canOpen ? () => _openCourse(context, c.courseId!) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumb.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  thumb,
                  width: Responsive.w(20),
                  height: Responsive.w(20),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (price != null)
                        Text(
                          price <= 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (canOpen)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: AppColor.red,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 14.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 5),
                              SvgPicture.asset("assets/icons/arrow.svg"),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: Responsive.textScaleFactor * 16,
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Duration: $duration',
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (meta.isNotEmpty || (rating != null && rating > 0)) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (meta.isNotEmpty)
                          Expanded(
                            child: Text(
                              meta,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (rating != null && rating > 0) ...[
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 3),
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loads the full course (GET /courses/{id}) and opens the catalog's
  /// existing course detail / enroll sheet for it.
  Future<void> _openCourse(BuildContext context, String courseId) async {
    if (_openingCourse) return;
    setState(() => _openingCourse = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    CourseModel? course;
    Object? error;
    try {
      final value = await CourseRepo().getCourseById(courseId);
      course = CourseModel.fromJson(
        value is Map<String, dynamic> ? value : <String, dynamic>{},
      );
    } catch (e) {
      error = e;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    setState(() => _openingCourse = false);
    if (course == null || (course.courseId ?? '').isEmpty) {
      Utils.toastMassage(
        error != null
            ? Utils.errorMessage(error)
            : 'Could not load this course',
      );
      return;
    }
    showCourseEnrollSheet(context, course);
  }

  Widget _errorBox(Object? error) {
    if (error is NotFoundException) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.person_off_outlined, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'This profile could not be found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Text(
            Utils.errorMessage(error),
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
}
