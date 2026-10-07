import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/session/session_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/live_session/live_session_screen.dart';
import 'package:toriino_todd/view/live_session/session_summary_screen.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_create_session_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_session_viewmodel.dart';
import 'package:toriino_todd/widgets/components/drop_down_text.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorSessionsView extends StatelessWidget {
  const MentorSessionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    final MentorSessionViewmodel sessionVm = Get.put(MentorSessionViewmodel());
    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MentorCreateSessionView()),
        ),
        backgroundColor: AppColor.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Session',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 1, right: 1, top: 1),
          child: Obx(() {
            final state = sessionVm.rxSessions.value;
            final sessions = state.data?.sessions ?? [];
            final upcoming = sessions
                .where((s) => s.status == 'scheduled' || s.status == 'active')
                .toList();
            final history = sessions
                .where((s) => s.status == 'completed' || s.status == 'cancelled')
                .toList();

            return ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Sessions',
                                style: GoogleFonts.rethinkSans(
                                  color: Colors.white,
                                  fontSize: Responsive.textScaleFactor * 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.20,
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
                            child: SvgPicture.asset('assets/icons/time.svg'),
                          ),
                        ),
                        SizedBox(width: Responsive.w(2)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NotificationsScreen()),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.backGroundColor.withValues(alpha: 0.1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset('assets/icons/notification.svg'),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(2)),
                        GestureDetector(
                          onTap: customDrawerController.advancedDrawerController.toggleDrawer,
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
                          child: _statCard(
                            'Total Sessions',
                            sessions.length.toString(),
                          ),
                        ),
                        SizedBox(width: Responsive.w(4)),
                        Expanded(
                          child: _statCard(
                            'Upcoming Sessions',
                            upcoming.length.toString(),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.h(1)),

                    Text(
                      'Upcoming Sessions',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                    SizedBox(height: Responsive.h(1)),

                    if (state.status == Status.loading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Colors.white),
                      ))
                    else if (upcoming.isEmpty)
                      _emptyCard('No upcoming sessions.\nTap "Create Session" to schedule one.')
                    else
                      ...upcoming.map((s) => _upcomingCard(context, s, sessionVm)),

                    SizedBox(height: Responsive.h(1)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent History',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.20,
                          ),
                        ),
                        SortByDropdown(),
                      ],
                    ),

                    if (state.status != Status.loading && history.isEmpty)
                      _emptyCard('No completed sessions yet.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) =>
                            _historyCard(history[index]),
                      ),

                    SizedBox(height: Responsive.h(10)),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: Responsive.padding(left: 2, right: 2, top: 2, bottom: 2),
        child: Column(
          spacing: Responsive.h(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.rethinkSans(
                color: Colors.white,
                fontSize: Responsive.textScaleFactor * 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.rethinkSans(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13),
        ),
      ),
    );
  }

  Widget _upcomingCard(
      BuildContext context, SessionModel s, MentorSessionViewmodel vm) {
    final dateLabel = _formatDate(s.dateTime);
    final initial = s.isGroup
        ? 'G'
        : (s.studentId ?? 'S').substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: s.isGroup
                            ? Colors.blueAccent.withValues(alpha: 0.6)
                            : AppColor.red,
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.topic ?? 'Session',
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (s.isGroup) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Group',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            s.isGroup
                                ? 'Up to ${s.maxParticipants ?? '—'} participants'
                                : 'Student',
                            style: GoogleFonts.dmSans(
                              color: AppColor.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.status ?? 'scheduled',
                      style: GoogleFonts.dmSans(
                        color: AppColor.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1),
              Text(
                dateLabel,
                style: GoogleFonts.dmSans(
                  fontSize: Responsive.textScaleFactor * 16,
                  color: AppColor.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _sessionInfoRow(
                type: s.isGroup ? 'Group' : 'Individual',
                duration: s.duration != null ? '${s.duration}min' : '—',
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveSessionScreen(
                            sessionId: s.sessionId ?? '',
                            isMentor: true,
                          ),
                        ),
                      ),
                      child: Container(
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
                                "Start Session",
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyCard(SessionModel s) {
    final initial = s.isGroup
        ? 'G'
        : (s.studentId ?? 'S').substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColor.white.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Responsive.h(1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: s.isGroup
                            ? Colors.blueAccent.withValues(alpha: 0.4)
                            : AppColor.white.withValues(alpha: 0.2),
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: Responsive.w(2)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s.topic ?? 'Session',
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (s.isGroup) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Group',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatDate(s.dateTime),
                            style: GoogleFonts.dmSans(
                              color: AppColor.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.status == 'completed'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.status ?? '',
                      style: GoogleFonts.dmSans(
                        color: s.status == 'completed' ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (s.status == 'completed' && (s.sessionId ?? '').isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Get.to(
                      () => SessionSummaryScreen(sessionId: s.sessionId!),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: AppColor.red, size: 16),
                    label: Text(
                      'View AI summary',
                      style: GoogleFonts.dmSans(
                        color: AppColor.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: Responsive.h(1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionInfoRow({required String type, required String duration}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Type", style: GoogleFonts.dmSans(fontSize: 12, color: AppColor.white, fontWeight: FontWeight.bold)),
              Text(type, style: GoogleFonts.dmSans(fontSize: 12, color: AppColor.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Container(width: 1, height: 30, color: AppColor.white.withValues(alpha: 0.3)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Duration", style: GoogleFonts.dmSans(fontSize: 12, color: AppColor.white, fontWeight: FontWeight.bold)),
              Text(duration, style: GoogleFonts.dmSans(fontSize: 12, color: AppColor.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '—';
    try {
      final dt = DateTime.parse(dateTime).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]}, $hour:$min $ampm';
    } catch (_) {
      return dateTime;
    }
  }
}
