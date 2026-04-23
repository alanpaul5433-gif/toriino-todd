import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_public_profile.dart';
import 'package:toriino_todd/view/users/student_view/availability_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:toriino_todd/viewmodel/controller/student/mentor_list_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseMentor extends StatelessWidget {
  BrowseMentor({super.key});

  final MentorListViewmodel mentorController = Get.put(MentorListViewmodel());

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
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
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              "Browse Mentor",
                              style: TextStyle(
                                color: AppColor.secconderyColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/icons/notification.svg',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () {
                      return customDrawerController.toggleDrawer();
                    },
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
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "Search by name, topic, or skill",
                        hintStyle: TextStyle(
                          color: AppColor.secconderyColor,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColor.secconderyColor,
                        ),
                        filled: true,
                        fillColor: AppColor.backGroundColor.withValues(
                          alpha: 0.1,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () => _filterBottomSheet(context),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.red,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/icons/filter.svg'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              Flexible(
                child: Obx(() {
                  final response = mentorController.rxMentors.value;
                  if (response.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (response.status == Status.error) {
                    return Center(child: Text('Error loading mentors', style: TextStyle(color: AppColor.white)));
                  }
                  final mentors = response.data?.mentors ?? [];
                  return ListView.builder(
                  itemCount: mentors.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColor.white.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 5,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundImage: AssetImage(
                                          "assets/icons/Frame 1171275882.png",
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 10,
                                        children: [
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/material-symbols_star (1).svg",
                                              ),
                                              Text(
                                                "${mentors[index].rating ?? 0}",
                                                style: GoogleFonts.dmSans(
                                                  color: AppColor.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: Responsive.sp(12),
                                                ),
                                              ),
                                            ],
                                          ),

                                          Text(
                                            mentors[index].name ?? 'Mentor',
                                            style: GoogleFonts.dmSans(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,  fontSize: Responsive.sp(12),
                                            ),
                                          ),
                                          Text(
                                            (mentors[index].expertise != null && mentors[index].expertise!.isNotEmpty) ? mentors[index].expertise!.first : 'Expert',
                                            style: GoogleFonts.dmSans(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,  fontSize: Responsive.sp(12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SvgPicture.asset(
                                    "assets/icons/bitcoin-icons_verify-filled.svg",
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),

                              Text(
                                mentors[index].bio ?? '',
                                style: GoogleFonts.dmSans(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: Responsive.sp(10),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset("assets/icons/mic.svg"),
                                      Text(
                                        'English, German',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 10,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.20,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '\$${mentors[index].hourlyRate?.toInt() ?? 0}/',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.20,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.20,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'hr',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                Responsive.textScaleFactor * 12,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -0.20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => MentorPublicProfile(),
                                            ),
                                          ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          color: AppColor.red,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            spacing: 2,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "View Profile",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: Responsive.sp(10),
                                                  color: AppColor.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SvgPicture.asset(
                                                "assets/icons/arrow.svg",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.w(4)),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => AvailabilityView(),
                                            ),
                                          ),

                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          color: AppColor.white.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Book Session",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: Responsive.sp(10),
                                                  color: AppColor.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
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
                  }),
                );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _filterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filters",
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close, color: AppColor.white),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(2)),
            //  DropdownButtonFormField<String>(
            //     iconEnabledColor: AppColor.white,
            //     dropdownColor: AppColor.primaryColor,
            //     style: GoogleFonts.rethinkSans(
            //       color: AppColor.white,
            //       fontWeight: FontWeight.w500,
            //     ),
            //     decoration: InputDecoration(
            //       filled: true,
            //       fillColor: AppColor.white.withValues(alpha: 0.08),
            //       enabledBorder: UnderlineInputBorder(
            //         // borderSide: BorderSide(color: AppColor.white),
            //         borderRadius: BorderRadius.circular(28),
            //       ),
            //       focusedBorder: OutlineInputBorder(
            //         borderSide: BorderSide(color: AppColor.red),
            //         borderRadius: BorderRadius.circular(28),
            //       ),

            //       hint: Padding(
            //         padding: const EdgeInsets.symmetric(vertical: 12.0),
            //         child: Text(
            //           'Course Level',
            //           style: GoogleFonts.dmSans(
            //             color: Colors.white,
            //             fontSize: Responsive.textScaleFactor * 12,
            //             fontWeight: FontWeight.w400,
            //             letterSpacing: -0.20,
            //           ),
            //         ),
            //       ),
            //     ),
            //     value: courselevel,
            //     items:
            //         courseLevels.map((String language) {
            //           return DropdownMenuItem<String>(
            //             value: language,
            //             child: Text(
            //               language,
            //               style: GoogleFonts.dmSans(
            //                 color: Colors.white,
            //                 fontSize: Responsive.textScaleFactor * 16,
            //                 fontWeight: FontWeight.w400,
            //                 letterSpacing: -0.20,
            //               ),
            //             ),
            //           );
            //         }).toList(),
            //     onChanged: (String? newValue) {
            //       setState(() {
            //         courselevel = newValue;
            //       });
            //     },
            //     validator:
            //         (value) =>
            //             value == null ? 'Please select course levels' : null,
            //   ),
            SizedBox(height: Responsive.h(1)),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColor.secconderyColor,
                  child: Icon(Icons.person, color: AppColor.white),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chance Calzoni',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Teacher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: Responsive.h(2)),
            const Divider(color: Colors.grey),
            SizedBox(height: Responsive.h(2)),
            _cousreinfo("Course Category", "Design"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Course Duration", "2–5h"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Language", "English"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Rating", "4.5"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Price Info", "\$19.99"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Platform Fee", "\$4.99"),
            SizedBox(height: Responsive.h(2)),
            Text(
              "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            SizedBox(height: Responsive.h(2)),
            AuthButton(
              buttontext: "Apply",
              onPress: () {
                Navigator.pop(context); // Close the bottom sheet
              },
              loading: false,
            ),
            SizedBox(height: Responsive.h(2)),
          ],
        ),
      );
    },
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
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
      Text(
        text2,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
