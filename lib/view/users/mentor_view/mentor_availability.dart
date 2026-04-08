import 'package:awesome_calendart/awesome_calendart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/mentor_view/edit_mentor_avaiblity_view.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorAvailability extends StatefulWidget {
  const MentorAvailability({super.key});

  @override
  State<MentorAvailability> createState() => _MentorAvailabilityState();
}

class _MentorAvailabilityState extends State<MentorAvailability> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedSessionMode = 'Group'; // '1-on-1' or 'Group'
  String? _sessionType; // Make it nullable


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
            dialogBackgroundColor: AppColor.primaryColor,
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
            dialogBackgroundColor: AppColor.primaryColor,
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
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Availability',
                      style: GoogleFonts.rethinkSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                  _buildIconButton('assets/icons/time.svg'),
                  SizedBox(width: Responsive.w(2)),
                  _buildIconButton('assets/icons/notification.svg'),
                  SizedBox(width: Responsive.w(2)),
                  _buildIconButton('assets/icons/menu.svg'),
                ],
              ),
              SizedBox(height: Responsive.h(2)),

              // Edit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>EditMentorAvaiblityView())),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.red,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(3),
                          vertical: Responsive.h(0.8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Edit',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 10,
                                fontWeight: FontWeight.w700,
                                height: 1.80,
                              ),
                            ),
                            SizedBox(width: Responsive.w(1)),
                            SvgPicture.asset(
                              "assets/icons/iconamoon_edit-fill.svg",
                              width: Responsive.w(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),

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
                    yearAndMonthHeaderTextStyle: TextStyle(color: AppColor.white),
                    weekDaysTextStyle :TextStyle(color: AppColor.white.withValues(alpha: 0.2)),
                    eventMarkerColorOnSelectedDay :AppColor.red,
                    unselectedDayTextStyle: TextStyle(color: AppColor.white.withValues(alpha: 0.2)),
                    backgroundColor: AppColor.white.withValues(alpha: 0.08),
                    selectedDateBackgroundColor : AppColor.red,
                    // todayColor: AppColor.red.withValues(alpha:  0.3),
                    // textColor: AppColor.white,
                    // disabledTextColor: AppColor.white.withValues(alpha:  0.5),
                    // // Add other theme properties as needed
                  ),
                ),
              ),
              SizedBox(height: Responsive.h(2)),

              // Start Time
              _buildTimeField(
                time: _startTime,
                onTap: _selectStartTime,
                hint: 'Start Time',
              ),
              SizedBox(height: Responsive.h(1)),

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
                  color: AppColor.white.withValues(alpha:  0.08),
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
                                        : AppColor.white.withValues(alpha:  0.3),
                              ),
                              borderRadius: BorderRadius.circular(22),
                              color:
                                  _selectedSessionMode == '1-on-1'
                                      ? AppColor.red.withValues(alpha:  0.2)
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
                                        : AppColor.white.withValues(alpha:  0.3),
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

              
            
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(String iconPath) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.backGroundColor.withValues(alpha:  0.1),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(2)),
        child: SvgPicture.asset(iconPath, width: Responsive.w(5)),
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
          color: AppColor.white.withValues(alpha:  0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColor.white.withValues(alpha:  0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppColor.white.withValues(alpha:  0.7),
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
                          : AppColor.white.withValues(alpha:  0.5),
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
        color: AppColor.white.withValues(alpha:  0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.white.withValues(alpha:  0.2), width: 1),
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
                    color: AppColor.white.withValues(alpha:  0.5),
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

















// import 'package:awesome_calendart/awesome_calendart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:getxmvvm/resources/colors/app_colors.dart';
// import 'package:getxmvvm/utils/responsive.dart';
// import 'package:getxmvvm/view/student_view/mytheme.dart' hide DarkTheme;
// import 'package:google_fonts/google_fonts.dart';

// class MentorAvailability extends StatefulWidget {
//   const MentorAvailability({super.key});

//   @override
//   State<MentorAvailability> createState() => _MentorAvailabilityState();
// }

// class _MentorAvailabilityState extends State<MentorAvailability> {
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;
//   String _sessionType = 'Seat';
//   String _group = '';
//   int _seat = 5;
//   bool _splitPayment = false;

//   Future<void> _selectStartTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
//     );
//     if (picked != null) {
//       setState(() {
//         _startTime = picked;
//       });
//     }
//   }

//   Future<void> _selectEndTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,

//       initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 30),
//     );
//     if (picked != null) {
//       setState(() {
//         _endTime = picked;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Responsive.init(context);
//     return Scaffold(
//       backgroundColor: AppColor.primaryColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Text(
//                         'Availability',
//                         style: GoogleFonts.rethinkSans(
//                           color: Colors.white,
//                           fontSize: Responsive.textScaleFactor * 18,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: -0.20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColor.backGroundColor.withValues(alpha:  0.1),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SvgPicture.asset('assets/icons/time.svg'),
//                   ),
//                 ),
//                 SizedBox(width: Responsive.w(2)),

//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColor.backGroundColor.withValues(alpha:  0.1),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SvgPicture.asset('assets/icons/notification.svg'),
//                   ),
//                 ),
//                 SizedBox(width: Responsive.w(2)),
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColor.backGroundColor.withValues(alpha:  0.1),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SvgPicture.asset('assets/icons/menu.svg'),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: Responsive.h(2)),

//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     color: AppColor.red,
//                     borderRadius: BorderRadius.circular(18),
//                   ),
//                   child: Padding(
//                     padding: Responsive.padding(
//                       left: 2,
//                       right: 2,
//                       top: 0.5,
//                       bottom: 0.5,
//                     ),
//                     child: Row(
//                       children: [
//                         Text(
//                           'Edit',
//                           style: GoogleFonts.dmSans(
//                             color: Colors.white,
//                             fontSize: Responsive.textScaleFactor * 10,
//                             fontWeight: FontWeight.w700,
//                             height: 1.80,
//                           ),
//                         ),
//                         SizedBox(width: Responsive.w(1)),
//                         SvgPicture.asset(
//                           "assets/icons/iconamoon_edit-fill.svg",
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
         
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
//               padding: EdgeInsets.all(5),
//               child: AwesomeCalenDart(theme: DarkTheme()),
//             ),
//             // Start Time
//             _buildTimeField(
//               time: _startTime,
//               onTap: _selectStartTime,
//               hint: 'Start Time',
//             ),
//             SizedBox(height: Responsive.h(1)),

//             // End Time
//             _buildTimeField(
//               time: _endTime,
//               onTap: _selectEndTime,
//               hint: 'End Time',
//             ),

//             SizedBox(height: Responsive.h(1)),
//             Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(28),
//                 color: AppColor.white.withValues(alpha: 0.08),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Session Type',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontFamily: 'DM Sans',
//                         fontWeight: FontWeight.w400,
//                         letterSpacing: -0.20,
//                       ),
//                     ),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: AppColor.white),
//                         borderRadius: BorderRadius.circular(22),
//                         // color:  AppColor.white.withValues(alpha: 0.08),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(
//                           '1-on-1',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontFamily: 'DM Sans',
//                             fontWeight: FontWeight.w400,
//                             letterSpacing: -0.20,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(22),
//                         color: AppColor.red,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(
//                           'Group',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontFamily: 'DM Sans',
//                             fontWeight: FontWeight.w400,
//                             letterSpacing: -0.20,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: Responsive.h(1)),

//             // Session Type
//             _buildDropdownField(
//               value: _sessionType,
//               items: const ['Seat', '1', '2', "3", "4", "5", "6", "7"],
//               onChanged: (value) {
//                 setState(() {
//                   _sessionType = value!;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Widget _buildTimeField({
//   required TimeOfDay? time,
//   required VoidCallback onTap,
//   required String hint,
// }) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       GestureDetector(
//         onTap: onTap,
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: AppColor.white.withValues(alpha: 0.08),
//             border: Border.all(color: AppColor.white.withValues(alpha: 0.0)),
//             borderRadius: BorderRadius.circular(28),
//           ),
//           child: Text(
//             time != null ? _formatTimeOfDay(time) : hint,
//             style: TextStyle(
//               fontSize: 16,
//               color: time != null ? AppColor.white : AppColor.white,
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }

// String _formatTimeOfDay(TimeOfDay time) {
//   final hour = time.hourOfPeriod;
//   final minute = time.minute.toString().padLeft(2, '0');
//   final period = time.period == DayPeriod.am ? 'AM' : 'PM';
//   return '$hour:${minute} $period';
// }

// Widget _buildDropdownField({
//   required String value,
//   required List<String> items,
//   required ValueChanged<String?> onChanged,
// }) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         decoration: BoxDecoration(
//           color: AppColor.white.withValues(alpha: 0.08),
//           borderRadius: BorderRadius.circular(22),
//         ),
//         child: DropdownButton<String>(
//           dropdownColor: AppColor.primaryColor,

//           value: value,
//           onChanged: onChanged,
//           isExpanded: true,
//           underline: const SizedBox(),
//           items:
//               items.map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value, style: TextStyle(color: AppColor.white)),
//                 );
//               }).toList(),
//         ),
//       ),
//     ],
//   );
// }
