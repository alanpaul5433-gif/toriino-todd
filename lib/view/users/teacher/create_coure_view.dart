import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/teacher/add_lesson_view.dart';
import 'package:toriino_todd/view/users/teacher/teacher_home_view.dart';
import 'package:toriino_todd/viewmodel/controller/teacher/teacher_course_viewmodel.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateCoureView extends StatefulWidget {
  const CreateCoureView({super.key});

  @override
  State<CreateCoureView> createState() => _CreateCoureViewState();
}

class _CreateCoureViewState extends State<CreateCoureView> {
  String? selectedlanguages;
  String? courseCategory;
  String? courselevel;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  final List<String> courseCategories = [
    'Programming',
    'Design',
    'Business',
    'Fitness & Wellness',
    'Language Learning',
    'Music',
    'Other',
  ];

  final List<String> courseLevels = [
    'All Levels',
    'Beginner',
    'Intermediate',
    'Expert',
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(5),
            vertical: Responsive.h(2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg")),
                      SizedBox(width: Responsive.w(2)),
                      Text(
                        'Create New Course',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Rethink Sans',
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ],
                  ),
                  circularIcon("assets/icons/robotic.svg"),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: const Color(0xFFE73121),
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: Responsive.padding(bottom: 1, top: 1),
                        child: Center(
                          child: Text(
                            'Pre-recorded',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: Responsive.padding(bottom: 1, top: 1),
                        child: Center(
                          child: Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),

              textflieds("Course Title", controller: _titleController),
              SizedBox(height: Responsive.h(1.5)),

              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: AppColor.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hint: Text(
                    "Description",
                    style: GoogleFonts.dmSans(color: AppColor.white),
                  ),

                  filled: true,
                  fillColor: AppColor.white.withValues(alpha: 0.08),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.focusedBorder),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.red),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  // label: Text(text, style: TextStyle(color: AppColor.white)),
                ),
                // onFieldSubmitted: (value) {
                //   Utils.fieldFoucsChange(context, focusNode, nextfocusNode);
                // },
              ),
              SizedBox(height: Responsive.h(1.5)),

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
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.focusedBorder),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.red),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  hint: Text(
                    'Course Category',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                ),
                value: courseCategory,
                items:
                    courseCategories.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.20,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    courseCategory = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null
                            ? 'Please select a course catogory'
                            : null,
              ),
              SizedBox(height: Responsive.h(1.5)),
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
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.focusedBorder),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.red),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  hint: Text(
                    'Course Level',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                ),
                value: courselevel,
                items:
                    courseLevels.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.20,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    courselevel = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please select course levels' : null,
              ),
              SizedBox(height: Responsive.h(1.5)),
              textflieds("Course Duration In hours", controller: _durationController),
              SizedBox(height: Responsive.h(1.5)),
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
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.focusedBorder),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.red),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  hint: Text(
                    'Language',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: Responsive.textScaleFactor * 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                ),
                value: selectedlanguages,
                items:
                    languages.map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.20,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedlanguages = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please select a language' : null,
              ),
              SizedBox(height: Responsive.h(1.5)),
              textflieds("Price Range", controller: _priceController),
              SizedBox(height: Responsive.h(1)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If the course is free, enter 0 as the price.',
                    style: GoogleFonts.dmSans(
                      color: AppColor.white,
                      fontSize: Responsive.textScaleFactor * 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),

              AuthButton(
                buttontext: "Next",
                loading: false,
                onPress: () {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a course title')),
                    );
                    return;
                  }
                  if (_descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a course description')),
                    );
                    return;
                  }
                  if (courseCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a category')),
                    );
                    return;
                  }
                  final vm = Get.isRegistered<TeacherCourseViewmodel>()
                      ? Get.find<TeacherCourseViewmodel>()
                      : Get.put(TeacherCourseViewmodel());
                  vm.titleController.text = _titleController.text.trim();
                  vm.descriptionController.text = _descriptionController.text.trim();
                  vm.durationController.text = _durationController.text.trim();
                  vm.priceController.text = _priceController.text.trim();
                  if (courseCategory != null) vm.selectedCategory.value = courseCategory!;
                  if (courselevel != null) vm.selectedLevel.value = courselevel!;
                  vm.selectedLanguage = selectedlanguages;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddLessonView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget textflieds(String text, {TextEditingController? controller}) {
  return TextFormField(
    controller: controller,
    style: TextStyle(color: AppColor.white),
    decoration: InputDecoration(
      hint: Text(text, style: GoogleFonts.dmSans(color: AppColor.white)),

      filled: true,
      fillColor: AppColor.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColor.primaryColor),
        borderRadius: BorderRadius.circular(28),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColor.focusedBorder),
        borderRadius: BorderRadius.circular(28),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColor.red),
        borderRadius: BorderRadius.circular(28),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColor.primaryColor),
        borderRadius: BorderRadius.circular(28),
      ),
      // label: Text(text, style: TextStyle(color: AppColor.white)),
    ),
    // onFieldSubmitted: (value) {
    //   Utils.fieldFoucsChange(context, focusNode, nextfocusNode);
    // },
  );
}
