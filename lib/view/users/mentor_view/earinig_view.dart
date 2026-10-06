import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_earnings_viewmodel.dart';
import 'package:toriino_todd/view/widgets/withdraw_sheet.dart';
import 'package:toriino_todd/widgets/components/drop_down_text.dart';
import 'package:google_fonts/google_fonts.dart';

class EarinigView extends StatefulWidget {
  const EarinigView({super.key});

  @override
  State<EarinigView> createState() => _EarinigViewState();
}

class _EarinigViewState extends State<EarinigView> {
  String _historyFilter = 'All';

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    final MentorEarningsViewmodel earningsVm = Get.put(MentorEarningsViewmodel());
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: Responsive.padding(left: 1, right: 1, top: 1),
          child: ListView(
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
                              'Earnings',
                              style: GoogleFonts.rethinkSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 18,
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
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset('assets/icons/time.svg'),
                        ),
                      ),
                      SizedBox(width: Responsive.w(2)),

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
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/icons/notification.svg',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(2)),
                      GestureDetector(
                        onTap:
                            customDrawerController
                                .advancedDrawerController
                                .toggleDrawer,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.backGroundColor.withValues(
                              alpha: 0.1,
                            ),
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
                  // In your build method:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // Align to right if needed
                    children: [
                      Obx(() {
                        final summary = earningsVm.rxSummary.value.data;
                        final total = summary?.totalEarnings ?? 0.0;
                        final withdrawn = summary?.totalWithdrawn ?? 0.0;
                        final available = (total - withdrawn).clamp(0.0, double.infinity);
                        return GestureDetector(
                          onTap: () => showWithdrawSheet(
                            context,
                            availableBalance: available,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColor.red,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: Responsive.padding(
                                left: 1.5,
                                right: 1.5,
                                top: 0.5,
                                bottom: 0.5,
                              ),
                              child: Text(
                                'Withdraw',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.textScaleFactor * 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 1.80,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      SortByDropdown(),
                    ],
                  ),

                  // Or as a standalone widget:

                  //this Mouth ,Total Withdrawn
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColor.white.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Column(
                              spacing: Responsive.h(1),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Month',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                                Obx(() {
                                  final summary = earningsVm.rxSummary.value.data;
                                  final amount = summary?.currentMonth.amount ?? 0.0;
                                  return Text(
                                    '\$${amount.toStringAsFixed(2)}',
                                    style: GoogleFonts.rethinkSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 25,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(1)),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColor.white.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Column(
                              spacing: Responsive.h(1),

                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Withdrawn',
                                  style: GoogleFonts.rethinkSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.20,
                                  ),
                                ),
                                Obx(() {
                                  final summary = earningsVm.rxSummary.value.data;
                                  final withdrawn = summary?.totalWithdrawn ?? 0.0;
                                  return Text(
                                    '\$${withdrawn.toStringAsFixed(2)}',
                                    style: GoogleFonts.rethinkSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 25,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.h(1)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: Responsive.padding(
                              left: 2,
                              right: 2,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Remaining Balance',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.20,
                                      ),
                                    ),
                                    Obx(() {
                                      final summary = earningsVm.rxSummary.value.data;
                                      final total = summary?.totalEarnings ?? 0.0;
                                      final withdrawn = summary?.totalWithdrawn ?? 0.0;
                                      return Text(
                                        '\$${(total - withdrawn).toStringAsFixed(2)}',
                                        style: GoogleFonts.rethinkSans(
                                          color: Colors.white,
                                          fontSize: Responsive.textScaleFactor * 25,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(1)),

                  Text(
                    'Recent Sessions History',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                  SizedBox(height: Responsive.h(1)),

                  Row(
                    spacing: 5,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _historyFilter = 'All'),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: _historyFilter == 'All'
                                ? AppColor.red
                                : AppColor.primaryColor,
                            border: _historyFilter == 'All'
                                ? null
                                : Border.all(color: AppColor.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              'All',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _historyFilter = 'Sessions'),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: _historyFilter == 'Sessions'
                                ? AppColor.red
                                : AppColor.primaryColor,
                            border: _historyFilter == 'Sessions'
                                ? null
                                : Border.all(color: AppColor.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              'Sessions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _historyFilter = 'Withdrawals'),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: _historyFilter == 'Withdrawals'
                                ? AppColor.red
                                : AppColor.primaryColor,
                            border: _historyFilter == 'Withdrawals'
                                ? null
                                : Border.all(color: AppColor.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              'Withdrawals',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(1)),
                  Obx(() {
                    final allEntries = earningsVm.rxHistory.value.data ?? [];
                    final filtered = _historyFilter == 'All'
                        ? allEntries
                        : allEntries.where((e) {
                            if (_historyFilter == 'Sessions') return (e.type ?? '') == 'session';
                            if (_historyFilter == 'Withdrawals') return (e.type ?? '') == 'withdrawal';
                            return true;
                          }).toList();
                    if (filtered.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: Responsive.h(2)),
                        child: Text(
                          'No earnings history yet.',
                          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: Responsive.sp(12)),
                        ),
                      );
                    }
                    return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: ((context, index) {
                      final entry = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColor.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColor.white.withValues(
                                                alpha: 0.20,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: SvgPicture.asset(
                                                "assets/icons/Vector (10).svg",
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: Responsive.w(1)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.periodKey ?? '',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Responsive
                                                          .textScaleFactor *
                                                      12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                '${entry.sessions ?? 0} sessions',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Responsive
                                                          .textScaleFactor *
                                                      12,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: -0.20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '\$${(entry.amount ?? 0).toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.rethinkSans(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 25,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
