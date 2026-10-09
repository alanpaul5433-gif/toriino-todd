import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/interest_view.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentProfileSetup extends StatefulWidget {
  const StudentProfileSetup({super.key});
  @override
  StudentProfileSetupState createState() => StudentProfileSetupState();
}

class StudentProfileSetupState extends State<StudentProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  String? bio;
  String? educationLevel;
  String? selectedLanguage;
  String? selectedIndustry;

  final List<String> educationLevels = [
    'High School',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Other',
  ];

  final List<String> selectedIndustries = [
    'Programming',
    'Design',
    'Business',
    'Fitness & Wellness',
    'Language Learning',
    'Music',
    'Other',
  ];

  final List<String> languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: [
                //     SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                //   ],
                // ),
                // SizedBox(height: 8),
                Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Stack(
                  children: [
                      CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        "assets/images/michel.png",
                      ),
                    ),
                    // Image(
                    //   image: AssetImage("assets/images/michel.png"),
                    // ),
                    Positioned(
                      bottom: 0,
                      right: 5,
                      child: SvgPicture.asset('assets/icons/add_photo.svg'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                TextFormField(
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 5,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    hint: Row(
                      children: [
                        SvgPicture.asset('assets/icons/file-01 (1).svg'),
                        Text(
                          'Bio',
                          style: GoogleFonts.rethinkSans(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bio';
                    }
                    return null;
                  },
                  onSaved: (value) => bio = value,
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  iconEnabledColor: AppColor.white,
                  dropdownColor: AppColor.primaryColor,
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/carousel-horizontal.svg',
                      ),
                    ),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Education Level',
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  ),
                  // ignore: deprecated_member_use
                  value: educationLevel,
                  items:
                      educationLevels.map((String level) {
                        return DropdownMenuItem<String>(
                          // ignore: deprecated_member_use
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      educationLevel = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a language' : null,
                ),

                SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  iconEnabledColor: AppColor.white,
                  dropdownColor: AppColor.primaryColor,
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/language-circle.svg',
                      ),
                    ),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Language',
                        style: GoogleFonts.dmSans(
                          color: AppColor.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  ),
                  // ignore: deprecated_member_use
                  value: selectedLanguage,
                  items:
                      languages.map((String language) {
                        return DropdownMenuItem<String>(
                          // ignore: deprecated_member_use
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLanguage = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a language' : null,
                ),
                SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InterestSelectionScreen(),
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
                              SvgPicture.asset("assets/icons/arrow.svg"),
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
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:toriino_todd/resources/AppColor/app_AppColor.dart';
// import 'package:google_fonts/google_fonts.dart';

// class StudentProfile extends StatefulWidget {
//   const StudentProfile({super.key});

//   @override
//   State<StudentProfile> createState() => _StudentProfileState();
// }

// class _StudentProfileState extends State<StudentProfile> {
//   String? selectedLevel; // This will hold the selected value
//   final List<String> levels = ['New', 'Beginner', 'Intermediate', 'Senior'];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColor.primaryColor,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Profile Setup",
//                 style: GoogleFonts.rethinkSans(
//                   fontWeight: FontWeight.w500,
//                   color: AppColor.white,
//                 ),
//               ),

//               CircleAvatar(backgroundImage: AssetImage("")),

//               TextFormField(
//                 maxLines: 5,
//                 decoration: InputDecoration(
//                   hintText: "Bio",
//                   hintStyle: GoogleFonts.rethinkSans(
//                     fontWeight: FontWeight.w300,
//                     color: AppColor.white,
//                   ),

//                   filled: true,
//                   fillColor: AppColor.white.withValues(alpha: 0.2),
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
//                     // borderSide: BorderSide(color: AppColor.white),
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
//                     // borderSide: BorderSide(color: AppColor.white),
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   prefixIcon: SvgPicture.asset("assetName"),
//                 ),
//               ),
//               SizedBox(height: 10),
//               DropdownButtonFormField<String>(
//                 decoration: InputDecoration(
//                   fillColor: AppColor.white.withValues(alpha: 0.2),filled: true,
//                   labelText: 'Select your level',
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
//                     // borderSide: BorderSide(color: AppColor.white),
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
//                     // borderSide: BorderSide(color: AppColor.white),
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   border: OutlineInputBorder(),
//                 ),
//                 value: selectedLevel,
//                 items:
//                     levels.map((String level) {
//                       return DropdownMenuItem<String>(
//                         value: level,
//                         child: Text(level),
//                       );
//                     }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     selectedLevel = newValue;
//                   });
//                 },
//                 validator:
//                     (value) => value == null ? 'Please select a level' : null,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
