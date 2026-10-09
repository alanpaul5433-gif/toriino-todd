import 'package:flutter/material.dart';
import 'package:toriino_todd/widgets/custom_recommended_mentors.dart';

/// Recommended teacher card: same real-data card as
/// [CustomRecommendedMentors] without the "Book Session" button. Rows without
/// data are hidden; the avatar is a network image with a neutral fallback.
class CustomRecommendedTeacher extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? role;
  final double? rating;
  final String? description;
  final String? languages;
  final String? pricePerHour;
  final VoidCallback onViewProfileTap;

  const CustomRecommendedTeacher({
    super.key,
    required this.name,
    required this.onViewProfileTap,
    this.avatarUrl,
    this.role,
    this.rating,
    this.description,
    this.languages,
    this.pricePerHour,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRecommendedMentors(
      avatarUrl: avatarUrl,
      name: name,
      role: role,
      rating: rating,
      description: description,
      languages: languages,
      pricePerHour: pricePerHour,
      onViewProfileTap: onViewProfileTap,
    );
  }
}
