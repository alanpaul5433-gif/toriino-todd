import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/student_public_profile_view.dart';

/// A session card for the teacher/mentor home screens, built only from the
/// real [SessionModel]. Empty fields are hidden.
///
/// When the session has a `studentId`, tapping the student opens
/// [StudentPublicProfileView] for that student (GET /users/{studentId}).
/// [onStart] adds a "Start Session" button (upcoming sessions only).
class SessionStudentCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onStart;

  const SessionStudentCard({super.key, required this.session, this.onStart});

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final studentId = (session.studentId ?? '').trim();
    final topic = (session.topic ?? '').trim();
    final status = (session.status ?? '').trim();
    final parsed = DateTime.tryParse(session.dateTime ?? '');
    final dateLabel =
        parsed == null
            ? null
            : DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
    final duration = session.duration;
    final type = (session.sessionType ?? '').trim();
    final details = <MapEntry<String, String>>[
      if (dateLabel != null) MapEntry('Date', dateLabel),
      if (duration != null && duration > 0)
        MapEntry('Duration', '${duration}min'),
      if (type.isNotEmpty) MapEntry('Type', _cap(type)),
    ];

    final studentHeader = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColor.white.withValues(alpha: 0.15),
          child: Icon(Icons.person, color: AppColor.white),
        ),
        SizedBox(width: Responsive.wp(2)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.isGroup ? 'Group session' : 'Student',
              style: GoogleFonts.dmSans(
                color: AppColor.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (studentId.isNotEmpty)
              Text(
                'View student profile',
                style: GoogleFonts.dmSans(
                  color: AppColor.white.withValues(alpha: 0.7),
                  fontSize: Responsive.textScaleFactor * 12,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColor.white.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ],
    );

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
                  Flexible(
                    child:
                        studentId.isNotEmpty
                            ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => StudentPublicProfileView(
                                            studentId: studentId,
                                          ),
                                    ),
                                  ),
                              child: studentHeader,
                            )
                            : studentHeader,
                  ),
                  if (status.isNotEmpty)
                    Text(
                      _cap(status),
                      style: GoogleFonts.rethinkSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.30,
                      ),
                    ),
                ],
              ),
              if (topic.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  topic,
                  style: GoogleFonts.dmSans(
                    fontSize: Responsive.textScaleFactor * 14,
                    color: AppColor.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (details.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Row(children: [Expanded(child: Divider(thickness: 1))]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < details.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: AppColor.white,
                        ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details[i].key,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: Responsive.textScaleFactor * 12,
                                color: AppColor.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              details[i].value,
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
                  ],
                ),
              ],
              if (onStart != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColor.red,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Session',
                          style: GoogleFonts.dmSans(
                            fontSize: Responsive.textScaleFactor * 14,
                            color: AppColor.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: Responsive.wp(2)),
                        SvgPicture.asset('assets/icons/arrow.svg'),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: Responsive.hp(1)),
            ],
          ),
        ),
      ),
    );
  }
}
