import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveSubcribtionView extends StatelessWidget {
  const ActiveSubcribtionView({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
                SizedBox(width: Responsive.w(2)),
                Text(
                  'Subscription',
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
              'Active Plan',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: Responsive.textScaleFactor * 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Responsive.h(2)),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: AppColor.white.withValues(alpha: 0.08),
              ),
              child: Padding(
                padding: Responsive.padding(
                  left: 4,
                  right: 4,
                  top: 2,
                  bottom: 2,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.white.withValues(alpha: 0.10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              "assets/icons/mdi_gold.svg",
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(4)),
                        Column(
                          children: [
                            Text(
                              'Monthly – \$9.99/mo',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Next Billing: June 15, 2025',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 10,
                                fontWeight: FontWeight.w400,
                                height: 1.80,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: AppColor.red,
                            ),
                            child: Padding(
                              padding: Responsive.padding(top: 1, bottom: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Text(
                                    'Upgrade Plan',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  SvgPicture.asset("assets/icons/vector.svg"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(2)),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: AppColor.white.withValues(alpha: 0.20),
                            ),
                            child: Padding(
                              padding: Responsive.padding(top: 1, bottom: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Cancel',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  SvgPicture.asset("assets/icons/vector.svg"),
                                ],
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
          ],
        ),
      ),
    );
  }
}
