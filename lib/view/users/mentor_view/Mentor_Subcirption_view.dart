import 'package:flutter/material.dart';
import 'package:toriino_todd/view/subscriptions/plans_view.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_bottom_nav_bar.dart';

/// Mentor subscription entry point — the shared, server-driven [PlansView].
/// [isOnboarding] shows "Skip" (to the mentor home) instead of a back arrow.
class MentorSubcirptionView extends StatelessWidget {
  const MentorSubcirptionView({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return PlansView(
      onContinue: isOnboarding
          ? () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MentorBottomNavBar()),
              )
          : null,
    );
  }
}
