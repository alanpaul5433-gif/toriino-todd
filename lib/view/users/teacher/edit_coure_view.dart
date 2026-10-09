import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/teacher/teacher_home_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:google_fonts/google_fonts.dart';

class EditCoureView extends StatefulWidget {
  final CourseModel course;
  const EditCoureView({super.key, required this.course});

  @override
  State<EditCoureView> createState() => _EditCoureViewState();
}

class _EditCoureViewState extends State<EditCoureView> {
  String? selectedlanguages;
  String? courseCategory;
  String? courselevel;
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

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
  void initState() {
    super.initState();
    final c = widget.course;
    _titleController.text = c.title ?? '';
    _descriptionController.text = c.description ?? '';
    _durationController.text = c.duration ?? '';
    _priceController.text = c.price != null ? c.price.toString() : '';

    // Pre-select dropdowns — fall back to null if the value isn't in the list
    if (c.category != null && courseCategories.contains(c.category)) {
      courseCategory = c.category;
    }
    if (c.level != null && courseLevels.contains(c.level)) {
      courselevel = c.level;
    }
    if (c.language != null && languages.contains(c.language)) {
      selectedlanguages = c.language;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
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

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': courseCategory ?? widget.course.category ?? '',
      'level': courselevel ?? widget.course.level ?? '',
      'language': selectedlanguages ?? widget.course.language ?? '',
      'duration': _durationController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ??
          widget.course.price ??
          0,
    };

    try {
      await CourseRepo().updateCourse(widget.course.courseId!, data);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!')),
        );
        Navigator.pop(context, true); // return true so caller can refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating course: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: SingleChildScrollView(
          child: Padding(
            padding: Responsive.padding(left: 2, right: 2, top: 2),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset(
                              "assets/icons/Arrow - Right 3.svg"),
                        ),
                        SizedBox(width: Responsive.w(1)),
                        Text(
                          'Edit Course',
                          style: const TextStyle(
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
                            side: const BorderSide(
                              width: 1,
                              color: Color(0xFFE73121),
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
                SizedBox(height: Responsive.h(1)),

                editTextField("Course Title", controller: _titleController),
                SizedBox(height: Responsive.h(1)),

                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColor.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hint: Text(
                      "Description",
                      style: GoogleFonts.dmSans(color: AppColor.white),
                    ),
                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.08),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColor.primaryColor),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColor.red),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColor.primaryColor),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
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
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  value: courseCategory,
                  items: courseCategories.map((String cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(
                        cat,
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
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  value: courselevel,
                  items: courseLevels.map((String lvl) {
                    return DropdownMenuItem<String>(
                      value: lvl,
                      child: Text(
                        lvl,
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
                ),
                SizedBox(height: Responsive.h(1)),

                editTextField("Course Duration In hours",
                    controller: _durationController),
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
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  value: selectedlanguages,
                  items: languages.map((String language) {
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
                ),
                SizedBox(height: Responsive.h(1)),

                editTextField("Price Range", controller: _priceController),
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
                  buttontext: "Save Changes",
                  loading: _isLoading,
                  onPress: _saveChanges,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget editTextField(String text, {TextEditingController? controller}) {
  return TextFormField(
    controller: controller,
    style: const TextStyle(color: AppColor.white),
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
    ),
  );
}
