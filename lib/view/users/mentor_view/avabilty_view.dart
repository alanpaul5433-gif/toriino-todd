import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/Mentor_Subcirption_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final List<bool> _selectedDays = List.filled(7, false);
  bool _sameTimingForAll = false;

  final List<TimeOfDay> _startTimes = List.generate(
    7,
    (_) => const TimeOfDay(hour: 9, minute: 0),
  );
  final List<TimeOfDay> _endTimes = List.generate(
    7,
    (_) => const TimeOfDay(hour: 18, minute: 0),
  );

  int _minStudents = 1;
  int _maxStudents = 10;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Responsive.h(1)),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     GestureDetector(
              //       onTap: () => Navigator.of(context).pop(),
              //       child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
              //     ),
              //   ],
              // ),
              SizedBox(height: Responsive.h(1)),

              Text(
                'Set Your Availability',
                style: TextStyle(
                  fontSize: Responsive.textScaleFactor * 30,
                  color: AppColor.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: Responsive.h(1)),

              // Days of week selector - Fixed toggle logic
              Center(
                child: Wrap(
                  spacing: 8.0,
                  children: List.generate(7, (index) {
                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDays[index] = !_selectedDays[index];
                        });
                      },
                      child: Container(
                        width: Responsive.h(5),
                        height: Responsive.h(5),
                        decoration: BoxDecoration(
                          color:
                              _selectedDays[index]
                                  ? AppColor.white.withValues(alpha: 0.08)
                                  : AppColor.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _selectedDays[index]
                                    ? AppColor.red
                                    : AppColor.white.withValues(alpha: 0.08),
                            width: _selectedDays[index] ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            style: GoogleFonts.rethinkSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: Responsive.h(2)),

              // Same timing toggle
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColor.white.withValues(alpha: 0.08),
                ),
                child: Padding(
                  padding: Responsive.padding(left: 2, right: 2),
                  child: Row(
                    children: [
                      Text(
                        'Use same timing for all days?',
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.white,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        splashRadius: 4,
                        value: _sameTimingForAll,
                        onChanged: (value) {
                          setState(() {
                            _sameTimingForAll = value;
                            if (value) {
                              // Apply first day's timing to all days
                              for (int i = 1; i < 7; i++) {
                                _startTimes[i] = _startTimes[0];
                                _endTimes[i] = _endTimes[0];
                              }
                            }
                          });
                        },
                        activeThumbColor: AppColor.red,
                        // activeColor: AppColor.red,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Responsive.h(1)),

              // Day time selectors
              _buildDayTimeRow('Monday', 0),
              _buildDayTimeRow('Tuesday', 1),
              _buildDayTimeRow('Wednesday', 2),
              _buildDayTimeRow('Thursday', 3),
              _buildDayTimeRow('Friday', 4),
              _buildDayTimeRow('Saturday', 5),
              _buildDayTimeRow('Sunday', 6),

              SizedBox(height: Responsive.h(1)),

              // Students limit
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppColor.white.withValues(alpha: 0.08),
                ),
                child: Padding(
                  padding: Responsive.padding(left: 2, right: 2),
                  child: Row(
                    children: [
                      Text(
                        'Students limit per session',
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.white,
                        ),
                      ),
                      // Text(
                      //   'Min',
                      //   style: TextStyle(
                      //     fontWeight: FontWeight.w500,
                      //     color: AppColor.white,
                      //   ),
                      // ),
                      // const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          child: TextFormField(
                            initialValue: _minStudents.toString(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                _minStudents = int.tryParse(value) ?? 0;
                              });
                            },
                            style: TextStyle(color: AppColor.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: Responsive.w(0.5),
                        height: Responsive.h(4),
                        color: AppColor.white,
                      ),
                      Expanded(
                        child: SizedBox(
                          child: TextFormField(
                            initialValue: _maxStudents.toString(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                _maxStudents = int.tryParse(value) ?? 0;
                              });
                            },
                            style: TextStyle(color: AppColor.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.h(2)),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap:
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MentorSubcirptionView(),
                          ),
                        ),
                    child: Container(
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
                              "Continue",
                              style: GoogleFonts.dmSans(
                                fontSize: Responsive.textScaleFactor * 14,
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

              // Save button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       // Save availability logic
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.blue[700],
              //       foregroundColor: Colors.white,
              //       padding: const EdgeInsets.symmetric(vertical: 16),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: const Text(
              //       'Save Availability',
              //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayTimeRow(String day, int dayIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          //days
          SizedBox(
            width: Responsive.w(20),
            child: Text(
              day,
              style: TextStyle(
                fontSize: Responsive.textScaleFactor * 12,
                color: AppColor.white,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: AppColor.white.withValues(alpha: 0.08),
            ),
            child: Padding(
              padding: Responsive.padding(left: 2, right: 0),
              child: Row(
                children: [
                  Text(
                    'From',
                    style: GoogleFonts.dmSans(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _startTimes[dayIndex],
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
                          _startTimes[dayIndex] = picked;
                          if (_sameTimingForAll) {
                            for (int i = 0; i < 7; i++) {
                              _startTimes[i] = picked;
                            }
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      // decoration: BoxDecoration(
                      //   color: AppColor.white.withOpacity(0.1),
                      //   border: Border.all(color:Colors.transparent),
                      //   borderRadius: BorderRadius.circular(4),
                      // ),
                      child: Text(
                        _formatTime(_startTimes[dayIndex]),
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: Responsive.w(2)),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: AppColor.white.withValues(alpha: 0.08),
            ),
            child: Padding(
              padding: Responsive.padding(left: 2, right: 0),
              child: Row(
                children: [
                  Text(
                    'To',
                    style: TextStyle(
                      fontSize: Responsive.textScaleFactor * 12,
                      color: AppColor.white,
                    ),
                  ),
                  SizedBox(width: Responsive.w(2)),
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _endTimes[dayIndex],
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: AppColor.red,
                                onPrimary: AppColor.white,
                                surface: AppColor.primaryColor,
                                onSurface: AppColor.white,
                              ),
                              dialogTheme: DialogThemeData(
                                backgroundColor: AppColor.primaryColor,
                              ),
                              //  dialogBackgroundColor : AppColor.primaryColor,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _endTimes[dayIndex] = picked;
                          if (_sameTimingForAll) {
                            for (int i = 0; i < 7; i++) {
                              _endTimes[i] = picked;
                            }
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        _formatTime(_endTimes[dayIndex]),
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}












// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:toriino_todd/resources/colors/app_colors.dart';
// import 'package:toriino_todd/utils/responsive.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AvailabilityScreen extends StatefulWidget {
//   const AvailabilityScreen({super.key});

//   @override
//   State<AvailabilityScreen> createState() => _AvailabilityScreenState();
// }

// class _AvailabilityScreenState extends State<AvailabilityScreen> {
//   final List<bool> _selectedDays = List.filled(7, false);
//   bool _sameTimingForAll = false;

//   final List<TimeOfDay> _startTimes = List.generate(
//     7,
//     (_) => const TimeOfDay(hour: 9, minute: 0),
//   );
//   final List<TimeOfDay> _endTimes = List.generate(
//     7,
//     (_) => const TimeOfDay(hour: 18, minute: 0),
//   );

//   int _minStudents = 1;
//   int _maxStudents = 10;

//   @override
//   Widget build(BuildContext context) {
//     Responsive.init(context);
//     return Scaffold(
//       backgroundColor: AppColor.primaryColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: Responsive.h(1)),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
//                 ],
//               ),
//               SizedBox(height: Responsive.h(1)),

//               Text(
//                 'Set Your Availability',
//                 style: TextStyle(
//                   fontSize: 30,
//                   color: AppColor.white,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               SizedBox(height: Responsive.h(1)),
//               // Days of week selector
//               Center(
//                 child: Wrap(
//                   runSpacing: 8.0,
//                   spacing: 8.0,
//                   children: List.generate(7, (index) {
//                     final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
//                     return GestureDetector(
//                       onTap: () {
//                         return setState(() {
//                           if (_selectedDays[index] = true) {
//                             _selectedDays[index] = false;
//                           } 
//                         });
//                       },
//                       child: Container(
//                         width: Responsive.h(6),
//                         height: Responsive.h(6),
//                         decoration: BoxDecoration(
//                           color: AppColor.white.withValues(alpha: 0.08),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color:
//                                 _selectedDays[index]
//                                     ? AppColor.white
//                                     : AppColor.red,
//                           ),
//                         ),
//                         child: Center(
//                           child: Text(
//                             days[index],
//                             style: GoogleFonts.rethinkSans(
//                               color: Colors.white,
//                               fontSize: Responsive.textScaleFactor * 20,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               // Same timing toggle
//               Row(
//                 children: [
//                   const Text(
//                     'Use same timing for all days?',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                   const Spacer(),
//                   Switch(
//                     value: _sameTimingForAll,
//                     onChanged: (value) {
//                       setState(() {
//                         _sameTimingForAll = value;
//                         if (value) {
//                           // Apply first day's timing to all days
//                           for (int i = 1; i < 7; i++) {
//                             _startTimes[i] = _startTimes[0];
//                             _endTimes[i] = _endTimes[0];
//                           }
//                         }
//                       });
//                     },
//                     activeColor: Colors.blue[700],
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 16),

//               // Day time selectors
//               _buildDayTimeRow('Monday', 0),
//               _buildDayTimeRow('Tuesday', 1),
//               _buildDayTimeRow('Wednesday', 2),
//               _buildDayTimeRow('Thursday', 3),
//               _buildDayTimeRow('Friday', 4),
//               _buildDayTimeRow('Saturday', 5),
//               _buildDayTimeRow('Sunday', 6),

//               const SizedBox(height: 24),

//               // Students limit
//               const Text(
//                 'Students limit per session',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               ),

//               const SizedBox(height: 12),

//               Row(
//                 children: [
//                   const Text(
//                     'Min',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(width: 8),
//                   SizedBox(
//                     width: 80,
//                     child: TextFormField(
//                       initialValue: _minStudents.toString(),
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       onChanged: (value) {
//                         setState(() {
//                           _minStudents = int.tryParse(value) ?? 1;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const Spacer(),

//                   const Text(
//                     'Max',
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(width: 8),
//                   SizedBox(
//                     width: 80,
//                     child: TextFormField(
//                       initialValue: _maxStudents.toString(),
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       onChanged: (value) {
//                         setState(() {
//                           _maxStudents = int.tryParse(value) ?? 10;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 32),

//               // Save button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Save availability logic
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[700],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Save Availability',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDayTimeRow(String day, int dayIndex) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 90,
//             child: Text(day, style: const TextStyle(fontSize: 16)),
//           ),
//           const SizedBox(width: 8),
//           const Text('From', style: TextStyle(color: Colors.grey)),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: () async {
//               final TimeOfDay? picked = await showTimePicker(
//                 context: context,
//                 initialTime: _startTimes[dayIndex],
//                 builder: (BuildContext context, Widget? child) {
//                   return Theme(
//                     data: ThemeData.light().copyWith(
//                       colorScheme: const ColorScheme.light(
//                         primary: Colors.blue,
//                       ),
//                     ),
//                     child: child!,
//                   );
//                 },
//               );
//               if (picked != null) {
//                 setState(() {
//                   _startTimes[dayIndex] = picked;
//                   if (_sameTimingForAll) {
//                     for (int i = 0; i < 7; i++) {
//                       _startTimes[i] = picked;
//                     }
//                   }
//                 });
//               }
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 _formatTime(_startTimes[dayIndex]),
//                 style: const TextStyle(fontSize: 16),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           const Text('To', style: TextStyle(color: Colors.grey)),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: () async {
//               final TimeOfDay? picked = await showTimePicker(
//                 context: context,
//                 initialTime: _endTimes[dayIndex],
//                 builder: (BuildContext context, Widget? child) {
//                   return Theme(
//                     data: ThemeData.light().copyWith(
//                       colorScheme: const ColorScheme.light(
//                         primary: Colors.blue,
//                       ),
//                     ),
//                     child: child!,
//                   );
//                 },
//               );
//               if (picked != null) {
//                 setState(() {
//                   _endTimes[dayIndex] = picked;
//                   if (_sameTimingForAll) {
//                     for (int i = 0; i < 7; i++) {
//                       _endTimes[i] = picked;
//                     }
//                   }
//                 });
//               }
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 _formatTime(_endTimes[dayIndex]),
//                 style: const TextStyle(fontSize: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatTime(TimeOfDay time) {
//     final hour = time.hourOfPeriod;
//     final minute = time.minute.toString().padLeft(2, '0');
//     final period = time.period == DayPeriod.am ? 'AM' : 'PM';
//     return '$hour:$minute $period';
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_svg/svg.dart';
// // import 'package:toriino_todd/resources/colors/app_colors.dart';
// // import 'package:toriino_todd/utils/responsive.dart';

// // class AvabiltyView extends StatelessWidget {
// //   const AvabiltyView({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     Responsive.init(context);

// //     return Scaffold(
// //       body: Column(
// //         children: [
// //           SizedBox(height: Responsive.h(1)),

// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.start,
// //             children: [SvgPicture.asset("assets/icons/Arrow - Right 3.svg")],
// //           ),
// //           SizedBox(height: Responsive.h(1)),

// //           Text(
// //             'Set Your Availability',
// //             style: TextStyle(
// //               fontSize: 30,
// //               color: AppColor.white,
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //           SizedBox(height: Responsive.h(10)),
// //         ],
// //       ),
// //     );
// //   }
// // }
