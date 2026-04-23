import 'package:awesome_calendart/awesome_calendart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class EditMentorAvaiblityView extends StatefulWidget {
  const EditMentorAvaiblityView({super.key});

  @override
  State<EditMentorAvaiblityView> createState() =>
      _EditMentorAvaiblityViewState();
}

class _EditMentorAvaiblityViewState extends State<EditMentorAvaiblityView> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedSessionMode = 'Group'; // '1-on-1' or 'Group'
  String? _sessionType; // Make it nullable

  final bool _splitPayment = false;

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColor.red,
              onPrimary: AppColor.white,
              surface: AppColor.primaryColor,
              onSurface: AppColor.white,
            ),
            // ignore: deprecated_member_use AppColor.primaryColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 30),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColor.red,
              onPrimary: AppColor.white,
              surface: AppColor.primaryColor,
              onSurface: AppColor.white,
            ),
            // ignore: deprecated_member_use AppColor.primaryColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.w(4)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
                  SizedBox(width: Responsive.w(2)),
                  Text(
                    'Edit Your Availability',
                    style: GoogleFonts.rethinkSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              Text(
                'Choose the days and time slots when you’re available to take sessions.',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 12,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),

              // Edit Button
              SizedBox(height: Responsive.h(2)),
              Text(
                'Select Preferred Date',
                style: GoogleFonts.rethinkSans(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // Calendar
              Container(
                margin: EdgeInsets.symmetric(vertical: Responsive.h(1)),
                padding: EdgeInsets.all(Responsive.w(2)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColor.primaryColor,
                ),
                child: AwesomeCalenDart(
                  theme: AwesomeTheme(
                    buttonColor: AppColor.red,
                    yearAndMonthHeaderTextStyle: TextStyle(
                      color: AppColor.white,
                    ),
                    weekDaysTextStyle: TextStyle(
                      color: AppColor.white.withValues(alpha: 0.2),
                    ),
                    eventMarkerColorOnSelectedDay: AppColor.red,
                    unselectedDayTextStyle: TextStyle(
                      color: AppColor.white.withValues(alpha: 0.2),
                    ),
                    backgroundColor: AppColor.white.withValues(alpha: 0.08),
                    selectedDateBackgroundColor: AppColor.red,
                  ),
                ),
              ),

              // Start Time
              _buildTimeField(
                time: _startTime,
                onTap: _selectStartTime,
                hint: 'Start Time',
              ),
              SizedBox(height: Responsive.h(2)),

              // End Time
              _buildTimeField(
                time: _endTime,
                onTap: _selectEndTime,
                hint: 'End Time',
              ),
              SizedBox(height: Responsive.h(2)),

              // Session Mode Toggle (1-on-1 vs Group)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.w(3)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColor.white.withValues(alpha: 0.08),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session Type',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.20,
                      ),
                    ),
                    Row(
                      children: [
                        // 1-on-1 Option
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSessionMode = '1-on-1';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(4),
                              vertical: Responsive.h(1),
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    _selectedSessionMode == '1-on-1'
                                        ? AppColor.red
                                        : AppColor.white.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(22),
                              color:
                                  _selectedSessionMode == '1-on-1'
                                      ? AppColor.red.withValues(alpha: 0.2)
                                      : Colors.transparent,
                            ),
                            child: Text(
                              '1-on-1',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.20,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(2)),
                        // Group Option
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSessionMode = 'Group';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(4),
                              vertical: Responsive.h(1),
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    _selectedSessionMode == 'Group'
                                        ? AppColor.red
                                        : AppColor.white.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(22),
                              color:
                                  _selectedSessionMode == 'Group'
                                      ? AppColor.red
                                      : Colors.transparent,
                            ),
                            child: Text(
                              'Group',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(2)),

              // Seat Selection (only show for Group sessions)
              if (_selectedSessionMode == 'Group') ...[
                _buildDropdownField(
                  value: _sessionType,
                  items: const ['1', '2', '3', '4', '5', '6', '7'],
                  onChanged: (value) {
                    setState(() {
                      _sessionType = value;
                    });
                  },
                  hint: 'Number of Seats',
                ),
                SizedBox(height: Responsive.h(2)),
              ],

              SizedBox(height: Responsive.h(3)),

              // Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColor.red, AppColor.red.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Save availability logic
                    if (kDebugMode) {
                      print('Start Time: ${_startTime?.format(context)}');
                      print('End Time: ${_endTime?.format(context)}');
                      print('Session Mode: $_selectedSessionMode');
                      print('Seats: $_sessionType');
                      print('Split Payment: $_splitPayment');
                    }
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: Responsive.h(2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Save ',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTimeField({
    required TimeOfDay? time,
    required VoidCallback onTap,
    required String hint,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.w(4)),
        decoration: BoxDecoration(
          color: AppColor.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColor.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppColor.white.withValues(alpha: 0.7),
              size: Responsive.w(6),
            ),
            SizedBox(width: Responsive.w(3)),
            Expanded(
              child: Text(
                time != null ? _formatTimeOfDay(time) : hint,
                style: GoogleFonts.dmSans(
                  color:
                      time != null
                          ? AppColor.white
                          : AppColor.white.withValues(alpha: 0.5),
                  fontSize: Responsive.textScaleFactor * 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value, // Make it nullable
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(4)),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColor.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        dropdownColor: AppColor.primaryColor,
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        hint:
            hint != null
                ? Text(
                  hint,
                  style: GoogleFonts.dmSans(
                    color: AppColor.white.withValues(alpha: 0.5),
                    fontSize: Responsive.textScaleFactor * 14,
                  ),
                )
                : null,
        items:
            items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: AppColor.white,
                    fontSize: Responsive.textScaleFactor * 14,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
