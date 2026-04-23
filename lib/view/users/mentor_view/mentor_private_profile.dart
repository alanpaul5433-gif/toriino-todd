import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/mentor_view/upload_video.dart';
import 'package:toriino_todd/widgets/components/button_large.dart';
import 'package:toriino_todd/widgets/components/edit.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorPrivateProfile extends StatefulWidget {
  MentorPrivateProfile({super.key});

  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFoucsNode = FocusNode();

  final TextEditingController bioController = TextEditingController();
  final FocusNode bioFoucsNode = FocusNode();
  final TextEditingController experienceController = TextEditingController();
  final FocusNode experienceFoucsNode = FocusNode();
  final TextEditingController nameController = TextEditingController();
  final FocusNode nameFoucsNode = FocusNode();
  final TextEditingController priceController = TextEditingController();
  final FocusNode priceFoucsNode = FocusNode();
  final TextEditingController industryController = TextEditingController();
  final FocusNode industryFoucsNode = FocusNode();
  final TextEditingController skillController = TextEditingController();
  final FocusNode skillFoucsNode = FocusNode();
  final TextEditingController languageController = TextEditingController();
  final FocusNode languageFoucsNode = FocusNode();

  @override
  State<MentorPrivateProfile> createState() => _MentorPrivateProfileState();
}

class _MentorPrivateProfileState extends State<MentorPrivateProfile> {
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
    Responsive.init(context);
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
                SizedBox(height: Responsive.h(1)),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: [
                //     SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                //   ],
                // ),
                // SizedBox(height: Responsive.h(1)),
                Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: Responsive.h(1)),

                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        "assets/icons/Ellipse 6 (1).png",
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset('assets/icons/add_photo.svg'),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(1)),
                EditProfileTextfeild(
                  text: 'Designation / Title',
                  controller: widget.titleController,
                  focusNode: widget.titleFoucsNode,
                  nextfocusNode: widget.experienceFoucsNode,
                  svgPath: 'assets/icons/3d-rotate.svg',
                ),
                SizedBox(height: Responsive.h(1)),
                EditProfileTextfeild(
                  text: 'Years of Experience',
                  controller: widget.experienceController,
                  focusNode: widget.experienceFoucsNode,
                  nextfocusNode: widget.bioFoucsNode,
                  svgPath: 'assets/icons/work.svg',
                ),
                SizedBox(height: Responsive.h(1)),

                TextFormField(
                  focusNode: widget.bioFoucsNode,
                  controller: widget.bioController,
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
                        SizedBox(width: Responsive.w(2)),
                        Text(
                          'Short Bio ',
                          style: GoogleFonts.rethinkSans(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    enabledBorder: UnderlineInputBorder(
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.red),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    Utils.fieldFoucsChange(
                      context,
                      widget.bioFoucsNode,
                      widget.priceFoucsNode,
                    );
                  },
                ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please enter your bio';
                //     }
                //     return null;
                //   },
                //   onSaved: (value) => bio = value,
                // ),
                SizedBox(height: Responsive.h(1)),
                EditProfileTextfeild(
                  text: 'Price per hour',
                  controller: widget.priceController,
                  focusNode: widget.priceFoucsNode,
                  nextfocusNode: widget.nameFoucsNode,
                  svgPath: 'assets/icons/money-03 (1).svg',
                ),
                SizedBox(height: Responsive.h(1)),

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
                    enabledBorder: UnderlineInputBorder(
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.red),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset('assets/icons/building.svg'),
                    ),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Industry',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  ),
                  initialValue: selectedIndustry,
                  items:
                      selectedIndustries.map((String language) {
                        return DropdownMenuItem<String>(
                          // ignore: deprecated_member_use
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedIndustry = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a language' : null,
                ),
                SizedBox(height: Responsive.h(1)),
                EditProfileTextfeild(
                  text: 'Expertise',
                  controller: widget.nameController,
                  focusNode: widget.nameFoucsNode,
                  nextfocusNode: widget.nameFoucsNode,
                  svgPath: 'assets/icons/mentoring.svg',
                ),
                SizedBox(height: Responsive.h(1)),
                DropdownButtonFormField<String>(
                  iconEnabledColor: AppColor.white,
                  dropdownColor: AppColor.primaryColor,
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
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
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),

                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    enabledBorder: UnderlineInputBorder(
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
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
                          value == null
                              ? 'Please select education level'
                              : null,
                ),
                SizedBox(height: Responsive.h(1)),
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
                    enabledBorder: UnderlineInputBorder(
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      // borderSide: BorderSide(color: AppColor.white),
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
                        'Select Language',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
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
                SizedBox(height: Responsive.h(1)),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColor.red),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        SvgPicture.asset("assetName"),
                        Text(
                          'Add More Language ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                GestureDetector(
                  onTap:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => UploadVideo()),
                      ),
                  child: buttonLarge(context, "Continue"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
