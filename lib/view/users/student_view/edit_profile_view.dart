import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/repository/user_repo.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/viewmodel/controller/student/profile_viewmodel.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentEditProfileView extends StatefulWidget {
  const StudentEditProfileView({super.key});

  @override
  State<StudentEditProfileView> createState() => _StudentEditProfileViewState();
}

class _StudentEditProfileViewState extends State<StudentEditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;
  String? educationLevel;
  String? selectedLanguage;

  final List<String> educationLevels = [
    'High School',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
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
    // Pre-fill from the cached profile when the profile screen loaded it.
    if (Get.isRegistered<ProfileViewmodel>()) {
      final p = Get.find<ProfileViewmodel>().rxProfile.value.data;
      if (p != null) {
        _nameCtrl.text = p.name ?? '';
        _bioCtrl.text = p.bio ?? '';
        if (educationLevels.contains(p.educationLevel)) {
          educationLevel = p.educationLevel;
        }
        if (languages.contains(p.language)) selectedLanguage = p.language;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await UserRepo().updateProfile({
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        if (educationLevel != null) 'educationLevel': educationLevel,
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                    "assets/icons/Frame 1171275882.png",
                  ),
                ),
                SizedBox(height: 8),TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontWeight: FontWeight.w500,
                  ),
                 
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    hint: Row(
                      children: [
                        SvgPicture.asset('assets/images/user-multiple-02 (1).svg'),
                        Text(
                          'Full Name',
                          style: GoogleFonts.rethinkSans(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.2),
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),

                TextFormField(
                  controller: _bioCtrl,
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
                    fillColor: AppColor.white.withValues(alpha: 0.2),
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your bio';
                    }
                    return null;
                  },
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
                    hint: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/carousel-horizontal.svg',
                        ),
                        Text(
                          'Education Level',
                          style: GoogleFonts.rethinkSans(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    filled: true,
                    fillColor: AppColor.white.withValues(alpha: 0.2),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
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
                    fillColor: AppColor.white.withValues(alpha: 0.2),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColor.primaryColor),
                      // borderSide: BorderSide(color: AppColor.white),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    hint: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset('assets/icons/language-circle.svg'),
                        Text(
                          'Select Language',
                          style: GoogleFonts.rethinkSans(
                            color: AppColor.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _saving ? null : _save,
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
                              if (_saving)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.white,
                                    ),
                                  ),
                                ),
                              Text(
                                _saving ? "Saving..." : "Save",
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
