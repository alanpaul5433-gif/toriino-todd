import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/getx_controllers/advanceddrawercontroller.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentPublicProfileView extends StatelessWidget {
  const StudentPublicProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();

    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Responsive.w(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(customDrawerController, context),
                    SizedBox(height: Responsive.h(2)),
                    _buildProfileHeader(),
                    SizedBox(height: Responsive.h(2)),
                    _buildEducationLevel(),
                    SizedBox(height: Responsive.h(2)),
                    _buildBio(),
                    SizedBox(height: Responsive.h(2)),
                    _buildLanguages(),
                    SizedBox(height: Responsive.h(2)),
                    const Divider(color: Colors.grey),
                    SizedBox(height: Responsive.h(2)),
                    _buildStatsRow(),
                    SizedBox(height: Responsive.h(2)),
                    _buildCourseList(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(CustomDrawerController controller, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
                SizedBox(width: Responsive.w(2)),
                Text(
                  'Student Profile',
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontSize: Responsive.textScaleFactor * 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildIconButton(icon: 'assets/icons/notification.svg', onTap: () {}),
        SizedBox(width: Responsive.w(2)),
        _buildIconButton(
          icon: 'assets/icons/menu.svg',
          onTap: () => controller.toggleDrawer(),
        ),
      ],
    );
  }

  Widget _buildIconButton({required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColor.backGroundColor.withValues(alpha:0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(icon),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: Responsive.w(10),
              backgroundImage: const AssetImage(
                "assets/icons/Ellipse 6 (1).png",
              ),
            ),
            SizedBox(width: Responsive.w(2)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Michel S.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColor.white.withValues(alpha:0.08),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset('assets/icons/share.svg'),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationLevel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Education Level',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.20,
          ),
        ),
        Text(
          'Collage',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.20,
          ),
        ),
      ],
    );
  }

  Widget _buildBio() {
    return Text(
      "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
      style: GoogleFonts.dmSans(
        color: Colors.white,
        fontSize: Responsive.textScaleFactor * 12,
        fontWeight: FontWeight.w400,
        height: 1.50,
      ),
    );
  }

  Widget _buildLanguages() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset("assets/icons/mic.svg"),
            SizedBox(width: Responsive.w(1)),
            Text(
              'English, German',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.textScaleFactor * 10,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Courses in Progress', '03')),
        SizedBox(width: Responsive.w(2)),
        Expanded(child: _buildStatCard('Sessions Booked', '02')),
        SizedBox(width: Responsive.w(2)),
        Expanded(child: _buildStatCard('Certificates Earned', '01')),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColor.white.withValues(alpha:0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.textScaleFactor * 14,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
            SizedBox(height: Responsive.h(1)),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 25,
                  fontFamily: 'Rethink Sans',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder:
          (context, index) => Padding(
            padding: EdgeInsets.only(bottom: Responsive.h(2)),
            child: _buildCourseCard(context),
          ),
    );
  }

  Widget _buildCourseCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColor.white.withValues(alpha:0.08),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.w(2.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Responsive.h(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/Frame 1000002079.svg",
                      colorFilter: ColorFilter.mode(
                        AppColor.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: Responsive.w(1)),
                    Text(
                      "\$19.99",
                      style: TextStyle(
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                        fontSize: Responsive.textScaleFactor * 14,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _enrollBottomSheet(context),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(3),
                        vertical: Responsive.h(1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Details",
                            style: TextStyle(
                              fontSize: Responsive.textScaleFactor * 14,
                              color: AppColor.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: Responsive.w(1)),
                          SvgPicture.asset(
                            "assets/icons/arrow.svg",
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
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
              "Duration: 2–5h",
              style: TextStyle(
                color: AppColor.white,
                fontWeight: FontWeight.w500,
                fontSize: Responsive.textScaleFactor * 14,
              ),
            ),
            SizedBox(height: Responsive.h(1)),
            Text(
              "UI/UX Design Basics",
              style: TextStyle(
                fontSize: Responsive.textScaleFactor * 20,
                color: AppColor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.h(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: Responsive.sp(22),
                      backgroundColor: AppColor.secconderyColor,
                      child: Icon(Icons.person, color: AppColor.white),
                    ),
                    SizedBox(width: Responsive.w(2)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chance Calzoni",
                          style: TextStyle(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.textScaleFactor * 14,
                          ),
                        ),
                        Text(
                          "Mentor",
                          style: TextStyle(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.textScaleFactor * 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColor.white,
                      size: Responsive.sp(16),
                    ),
                    SizedBox(width: Responsive.w(1)),
                    Text(
                      "4.8",
                      style: TextStyle(
                        color: AppColor.white,
                        fontWeight: FontWeight.w500,
                        fontSize: Responsive.textScaleFactor * 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _enrollBottomSheet(BuildContext context) {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "UI/UX Design Basics",
                    style: TextStyle(
                      color: AppColor.white,
                      fontSize: Responsive.textScaleFactor * 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColor.white),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColor.secconderyColor,
                    child: Icon(Icons.person, color: AppColor.white),
                  ),
                  SizedBox(width: Responsive.w(2)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chance Calzoni',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Teacher',
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
              SizedBox(height: Responsive.h(2)),
              const Divider(color: Colors.grey),
              SizedBox(height: Responsive.h(2)),
              _buildCourseInfoRow("Course Category", "Design"),
              SizedBox(height: Responsive.h(1)),
              _buildCourseInfoRow("Course Duration", "2–5h"),
              SizedBox(height: Responsive.h(1)),
              _buildCourseInfoRow("Language", "English"),
              SizedBox(height: Responsive.h(1)),
              _buildCourseInfoRow("Rating", "4.5"),
              SizedBox(height: Responsive.h(1)),
              _buildCourseInfoRow("Price Info", "\$19.99"),
              SizedBox(height: Responsive.h(1)),
              _buildCourseInfoRow("Platform Fee", "\$4.99"),
              SizedBox(height: Responsive.h(2)),
              Text(
                "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.textScaleFactor * 12,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              SizedBox(height: Responsive.h(2)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:getxmvvm/getx_controllers/advanceddrawercontroller%20.dart';
// import 'package:getxmvvm/resources/colors/app_colors.dart';
// import 'package:getxmvvm/utils/responsive.dart';
// import 'package:getxmvvm/view/users/student_view/review.dart';
// import 'package:google_fonts/google_fonts.dart';

// class StudentPublicProfileView extends StatelessWidget {
//   StudentPublicProfileView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final CustomDrawerController customDrawerController =
//         Get.find<CustomDrawerController>();

//     Responsive.init(context);
//     return Scaffold(
//       backgroundColor: AppColor.primaryColor,
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             ListView(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Row(
//                               children: [
//                                 SvgPicture.asset(
//                                   "assets/icons/Arrow - Right 3 (1).svg",
//                                 ),
//                                 SizedBox(width: Responsive.w(2)),
//                                 Text(
//                                   'Student Profile',
//                                   style: GoogleFonts.rethinkSans(
//                                     color: AppColor.white,
//                                     fontSize: Responsive.textScaleFactor * 18,
//                                     fontWeight: FontWeight.w600,
//                                     letterSpacing: -0.20,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: AppColor.backGroundColor.withValues(alpha:0.1),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: SvgPicture.asset(
//                                 'assets/icons/notification.svg',
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: Responsive.w(2)),
//                           GestureDetector(
//                             onTap: () {
//                               return customDrawerController.toggleDrawer();
//                             },

//                             child: Container(
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: AppColor.backGroundColor.withValues(alpha:
//                                   0.1,
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: SvgPicture.asset(
//                                   'assets/icons/menu.svg',
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       //Profile Pic Name Domain and Share Icon
//                       SizedBox(height: Responsive.h(2)),

//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               CircleAvatar(
//                                 radius: Responsive.w(10),
//                                 backgroundImage: const AssetImage(
//                                   "assets/icons/Ellipse 6 (1).png",
//                                 ),
//                               ),
//                               SizedBox(width: Responsive.w(2)),

//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     'Michel S.',
//                                     style: GoogleFonts.dmSans(
//                                       color: Colors.white,
//                                       fontSize: Responsive.textScaleFactor * 18,
//                                       fontWeight: FontWeight.w600,
//                                       letterSpacing: -0.20,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),

//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: AppColor.white.withValues(alpha: 0.08),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: SvgPicture.asset('assets/icons/share.svg'),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: Responsive.h(2)),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,

//                         children: [
//                           Text(
//                             'Education Level',
//                             style: GoogleFonts.dmSans(
//                               color: Colors.white,
//                               fontSize: Responsive.textScaleFactor * 12,
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: -0.20,
//                             ),
//                           ),

//                           Text(
//                             'Collage',
//                             style: GoogleFonts.dmSans(
//                               color: Colors.white,
//                               fontSize: Responsive.textScaleFactor * 12,
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: -0.20,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: Responsive.h(2)),

//                       Text(
//                         "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
//                         style: GoogleFonts.dmSans(
//                           color: Colors.white,
//                           fontSize: Responsive.textScaleFactor * 12,
//                           fontWeight: FontWeight.w400,
//                           height: 1.50,
//                         ),
//                       ),
//                       SizedBox(height: Responsive.h(2)),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               SvgPicture.asset("assets/icons/mic.svg"),
//                               Text(
//                                 'English, German',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: Responsive.textScaleFactor * 10,
//                                   fontFamily: 'DM Sans',
//                                   fontWeight: FontWeight.w400,
//                                   letterSpacing: -0.20,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       SizedBox(height: Responsive.h(2)),
//                       //Divider
//                       const Row(children: [Expanded(child: Divider())]),
//                       SizedBox(height: Responsive.h(2)),
//                       Row(
//                         spacing: 5,
//                         children: [
//                           Expanded(
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(22),
//                                 color: AppColor.white.withValues(alpha: 0.08),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Courses in Progress',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize:
//                                             Responsive.textScaleFactor * 16,
//                                         fontFamily: 'DM Sans',
//                                         fontWeight: FontWeight.w400,
//                                         letterSpacing: -0.20,
//                                       ),
//                                     ),
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.end,
//                                       children: [
//                                         Text(
//                                           '03',
//                                           textAlign: TextAlign.right,
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize:
//                                                 Responsive.textScaleFactor * 25,
//                                             fontFamily: 'Rethink Sans',
//                                             fontWeight: FontWeight.w500,
//                                             letterSpacing: -0.30,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(22),
//                                 color: AppColor.white.withValues(alpha: 0.08),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Sessions Booked',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize:
//                                             Responsive.textScaleFactor * 16,
//                                         fontFamily: 'DM Sans',
//                                         fontWeight: FontWeight.w400,
//                                         letterSpacing: -0.20,
//                                       ),
//                                     ),
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.end,

//                                       children: [
//                                         Text(
//                                           '02',
//                                           textAlign: TextAlign.right,
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize:
//                                                 Responsive.textScaleFactor * 25,
//                                             fontFamily: 'Rethink Sans',
//                                             fontWeight: FontWeight.w500,
//                                             letterSpacing: -0.30,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(22),
//                                 color: AppColor.white.withValues(alpha: 0.08),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Certificates Earned',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize:
//                                             Responsive.textScaleFactor * 16,
//                                         fontFamily: 'DM Sans',
//                                         fontWeight: FontWeight.w400,
//                                         letterSpacing: -0.20,
//                                       ),
//                                     ),
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.end,

//                                       children: [
//                                         Text(
//                                           '01',
//                                           textAlign: TextAlign.right,
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize:
//                                                 Responsive.textScaleFactor * 25,
//                                             fontFamily: 'Rethink Sans',
//                                             fontWeight: FontWeight.w500,
//                                             letterSpacing: -0.30,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: Responsive.h(2)),
//                       //video view
//                       ListView.builder(
//                         shrinkWrap: true,
//                         scrollDirection: NeverScrollableScrollPhysics(),
//                         itemCount: 4,
//                         itemBuilder:
//                             (context, index) => Padding(
//                               padding: Responsive.padding(
//                                 left: 1,
//                                 right: 1,
//                                 bottom: 1,
//                                 top: 1,
//                               ),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(28),
//                                   color: AppColor.white.withValues(alpha:0.08),
//                                 ),
//                                 child: Padding(
//                                   padding: Responsive.padding(
//                                     left: 2.5,
//                                     right: 2.5,
//                                     bottom: 2,
//                                     top: 2,
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       SizedBox(height: Responsive.h(1)),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               SvgPicture.asset(
//                                                 "assets/icons/Frame 1000002079.svg",
//                                                 // Using a placeholder icon
//                                                 colorFilter: ColorFilter.mode(
//                                                   AppColor.white,
//                                                   BlendMode.srcIn,
//                                                 ),
//                                               ),
//                                               SizedBox(width: Responsive.w(1)),
//                                               Text(
//                                                 "\$19.99",
//                                                 style: TextStyle(
//                                                   color: AppColor.white,
//                                                   fontWeight: FontWeight.w500,
//                                                   fontSize:
//                                                       Responsive
//                                                           .textScaleFactor *
//                                                       14,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           GestureDetector(
//                                             onTap: () {
//                                               _enrollBottomSheet(context);
//                                             },
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 borderRadius:
//                                                     BorderRadius.circular(28),
//                                                 color: AppColor.red,
//                                               ),
//                                               child: Padding(
//                                                 padding: Responsive.padding(
//                                                   left: 3,
//                                                   right: 3,
//                                                   bottom: 1,
//                                                   top: 1,
//                                                 ),
//                                                 child: Row(
//                                                   children: [
//                                                     Text(
//                                                       "Details",
//                                                       style: TextStyle(
//                                                         fontSize:
//                                                             Responsive
//                                                                 .textScaleFactor *
//                                                             14,
//                                                         color: AppColor.white,
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                     SizedBox(
//                                                       width: Responsive.w(1),
//                                                     ),
//                                                     SvgPicture.asset(
//                                                       "assets/icons/arrow.svg",
//                                                       // Using a placeholder icon
//                                                       colorFilter:
//                                                           const ColorFilter.mode(
//                                                             Colors.white,
//                                                             BlendMode.srcIn,
//                                                           ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: Responsive.h(1)),
//                                       Text(
//                                         "Duration: 2–5h",
//                                         style: TextStyle(
//                                           color: AppColor.white,
//                                           fontWeight: FontWeight.w500,
//                                           fontSize:
//                                               Responsive.textScaleFactor * 14,
//                                         ),
//                                       ),
//                                       SizedBox(height: 10),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.end,
//                                         children: [
//                                           Text(
//                                             "UI/UX Design Basics",
//                                             style: TextStyle(
//                                               fontSize:
//                                                   Responsive.textScaleFactor *
//                                                   20,
//                                               color: AppColor.white,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: Responsive.h(1)),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.end,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               CircleAvatar(
//                                                 radius: Responsive.sp(22),
//                                                 backgroundColor:
//                                                     AppColor.secconderyColor,
//                                                 child: Icon(
//                                                   Icons.person,
//                                                   color: AppColor.white,
//                                                 ),
//                                               ),
//                                               SizedBox(width: Responsive.w(2)),
//                                               Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     "Chance Calzoni",
//                                                     style: TextStyle(
//                                                       color: AppColor.white,
//                                                       fontWeight:
//                                                           FontWeight.w500,
//                                                       fontSize:
//                                                           Responsive
//                                                               .textScaleFactor *
//                                                           14,
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     "Mentor",
//                                                     style: TextStyle(
//                                                       color: AppColor.white,
//                                                       fontWeight:
//                                                           FontWeight.w500,
//                                                       fontSize:
//                                                           Responsive
//                                                               .textScaleFactor *
//                                                           12,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//                                           Row(
//                                             children: [
//                                               Icon(
//                                                 Icons.star,
//                                                 color: AppColor.white,
//                                                 size: Responsive.sp(16),
//                                               ),
//                                               SizedBox(width: Responsive.w(2)),
//                                               Text(
//                                                 "4.8",
//                                                 style: TextStyle(
//                                                   color: AppColor.white,
//                                                   fontWeight: FontWeight.w500,
//                                                   fontSize:
//                                                       Responsive
//                                                           .textScaleFactor *
//                                                       14,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: Responsive.h(1)),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// void _enrollBottomSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//     ),
//     backgroundColor: AppColor.primaryColor,
//     builder: (context) {
//       return Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           left: Responsive.w(5),
//           right: Responsive.w(5),
//           top: Responsive.h(3),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "UI/UX Design Basics",
//                   style: TextStyle(
//                     color: AppColor.white,
//                     fontSize: Responsive.textScaleFactor * 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                   child: Icon(Icons.close, color: AppColor.white),
//                 ),
//               ],
//             ),
//             SizedBox(height: Responsive.h(2)),
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: AppColor.secconderyColor,
//                   child: Icon(Icons.person, color: AppColor.white),
//                 ),
//                 SizedBox(width: Responsive.w(2)),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Chance Calzoni',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: Responsive.textScaleFactor * 12,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Text(
//                       'Teacher',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: Responsive.textScaleFactor * 12,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: Responsive.h(2)),
//             const Divider(color: Colors.grey),
//             SizedBox(height: Responsive.h(2)),
//             _cousreinfo("Course Category", "Design"),
//             SizedBox(height: Responsive.h(1)),
//             _cousreinfo("Course Duration", "2–5h"),
//             SizedBox(height: Responsive.h(1)),
//             _cousreinfo("Language", "English"),
//             SizedBox(height: Responsive.h(1)),
//             _cousreinfo("Rating", "4.5"),
//             SizedBox(height: Responsive.h(1)),
//             _cousreinfo("Price Info", "\$19.99"),
//             SizedBox(height: Responsive.h(1)),
//             _cousreinfo("Platform Fee", "\$4.99"),
//             SizedBox(height: Responsive.h(2)),
//             Text(
//               "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: Responsive.textScaleFactor * 12,
//                 fontWeight: FontWeight.w400,
//                 height: 1.5,
//               ),
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }

// Widget _cousreinfo(String text1, String text2) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(
//         text1,
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: Responsive.textScaleFactor * 12,
//           fontWeight: FontWeight.w400,
//         ),
//       ),
//       Text(
//         text2,
//         textAlign: TextAlign.right,
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: Responsive.textScaleFactor * 12,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     ],
//   );
// }
