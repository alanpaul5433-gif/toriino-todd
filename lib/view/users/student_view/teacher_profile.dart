import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherProfile extends StatelessWidget {
  const TeacherProfile({super.key});

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
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            width: Responsive.w(6),
                            height: Responsive.w(6),
                            "assets/icons/Arrow - Right 3 (1).svg",
                          ),

                          SizedBox(width: Responsive.w(2)),
                          Text(
                            'Teacher Profile',
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
                                "assets/images/abram.png",
                              ),
                            ),
                            SizedBox(width: Responsive.w(2)),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Giana Rhiel Madsen',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize:
                                            Responsive.textScaleFactor * 18,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                    SizedBox(width: Responsive.w(2)),

                                    SvgPicture.asset(
                                      'assets/icons/bitcoin-icons_verify-filled (1).svg',
                                    ),
                                  ],
                                ),
                                Text(
                                  'IELTS Expert',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 12,
                                    fontWeight: FontWeight.w400,
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

                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '\$30/',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.textScaleFactor * 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.20,
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.textScaleFactor * 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.20,
                                ),
                              ),
                              TextSpan(
                                text: 'hr',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.textScaleFactor * 12,
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

                    //Divider
                    const Row(children: [Expanded(child: Divider())]),

                    Text(
                      'Expertise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: Responsive.h(2)),

                    //Skill chips
                    Wrap(
                      spacing: 5,
                      runSpacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Data Science',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Machine Learning',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Resume Review',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Career Guidance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(2)),

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
                    //   color: AppColor.white,
                    // ),
                    SvgPicture.asset("assets/icons/Frame 1410120834.svg"),
                    SizedBox(height: Responsive.h(2)),

                    //review and view all
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'View all',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.60,
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
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'DM Sans',
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
                                                      size: 12,
                                                      color: Colors.white,
                                                    ), //
                                                    // decoration:
                                                    // const BoxDecoration(
                                                    //   color: Colors.amber,
                                                    //   shape:
                                                    //       BoxShape.circle,
                                                    // ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '15 Days Ago',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const SizedBox(
                                  width: 325,
                                  child: Text(
                                    "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'DM Sans',
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
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sort By: Latest',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/Frame 1000002079.svg",
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "\$19.99",
                                      style: GoogleFonts.dmSans(
                                        color: AppColor.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
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
                                          "Enroll",
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        SvgPicture.asset(
                                          "assets/icons/arrow.svg",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Text(
                              "Duration: 2–5h",
                              style: GoogleFonts.dmSans(
                                color: AppColor.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "UI/UX Design Basics",
                                  style: GoogleFonts.dmSans(
                                    fontSize: Responsive.textScaleFactor * 18,
                                    color: AppColor.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: const AssetImage(
                                        "assets/icons/Ellipse 6.png",
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Chance Calzoni",
                                          style: GoogleFonts.dmSans(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.w500,
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
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/material-symbols_star (1).svg",
                                    ),
                                    const SizedBox(width: 5),
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

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: 2, // Number of list items
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

// Extracted book session button widget
class BookSessionButton extends StatelessWidget {
  const BookSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColor.red,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Book a session',
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
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:toriino_todd/resources/colors/app_colors.dart';
// import 'package:toriino_todd/utils/responsive.dart';
// import 'package:google_fonts/google_fonts.dart';

// class TeacherProfile extends StatelessWidget {
//   const TeacherProfile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Responsive.init(context);
//     return Scaffold(
//       backgroundColor: AppColor.primaryColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg"),
//                     SizedBox(width: Responsive.w(2)),
//                     Text(
//                       'Teacher Profile',
//                       style: GoogleFonts.rethinkSans(
//                         color: AppColor.white,
//                         fontSize: Responsive.textScaleFactor * 18,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: -0.20,
//                       ),
//                     ),
//                   ],
//                 ),

//                 //Profile Pic Name Domain and Share Icon
//                 SizedBox(height: Responsive.h(2)),

//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,

//                       children: [
//                         CircleAvatar(
//                           radius: Responsive.w(10),
//                           backgroundImage: AssetImage(
//                             "assets/icons/Ellipse 6 (1).png",
//                           ),
//                         ),
//                         SizedBox(width: Responsive.w(2)),

//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Text(
//                                   'Jaylon Culhane',
//                                   style: GoogleFonts.dmSans(
//                                     color: Colors.white,
//                                     fontSize: Responsive.textScaleFactor * 18,
//                                     fontWeight: FontWeight.w500,
//                                     letterSpacing: -0.30,
//                                   ),
//                                 ),
//                                 SizedBox(width: Responsive.w(2)),

//                                 SvgPicture.asset(
//                                   'assets/icons/bitcoin-icons_verify-filled (1).svg',
//                                 ),
//                               ],
//                             ),
//                             Text(
//                               'Data Science Specialist',
//                               style: GoogleFonts.dmSans(
//                                 color: Colors.white,
//                                 fontSize: Responsive.textScaleFactor * 12,
//                                 fontWeight: FontWeight.w400,
//                                 letterSpacing: -0.20,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppColor.white.withValues(alpha: 0.08),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: SvgPicture.asset('assets/icons/share.svg'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 Text(
//                   "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
//                   style: GoogleFonts.dmSans(
//                     color: Colors.white,
//                     fontSize: Responsive.textScaleFactor * 12,
//                     fontWeight: FontWeight.w400,
//                     height: 1.50,
//                   ),
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,

//                   children: [
//                     Row(
//                       children: [
//                         SvgPicture.asset("assets/icons/mic.svg"),
//                         Text(
//                           'English, German',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: Responsive.textScaleFactor * 10,
//                             fontFamily: 'DM Sans',
//                             fontWeight: FontWeight.w400,
//                             letterSpacing: -0.20,
//                           ),
//                         ),
//                       ],
//                     ),

//                     Text.rich(
//                       TextSpan(
//                         children: [
//                           TextSpan(
//                             text: '\$30/',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: Responsive.textScaleFactor * 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w800,
//                               letterSpacing: -0.20,
//                             ),
//                           ),
//                           TextSpan(
//                             text: ' ',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: Responsive.textScaleFactor * 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w500,
//                               letterSpacing: -0.20,
//                             ),
//                           ),
//                           TextSpan(
//                             text: 'hr',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: Responsive.textScaleFactor * 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w400,
//                               letterSpacing: -0.20,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),

//                 //Divider
//                 Row(children: [Expanded(child: Divider())]),

//                 Text(
//                   'Expertise',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: Responsive.textScaleFactor * 12,
//                     fontFamily: 'DM Sans',
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 //Skill cipsviewview
//                 Wrap(
//                   spacing: 5,
//                   runSpacing: 10,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: ShapeDecoration(
//                         shape: RoundedRectangleBorder(
//                           side: BorderSide(
//                             width: 1,
//                             color: Colors.white.withValues(alpha: 0.40),
//                           ),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         spacing: 10,
//                         children: [
//                           Text(
//                             'Data Science',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w400,
//                               height: 1.50,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: ShapeDecoration(
//                         shape: RoundedRectangleBorder(
//                           side: BorderSide(
//                             width: 1,
//                             color: Colors.white.withValues(alpha: 0.40),
//                           ),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         spacing: 10,
//                         children: [
//                           Text(
//                             'Machine Learning',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w400,
//                               height: 1.50,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: ShapeDecoration(
//                         shape: RoundedRectangleBorder(
//                           side: BorderSide(
//                             width: 1,
//                             color: Colors.white.withValues(alpha: 0.40),
//                           ),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         spacing: 10,
//                         children: [
//                           Text(
//                             'Resume Review',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w400,
//                               height: 1.50,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: ShapeDecoration(
//                         shape: RoundedRectangleBorder(
//                           side: BorderSide(
//                             width: 1,
//                             color: Colors.white.withValues(alpha: 0.40),
//                           ),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         spacing: 10,
//                         children: [
//                           Text(
//                             'Career Guidance',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontFamily: 'DM Sans',
//                               fontWeight: FontWeight.w400,
//                               height: 1.50,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 Text(
//                   'Intro Video',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: Responsive.textScaleFactor * 12,
//                     fontFamily: 'DM Sans',
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 //video view
//                 Container(
//                   height: 100,
//                   width: double.infinity,
//                   color: AppColor.red,
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 //reivew and viewa all
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Reviews',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontFamily: 'DM Sans',
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Text(
//                       'View all',
//                       textAlign: TextAlign.right,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontFamily: 'DM Sans',
//                         fontWeight: FontWeight.w400,
//                         height: 1.60,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: Responsive.h(2)),

//                 //comments card
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(15),
//                   decoration: ShapeDecoration(
//                     color: Colors.white.withValues(alpha: 0.08),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     spacing: 10,
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           spacing: 10,
//                           children: [
//                             Container(
//                               width: double.infinity,
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 spacing: 9,
//                                 children: [
//                                   Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     mainAxisAlignment: MainAxisAlignment.start,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     spacing: 9,
//                                     children: [
//                                       Container(
//                                         width: 40,
//                                         height: 40,
//                                         decoration: ShapeDecoration(
//                                           image: DecorationImage(
//                                             image: AssetImage(
//                                               "assets/icons/Ellipse 6.png",
//                                             ),
//                                             fit: BoxFit.cover,
//                                           ),
//                                           shape: OvalBorder(),
//                                         ),
//                                       ),
//                                       Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.start,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         spacing: 3,
//                                         children: [
//                                           Text(
//                                             'Jamie Dunn',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 14,
//                                               fontFamily: 'DM Sans',
//                                               fontWeight: FontWeight.w500,
//                                               letterSpacing: -0.30,
//                                             ),
//                                           ),
//                                           Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.start,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             children: [
//                                               Container(
//                                                 width: 13,
//                                                 height: 13,
//                                                 clipBehavior: Clip.antiAlias,
//                                                 decoration: BoxDecoration(),
//                                                 child: Stack(),
//                                               ),
//                                               Container(
//                                                 width: 13,
//                                                 height: 13,
//                                                 clipBehavior: Clip.antiAlias,
//                                                 decoration: BoxDecoration(),
//                                                 child: Stack(),
//                                               ),
//                                               Container(
//                                                 width: 13,
//                                                 height: 13,
//                                                 clipBehavior: Clip.antiAlias,
//                                                 decoration: BoxDecoration(),
//                                                 child: Stack(),
//                                               ),
//                                               Container(
//                                                 width: 13,
//                                                 height: 13,
//                                                 clipBehavior: Clip.antiAlias,
//                                                 decoration: BoxDecoration(),
//                                                 child: Stack(),
//                                               ),
//                                               Container(
//                                                 width: 13,
//                                                 height: 13,
//                                                 clipBehavior: Clip.antiAlias,
//                                                 decoration: BoxDecoration(),
//                                                 child: Stack(),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                   Text(
//                                     '15 Days Ago',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 10,
//                                       fontFamily: 'DM Sans',
//                                       fontWeight: FontWeight.w500,
//                                       letterSpacing: -0.30,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             SizedBox(
//                               width: 325,
//                               child: Text(
//                                 "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontFamily: 'DM Sans',
//                                   fontWeight: FontWeight.w400,
//                                   height: 1.50,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 SizedBox(height: Responsive.h(2)),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Courses Offered by Mentor',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontFamily: 'DM Sans',
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Text(
//                       'Sort By: Latest',
//                       textAlign: TextAlign.right,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontFamily: 'DM Sans',
//                         fontWeight: FontWeight.w400,
//                         height: 1.60,
//                       ),
//                     ),
//                   ],
//                 ),

//                 Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//                     color: AppColor.red,
//                   ),
//                   child: Padding(
//                     padding: Responsive.padding(
//                       left: 1,
//                       right: 1,
//                       top: 2,
//                       bottom: 2,
//                     ),
//                     child: Text(
//                       'Book a session',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontFamily: 'DM Sans',
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: -0.20,
//                       ),
//                     ),
//                   ),
//                 ),

//                 Flexible(
//                   child: ListView.builder(
//                     itemCount: 10,
//                     itemBuilder: ((context, index) {
//                       return Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(28),
//                             color: AppColor.white.withValues(alpha: 0.08),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 SizedBox(height: 10),
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Row(
//                                       spacing: 10,
//                                       children: [
//                                         SvgPicture.asset(
//                                           "assets/icons/Frame 1000002079.svg",
//                                         ),
//                                         Text(
//                                           "\$19.99",
//                                           style: GoogleFonts.dmSans(
//                                             color: AppColor.white,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(28),
//                                         color: AppColor.red,
//                                       ),
//                                       child: Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 8.0,
//                                           horizontal: 16.0,
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             Text(
//                                               "Enroll",
//                                               style: GoogleFonts.dmSans(
//                                                 fontSize: 14,
//                                                 color: AppColor.white,
//                                                 fontWeight: FontWeight.w700,
//                                               ),
//                                             ),
//                                             SvgPicture.asset(
//                                               "assets/icons/arrow.svg",
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 10),

//                                 Text(
//                                   "Duration: 2–5h",
//                                   style: GoogleFonts.dmSans(
//                                     color: AppColor.white,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 SizedBox(height: 10),

//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: [
//                                     Text(
//                                       "UI/UX Design Basics",
//                                       style: GoogleFonts.dmSans(
//                                         fontSize:
//                                             Responsive.textScaleFactor * 25,
//                                         color: AppColor.white,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),

//                                 SizedBox(height: 10),
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: [
//                                     Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.end,
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 20,
//                                           backgroundImage: AssetImage(
//                                             "assets/icons/Ellipse 6.png",
//                                           ),
//                                         ),
//                                         SizedBox(width: 10),

//                                         Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "Chance Calzoni",
//                                               style: GoogleFonts.dmSans(
//                                                 color: AppColor.white,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                             Text(
//                                               "Mentor",
//                                               style: GoogleFonts.dmSans(
//                                                 color: AppColor.white,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                     Row(
//                                       children: [
//                                         SvgPicture.asset(
//                                           "assets/icons/material-symbols_star (1).svg",
//                                         ),
//                                         Text(
//                                           "4.8",
//                                           style: GoogleFonts.dmSans(
//                                             color: AppColor.white,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),

//                                 SizedBox(height: 10),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
