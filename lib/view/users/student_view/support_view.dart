import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/student_view/generate_ticket_view.dart';

class SupportView extends StatelessWidget {
  SupportView({super.key});
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final FocusNode subjectFoucs = FocusNode();
  final FocusNode messageFoucs = FocusNode();
  final FocusNode buttonFoucs = FocusNode();
  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 10,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
                  SizedBox(width: Responsive.w(1)),
                  Text(
                    "Support Ticket",
                    style: TextStyle(
                      fontSize: Responsive.textScaleFactor * 24,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                    color: AppColor.white.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7700),
                              border: BoxBorder.all(
                                color: AppColor.white.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Center(
                                child: Text(
                                  "In-progress",
                                  style: TextStyle(
                                    fontSize: Responsive.textScaleFactor * 12,
                                    color: AppColor.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "12/12/2025",
                            style: TextStyle(
                              fontSize: Responsive.textScaleFactor * 12,
                              color: AppColor.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(1)),
                      Text(
                        "Issue with Job Application Submission",
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 14,
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Responsive.h(1)),
                      Text(
                        "I encountered a problem while trying to submit my job application for the position of Marketing Specialist at XYZ Company. After filling in all the required details and uploading my resume, I clicked the Submit button, but the page froze, and the application did not go through.",
                        style: TextStyle(
                          fontSize: Responsive.textScaleFactor * 12,
                          color: AppColor.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector
              (
                onTap: ()=>  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => CreatenewTicticketView()),
                  ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColor.red,
                    borderRadius: BorderRadius.circular(18),
                    // color: AppColor.white.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Create a ticket',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'DM Sans',
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
    );
  }
}
