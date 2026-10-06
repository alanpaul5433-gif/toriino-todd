import 'package:awesome_calendart/awesome_calendart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/repository/earnings_repo.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/services/stripe_service.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailabilityView extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final double hourlyRate;

  const AvailabilityView({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.hourlyRate,
  });

  @override
  State<AvailabilityView> createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<AvailabilityView> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _sessionType = 'Seat';
  bool _splitPayment = false;

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
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
                      onTap:()=> Navigator.pop(context),
                      child: SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg")),
                    SizedBox(width: Responsive.w(2)),
                    Text(
                      'Set Your Availability',
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
                  'Choose the days and time slots when you’re available to take sessions.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,

                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                Text(
                  'Select Preferred Date',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                  padding: EdgeInsets.all(5),
                  child: AwesomeCalenDart(theme: DarkTheme()),
                ),
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
                SizedBox(height: Responsive.h(1)),

                // Session Type
                _buildDropdownField(
                  value: _sessionType,
                  items: const ['Seat', 'Group', 'Workshop'],
                  onChanged: (value) {
                    setState(() {
                      _sessionType = value!;
                    });
                  },
                ),

                SizedBox(height: Responsive.h(1)),

                // Split Payment
                _buildSwitchField(
                  label: 'Split payment with participants?',
                  value: _splitPayment,
                  onChanged: (value) {
                    setState(() {
                      _splitPayment = value;
                    });
                  },
                ),
                SizedBox(height: Responsive.h(1)),

                // Invite Participants Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColor.white),
                    // color: AppColor.white.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Invite Participants',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 14,

                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(1)),

                GestureDetector(
                  onTap: () {
                    _bookSessionBottomSheet(
                      context,
                      mentorId: widget.mentorId,
                      mentorName: widget.mentorName,
                      hourlyRate: widget.hourlyRate,
                      startTime: _startTime,
                    );
                  },
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

  Widget _buildTimeField({
    required TimeOfDay? time,
    required VoidCallback onTap,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColor.white.withValues(alpha: 0.08),
              border: Border.all(color: AppColor.white.withValues(alpha: 0.0)),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              time != null ? _formatTimeOfDay(time) : hint,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: time != null ? AppColor.white : AppColor.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColor.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
          ),
          child: DropdownButton<String>(
            dropdownColor: AppColor.primaryColor,

            value: value,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            items:
                items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.dmSans(color: AppColor.white),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // Widget _buildTextField({
  //   required String label,
  //   required String value,
  //   required ValueChanged<String> onChanged,
  //   required String hint,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: GoogleFonts.dmSans(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       TextField(
  //         onChanged: onChanged,
  //         decoration: InputDecoration(
  //           hintText: hint,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: BorderSide(color: Colors.grey.shade300),
  //           ),
  //           contentPadding: const EdgeInsets.all(16),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildNumberField({
  //   required String label,
  //   required int value,
  //   required ValueChanged<int> onChanged,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: GoogleFonts.dmSans(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.symmetric(horizontal: 16),
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey.shade300),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Row(
  //           children: [
  //             IconButton(
  //               icon: const Icon(Icons.remove),
  //               onPressed: () {
  //                 if (value > 1) {
  //                   onChanged(value - 1);
  //                 }
  //               },
  //             ),
  //             Expanded(
  //               child: Text(
  //                 value.toString(),
  //                 textAlign: TextAlign.center,
  //                 style: GoogleFonts.dmSans(fontSize: 16),
  //               ),
  //             ),
  //             IconButton(
  //               icon: const Icon(Icons.add),
  //               onPressed: () {
  //                 onChanged(value + 1);
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColor.white.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,

                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.20,
                  ),
                ),
              ),
            ),
            Switch(
              splashRadius: 9.5,
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColor.white,
              activeTrackColor: AppColor.red,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // void _showInviteDialog() {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Invite Participants'),
  //           content: const Text(
  //             'This would open your contact list to select participants to invite.',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         ),
  //   );
  // }
}

