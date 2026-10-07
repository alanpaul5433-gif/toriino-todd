import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/widgets/session_booking_sheet.dart';

/// Student-side 1-on-1 booking: pick a date and a start/end time, then open the
/// booking sheet. The price is quoted by the server (GET /payments/quote) —
/// the app never calculates it.
class AvailabilityView extends StatefulWidget {
  final String mentorId;
  final String mentorName;

  const AvailabilityView({
    super.key,
    required this.mentorId,
    required this.mentorName,
  });

  @override
  State<AvailabilityView> createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<AvailabilityView> {
  /// Server limits for a student booking's duration (minutes).
  static const int _minDuration = 15;
  static const int _maxDuration = 480;
  static const int _defaultDuration = 60;

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? const TimeOfDay(hour: 11, minute: 0),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  /// Session length in minutes from the chosen times (default 60 when no end
  /// time is chosen). Null when the end is not after the start.
  int? get _durationMinutes {
    final start = _startTime;
    final end = _endTime;
    if (start == null || end == null) return _defaultDuration;
    final minutes =
        (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    return minutes > 0 ? minutes : null;
  }

  void _openBooking() {
    final date = _date;
    final start = _startTime;
    if (date == null || start == null) {
      Utils.toastMassage('Please choose a date and a start time');
      return;
    }
    final scheduledAt =
        DateTime(date.year, date.month, date.day, start.hour, start.minute);
    if (!scheduledAt.isAfter(DateTime.now())) {
      Utils.toastMassage('Please choose a time in the future');
      return;
    }
    final duration = _durationMinutes;
    if (duration == null) {
      Utils.toastMassage('End time must be after the start time');
      return;
    }
    if (duration < _minDuration || duration > _maxDuration) {
      Utils.toastMassage(
          'Sessions must be between $_minDuration minutes and ${_maxDuration ~/ 60} hours');
      return;
    }
    showSessionBookingSheet(
      context,
      mentorId: widget.mentorId,
      mentorName: widget.mentorName,
      scheduledAt: scheduledAt,
      durationMinutes: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Responsive.h(2)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                          "assets/icons/Arrow - Right 3 (1).svg"),
                    ),
                    SizedBox(width: Responsive.w(2)),
                    Text(
                      'Book a Session',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),
                Text(
                  widget.mentorName.trim().isNotEmpty
                      ? 'Choose a date and time for your 1-on-1 session with ${widget.mentorName}.'
                      : 'Choose a date and time for your 1-on-1 session.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                _buildField(
                  text: _date != null
                      ? DateFormat('EEE, d MMM yyyy').format(_date!)
                      : null,
                  hint: 'Select Date',
                  onTap: _selectDate,
                ),
                SizedBox(height: Responsive.h(1)),
                _buildField(
                  text: _startTime != null ? _formatTimeOfDay(_startTime!) : null,
                  hint: 'Start Time',
                  onTap: _selectStartTime,
                ),
                SizedBox(height: Responsive.h(1)),
                _buildField(
                  text: _endTime != null ? _formatTimeOfDay(_endTime!) : null,
                  hint: 'End Time (default 1 hour)',
                  onTap: _selectEndTime,
                ),
                SizedBox(height: Responsive.h(2)),
                GestureDetector(
                  onTap: _openBooking,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: Responsive.padding(
                        left: 1,
                        right: 1,
                        top: 2,
                        bottom: 2,
                      ),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String? text,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          text ?? hint,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            color: text != null
                ? AppColor.white
                : AppColor.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
