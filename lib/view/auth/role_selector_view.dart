import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_bottom_nav_bar.dart';
import 'package:toriino_todd/view/users/student_view/bottom_nav_bar_holder.dart';
import 'package:toriino_todd/view/users/teacher/teacher_bottom_nav_bar.dart';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;
  bool _saving = false;

  Future<void> _continueWithRole() async {
    if (selectedRole == null) return;
    setState(() => _saving = true);

    // POST /auth/set-role saves the role in Cognito (custom:role) and on the
    // profile record; only continue once it has actually been saved.
    final roleResult = await AuthService.setRole(selectedRole!);
    if (!mounted) return;
    if (roleResult['success'] != true) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save your role: ${roleResult['message'] ?? 'please try again'}'),
      ));
      return;
    }

    await UsersPrefrence().saveUserRole(selectedRole!);
    if (!mounted) return;
    setState(() => _saving = false);

    // Reset tab index so every role always opens to Home tab
    try { Get.find<CustomDrawerController>().changeIndex(0); } catch (_) {}

    if (selectedRole == "Student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainWrapper()),
      );
    } else if (selectedRole == "Mentor") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MentorBottomNavBar()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TeacherBottomNavBar()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What describes you best?',
                  style: GoogleFonts.rethinkSans(
                    fontSize: 32,
                    color: AppColor.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your role to customize your learning experience.',
                  style: GoogleFonts.rethinkSans(
                    fontSize: 16,
                    color: AppColor.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Fighter option
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    RoleSelectionCard(
                      svgImage: "assets/icons/books.svg",
                      title: "I’m a Student",
                      isSelected: selectedRole == "Student",
                      onTap: () {
                        setState(() {
                          selectedRole = "Student";
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    RoleSelectionCard(
                      svgImage: "assets/icons/mentoring.svg",
                      title: "I’m a Mentor",
                      isSelected: selectedRole == "Mentor",
                      onTap: () {
                        setState(() {
                          selectedRole = "Mentor";
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Promoter option
                    RoleSelectionCard(
                      svgImage: "assets/icons/presentation.svg",
                      title: "I’m a Teacher",
                      isSelected: selectedRole == "Teacher",
                      onTap: () {
                        setState(() {
                          selectedRole = "Teacher";
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(10),),
        
                ElevatedButton(
                  onPressed: (selectedRole == null || _saving) ? null : _continueWithRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.red,
                    foregroundColor: AppColor.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoleSelectionCard extends StatelessWidget {
  final String title;
  final String svgImage;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleSelectionCard({
    required this.title,
    required this.isSelected,
    required this.svgImage,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.red : AppColor.baseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColor.red : AppColor.primaryColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgImage,
              placeholderBuilder: (_) => const SizedBox(height: 48, width: 48),
            ),
            Text(
              title,
              style: GoogleFonts.rethinkSans(
                fontWeight: FontWeight.w300,
                color: AppColor.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:cage/fonts/fonts.dart';
// import 'package:cage/res/components/app_color.dart';
// import 'package:cage/res/components/button.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// class RoleSelectorView extends StatelessWidget {
//   const RoleSelectorView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColor.black,
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Select your role",
//               style: TextStyle(
//                 fontSize: 28,
//                 fontFamily: AppFonts.appFont,
//                 color: AppColor.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             Text(
//               "Choose your role to continue and personalize your experience.",
//               style: TextStyle(
//                 fontFamily: AppFonts.appFont,
//                 color: AppColor.white,
//                 fontWeight: FontWeight.w100,
//               ),
//             ),

//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     border: BoxBorder.all(color: AppColor.red),
//                     borderRadius: BorderRadius.circular(22),
//                     color: AppColor.black,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       children: [
//                         SvgPicture.asset("assets/icons/boxing.svg"),
//                         Text(
//                           "I’m a Fighter",
//                           style: TextStyle(
//                             fontFamily: AppFonts.appFont,
//                             color: AppColor.white,
//                             fontWeight: FontWeight.w100,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     border: BoxBorder.all(color: AppColor.red),
//                     borderRadius: BorderRadius.circular(22),
//                     color: AppColor.black,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       children: [
//                         SvgPicture.asset("assets/icons/boxing.svg"),
//                         Text(
//                           "I’m a Fighter",
//                           style: TextStyle(
//                             fontFamily: AppFonts.appFont,
//                             color: AppColor.white,
//                             fontWeight: FontWeight.w100,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             Button(text: "Continue", onTap: () {}),
//           ],
//         ),
//       ),
//     );
//   }
// }