void _bookSessionBottomSheet(
  BuildContext context, {
  required String mentorId,
  required String mentorName,
  required double hourlyRate,
  TimeOfDay? startTime,
}) async {
  double walletBalance = 0.0;
  try {
    final summary = await EarningsRepo().getEarningsSummary();
    walletBalance = (summary['availableBalance'] as num?)?.toDouble() ?? 0.0;
  } catch (_) {}

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        bool paying = false;
        // Session is created BEFORE Stripe payment so the real UUID is
        // available in Stripe metadata. The webhook then uses it to confirm
        // the session and credit mentor earnings. On cancel/failure the
        // pre-created session is marked 'cancelled'.
        void pay() async {
          if (paying) return;
          setSheetState(() => paying = true);

          // Build scheduled datetime from selected time (or now)
          final now = DateTime.now();
          final DateTime scheduledAt = startTime != null
              ? DateTime(now.year, now.month, now.day,
                  startTime.hour, startTime.minute)
              : now;

          // Step 1: Create the session — get the real UUID back.
          String? realSessionId;
          try {
            final studentId = await AuthService.getUserId();
            final bookResult = await SessionRepo().bookSession({
              'mentorId': mentorId,
              'studentId': studentId ?? '',
              'dateTime': scheduledAt.toIso8601String(),
              'duration': 60,
              'price': hourlyRate,
              'sessionType': 'one-on-one',
            });
            if (bookResult is Map) {
              realSessionId = (bookResult['sessionId'] ??
                  bookResult['session']?['sessionId']) as String?;
            }
          } catch (e) {
            if (!sheetContext.mounted) return;
            setSheetState(() => paying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not create session: $e')),
            );
            return;
          }

          if (realSessionId == null) {
            if (!sheetContext.mounted) return;
            setSheetState(() => paying = false);
            Utils.toastMassage('Session setup failed. Please try again.');
            return;
          }

          // Step 2: Charge the student. Real sessionId + mentorId go into
          // Stripe metadata so the webhook can confirm and credit earnings.
          final result = await StripeService.payForSession(
            sessionId: realSessionId,
            mentorId: mentorId,
            mentorName: mentorName,
            price: hourlyRate,
          );

          if (!sheetContext.mounted) return;
          setSheetState(() => paying = false);

          if (result['success'] == true) {
            Navigator.pop(sheetContext);
            _showPaymentAlert(context);
          } else {
            // Payment cancelled or failed — mark the pre-created session cancelled.
            try {
              await SessionRepo().updateSessionStatus(realSessionId, 'cancelled');
            } catch (_) {}
            Utils.toastMassage(result['message'] ?? 'Payment failed');
          }
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: Responsive.w(5),
            right: Responsive.w(5),
            top: Responsive.h(3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Icon(Icons.close, color: AppColor.white),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColor.secconderyColor,
                        child: Icon(Icons.person, color: AppColor.white),
                      ),
                      SizedBox(width: Responsive.textScaleFactor * 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Mentor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            mentorName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              const Divider(color: Colors.grey),
              SizedBox(height: Responsive.h(2)),
              _cousreinfo("Session Type", "1-on-1"),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Duration", "1h"),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Price", "\$${hourlyRate.toStringAsFixed(2)}"),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Platform Fee", "\$4.99"),
              SizedBox(height: Responsive.h(1)),
              // TODO(P5-3): When wallet-deduction Lambda is ready, charge only the shortfall
              // and deduct walletBalance from the wallet endpoint before calling Stripe.
              if (walletBalance > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Wallet Balance', style: TextStyle(color: Colors.grey[400])),
                    Text('\$${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                if (walletBalance >= hourlyRate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Full amount covered by wallet',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  )
                else
                  Text(
                    'Card charge: \$${(hourlyRate - walletBalance).toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                const SizedBox(height: 12),
              ],
              AuthButton(
                buttontext: "Proceed to Payment",
                onPress: pay,
                loading: paying,
              ),
              SizedBox(height: Responsive.h(2)),
            ],
          ),
        );
      },
    ),
  );
}

Widget _cousreinfo(String text1, String text2) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        text1,
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.textScaleFactor * 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      Text(
        text2,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.textScaleFactor * 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

void _showPaymentAlert(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/icons/checkmark-circle-02.svg"),
              SizedBox(height: Responsive.h(1)),
              Text(
                "Session booked!",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Responsive.h(1)),
              Text(
                'Your session has been booked successfully. You\'ll receive a confirmation shortly.',
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 16,
                ),
              ),
              SizedBox(height: Responsive.h(5)),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
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
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Got It",
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
              ),
            ],
          ),
        ),
      );
    },
  );
}
