import 'package:flutter/material.dart';
import 'package:toriino_todd/view/subscriptions/plans_view.dart';
import 'package:toriino_todd/view/users/teacher/teacher_bottom_nav_bar.dart';

/// Teacher subscription entry point — the shared, server-driven [PlansView].
/// [isOnboarding] shows "Skip" (to the teacher home) instead of a back arrow.
class TeacherSubcribption extends StatelessWidget {
  const TeacherSubcribption({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return PlansView(
      onContinue: isOnboarding
          ? () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => TeacherBottomNavBar()),
              )
          : null,
    );
  }
}
