import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/view/users/student_view/edit_profile_view.dart';
import 'package:getxmvvm/view/users/student_view/my_taken_cousre_view.dart';
import 'package:getxmvvm/view/users/student_view/review.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/icons/Arrow - Right 3 (1).svg",
                                ),
                                SizedBox(width: Responsive.w(2)),
                                Text(
                                  'Your Profile',
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

                        Container(
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
                        SizedBox(width: Responsive.w(2)),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     color: AppColor.backGroundColor.withValues(
                        //       alpha: 0.1,
                        //     ),
                        //   ),
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(8.0),
                        //     child: SvgPicture.asset('assets/icons/menu.svg'),
                        //   ),
                        // ),
                      ],
                    ),
                    //Profile Pic Name Domain and Share Icon
                    SizedBox(height: Responsive.h(2)),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: Responsive.w(10),
                              backgroundImage: const AssetImage(
                                "assets/images/michel.png",
                              ),
                            ),
                            SizedBox(width: Responsive.w(2)),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
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
                            color: AppColor.white.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset('assets/icons/share.svg'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),
                    Row(
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
                    ),
                    SizedBox(height: Responsive.h(2)),

                    Text(
                      "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                    SizedBox(height: Responsive.h(2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset("assets/icons/mic.svg"),
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
                    ),
                    SizedBox(height: Responsive.h(2)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentEditProfileView(),
                          ),
                        );
                      },

                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColor.white),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Edit Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.h(2)),
                    //Divider
                    const Row(children: [Expanded(child: Divider())]),
                    SizedBox(height: Responsive.h(2)),
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: AppColor.white.withValues(alpha: 0.08),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Courses in Progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 16,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '03',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 25,
                                          fontFamily: 'Rethink Sans',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: AppColor.white.withValues(alpha: 0.08),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sessions Booked',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 16,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,

                                    children: [
                                      Text(
                                        '02',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 25,
                                          fontFamily: 'Rethink Sans',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: AppColor.white.withValues(alpha: 0.08),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Certificates Earned',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 16,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.20,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,

                                    children: [
                                      Text(
                                        '01',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 25,
                                          fontFamily: 'Rethink Sans',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),

                    //Skill chips
                    Text(
                      'Intro Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: Responsive.h(2)),

                    //video view
                    // Container(
                    //   height: 100,
                    //   width: double.infinity,
                    //   color: AppColor.red,
                    // ),
                    SvgPicture.asset("assets/icons/Frame 1410120834.svg"),
                    SizedBox(height: Responsive.h(2)),

                    //review and view all
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ReviewView()),
                            );
                          },
                          child: Text(
                            'View all',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 10,
                              fontWeight: FontWeight.w400,
                              height: 1.60,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),

                    //comments card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const ShapeDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                  "assets/icons/Ellipse 6.png",
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                              shape: OvalBorder(),
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Jamie Dunn',
                                                style: GoogleFonts.dmSans(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Responsive
                                                          .textScaleFactor *
                                                      14,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: -0.30,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: List.generate(
                                                  5,
                                                  (index) => Container(
                                                    width: 13,
                                                    height: 13,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 2,
                                                        ),
                                                    child: Icon(
                                                      Icons.star,
                                                      color: Colors.white,
                                                      size:
                                                          Responsive
                                                              .textScaleFactor *
                                                          14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '15 Days Ago',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.textScaleFactor * 10,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 325,
                                  child: Text(
                                    "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: Responsive.textScaleFactor * 12,
                                      fontWeight: FontWeight.w400,
                                      height: 1.50,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Courses Offered by Mentor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 12,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sort By: Latest',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 10,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.60,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),
                  ],
                ),
              ),
            ),

            // ListView section as a SliverList
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: AppColor.white.withValues(alpha: 0.08),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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
                                    ),
                                    SizedBox(width: Responsive.w(4)),
                                    Text(
                                      "Course 01",
                                      style: GoogleFonts.dmSans(
                                        color: AppColor.white,
                                        fontSize:
                                            Responsive.textScaleFactor * 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SvgPicture.asset(
                                  "assets/icons/Component 26.svg",
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            Text(
                              "Last seen 2 days ago",
                              style: GoogleFonts.dmSans(
                                fontSize: Responsive.textScaleFactor * 12,
                                color: AppColor.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "UI/UX Design Basics",
                                  style: GoogleFonts.dmSans(
                                    fontSize: Responsive.textScaleFactor * 25,
                                    color: AppColor.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/material-symbols_star (1).svg",
                                    ),
                                    Text(
                                      "4.8",
                                      style: GoogleFonts.dmSans(
                                        color: AppColor.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: AssetImage(
                                        "assets/icons/Ellipse 6.png",
                                      ),
                                    ),
                                    SizedBox(width: 10),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Chance Calzoni",
                                          style: GoogleFonts.dmSans(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Mentor",
                                          style: GoogleFonts.dmSans(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MyTakenCousreView(),
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
                                              fontSize: 14,
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
                              ],
                            ),

                            SizedBox(height: Responsive.h(2)),
                            LinearProgressIndicator(
                              backgroundColor: AppColor.white.withValues(
                                alpha: 0.23,
                              ), // Background color
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColor.white,
                              ), // Progress color
                              value: 0.5, // Set progress to 50%
                            ),
                            SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Completion",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: AppColor.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  "78 %",
                                  style: GoogleFonts.dmSans(
                                    color: AppColor.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Responsive.h(1)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: 4, // Number of list items
              ),
            ),

            // Book session button at the bottom
            // const SliverToBoxAdapter(
            //   child: Padding(
            //     padding: EdgeInsets.all(16.0),
            //     child: BookSessionButton(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// // Extracted book session button widget
// class BookSessionButton extends StatelessWidget {
//   const BookSessionButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(22),
//         color: AppColor.red,
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16.0),
//         child: Text(
//           'Book a session',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontFamily: 'DM Sans',
//             fontWeight: FontWeight.w700,
//             letterSpacing: -0.20,
//           ),
//         ),
//       ),
//     );
//   }
// }
