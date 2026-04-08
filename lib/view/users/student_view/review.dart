import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      "assets/icons/Arrow - Right 3 (1).svg",
                    ),
                  ),
                  SizedBox(width: Responsive.w(1)),
                  Text(
                    "Reviews",
                    style: GoogleFonts.rethinkSans(
                      fontSize: Responsive.textScaleFactor * 18,
                      color: AppColor.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "4.8",
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 72,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Based on 40 Reviews",
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SizedBox(
                      // color: AppColor.white,
                      child: Column(
                        spacing: 1,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(22),
                                  backgroundColor: AppColor.white.withValues(
                                    alpha: 0.4,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.red,
                                  ), // Progress color
                                  value: 0.5, // Set progress to 50%
                                ),
                              ),
                              SizedBox(width: Responsive.w(1)),
                              Text(
                                "1",
                                style: TextStyle(
                                  fontSize: Responsive.textScaleFactor * 12,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(22),
                                  backgroundColor: AppColor.white.withValues(
                                    alpha: 0.4,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.red,
                                  ), // Progress color
                                  value: 0.9, // Set progress to 50%
                                ),
                              ),
                              Text(
                                "2",
                                style: TextStyle(
                                  fontSize: Responsive.textScaleFactor * 12,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(22),
                                  backgroundColor: AppColor.white.withValues(
                                    alpha: 0.4,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.red,
                                  ), // Progress color
                                  value: 0.3, // Set progress to 50%
                                ),
                              ),
                              SizedBox(width: Responsive.w(1)),
                              Text(
                                "3",
                                style: TextStyle(
                                  fontSize: Responsive.textScaleFactor * 12,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(22),
                                  backgroundColor: AppColor.white.withValues(
                                    alpha: 0.4,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.red,
                                  ), // Progress color
                                  value: 0.7, // Set progress to 50%
                                ),
                              ),
                              SizedBox(width: Responsive.w(1)),
                              Text(
                                "4",
                                style: TextStyle(
                                  fontSize: Responsive.textScaleFactor * 12,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(22),
                                  backgroundColor: AppColor.white.withValues(
                                    alpha: 0.4,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.red,
                                  ), // Progress color
                                  value: 0.2, // Set progress to 50%
                                ),
                              ),
                              SizedBox(width: Responsive.w(1)),
                              Text(
                                "5",
                                style: TextStyle(
                                  fontSize: Responsive.textScaleFactor * 12,
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
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
              Flexible(
                child: ListView.builder(
                  padding: Responsive.padding(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                  ),
                  itemCount: 15,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: Responsive.padding(
                        left: 0,
                        right: 0,
                        top: 0.5,
                        bottom: 0.5,
                      ),
                      child: Container(
                        width: double.infinity,

                        decoration: BoxDecoration(
                          border: BoxBorder.all(
                            color: AppColor.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          color: AppColor.white.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Image(
                                    image: AssetImage(
                                      "assets/icons/Ellipse 6 (1).png",
                                    ),
                                  ),

                                  SizedBox(width: Responsive.w(2)),
                                  Text(
                                    "Ruben ",
                                    style: TextStyle(
                                      color: AppColor.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.sp(10),
                                    ),
                                  ),
                                  Spacer(),
                                  Column(
                                    children: [
                                      Text(
                                        "3h ago",
                                        style: TextStyle(
                                          color: AppColor.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: Responsive.sp(10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.h(1)),
                              Text(
                                "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s",
                                style: TextStyle(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.sp(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
