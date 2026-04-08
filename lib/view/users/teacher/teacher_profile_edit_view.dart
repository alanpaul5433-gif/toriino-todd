import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/utils/utils.dart';
import 'package:getxmvvm/widgets/components/button_large.dart';
import 'package:getxmvvm/widgets/components/edit.dart';
import 'package:getxmvvm/widgets/components/expertise_selection_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherProfileEditView extends StatefulWidget {
  TeacherProfileEditView({super.key});

  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFoucsNode = FocusNode();
  final TextEditingController priceController = TextEditingController();
  final FocusNode priceFoucsNode = FocusNode();
  final TextEditingController bioController = TextEditingController();
  final FocusNode bioFoucsNode = FocusNode();
  final TextEditingController experienceController = TextEditingController();
  final FocusNode experienceFoucsNode = FocusNode();
  final TextEditingController nameController = TextEditingController();
  final FocusNode nameFoucsNode = FocusNode();
  final TextEditingController expertiseController = TextEditingController();
  final FocusNode expertiseFoucsNode = FocusNode();
  final TextEditingController industryController = TextEditingController();
  final FocusNode industryFoucsNode = FocusNode();
  final TextEditingController skillController = TextEditingController();
  final FocusNode skillFoucsNode = FocusNode();
  final TextEditingController languageController = TextEditingController();
  final FocusNode languageFoucsNode = FocusNode();

  @override
  State<TeacherProfileEditView> createState() => _TeacherProfileEditViewState();
}

class _TeacherProfileEditViewState extends State<TeacherProfileEditView> {
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset("assets/icons/Arrow - Right 3 (1).svg")),
                    SizedBox(width: Responsive.w(2)),
                    Text(
                      'Edit Your Profile',
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

                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                    "assets/icons/Frame 1171275882.png",
                  ),
                ),
                SizedBox(height: Responsive.h(1)),
                EditProfileTextfeild(
                  text: 'Full Name',
                  controller: widget.nameController,
                  focusNode: widget.nameFoucsNode,
                  nextfocusNode: widget.titleFoucsNode,
                  svgPath: 'assets/icons/user-multiple-02.svg',
                ),
                SizedBox(height: Responsive.h(1)),
                EditProfileTextfeild(
                  text: 'Subject/Field',
                  controller: widget.titleController,
                  focusNode: widget.titleFoucsNode,
                  nextfocusNode: widget.experienceFoucsNode,
                  svgPath: 'assets/icons/3d-rotate.svg',
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
                ExpertiseSelectionWidget(
                  initialExpertise:
                      [], // You can pre-populate with existing expertise if needed
                  onExpertiseChanged: (List<String> expertiseList) {
                    // Handle the updated list of expertise
                    // You might want to store this in your state
                  },
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
                  value: selectedLanguage,
                  items:
                      languages.map((String language) {
                        return DropdownMenuItem<String>(
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
                SizedBox(height: 32),
                GestureDetector(
                  onTap: ()=>Navigator.pop(context),
                  child: buttonLarge(context, "Continue")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
