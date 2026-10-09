import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/widgets/components/button_large.dart';
import 'package:toriino_todd/widgets/components/edit.dart';
import 'package:toriino_todd/widgets/components/expertise_selection_widget.dart';
import 'package:toriino_todd/viewmodel/controller/student/profile_viewmodel.dart';
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
  bool _saving = false;
  List<String> _expertise = [];
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
  void initState() {
    super.initState();
    // Pre-fill from the cached profile loaded by the teacher profile screen.
    if (Get.isRegistered<ProfileViewmodel>()) {
      final p = Get.find<ProfileViewmodel>().rxProfile.value.data;
      if (p != null) {
        widget.nameController.text = p.name ?? '';
        widget.titleController.text = p.title ?? '';
        widget.bioController.text = p.bio ?? '';
        _expertise = List<String>.from(p.expertise ?? const []);
        if (languages.contains(p.language)) selectedLanguage = p.language;
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = widget.nameController.text.trim();
    if (name.isEmpty) {
      Utils.toastMassage('Please enter your name');
      return;
    }
    setState(() => _saving = true);
    try {
      await UserRepo().updateProfile({
        'name': name,
        'title': widget.titleController.text.trim(),
        'bio': widget.bioController.text.trim(),
        'expertise': _expertise,
        if (selectedLanguage != null) 'language': selectedLanguage,
      });
      if (Get.isRegistered<ProfileViewmodel>()) {
        Get.find<ProfileViewmodel>().fetchProfile();
      }
      Utils.toastMassage('Profile updated');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Utils.toastMassage(Utils.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

                // The user's own photo, or a neutral placeholder (was a stock photo for
                // everyone — UAT Round 4b M9). There is no photo picker yet.
                Builder(builder: (_) {
                  final url = Get.isRegistered<ProfileViewmodel>()
                      ? (Get.find<ProfileViewmodel>().rxProfile.value.data?.avatarUrl ?? '')
                      : '';
                  return CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white12,
                    backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                    child: url.isEmpty ? const Icon(Icons.person, size: 48, color: Colors.white54) : null,
                  );
                }),
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
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.focusedBorder),
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
                  initialExpertise: _expertise,
                  onExpertiseChanged: (List<String> expertiseList) {
                    _expertise = List<String>.from(expertiseList);
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
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
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
                ),
                SizedBox(height: 32),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: buttonLarge(context, _saving ? "Saving..." : "Save")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
