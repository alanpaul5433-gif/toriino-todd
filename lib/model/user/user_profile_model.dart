class UserProfileModel {
  final String? userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? bio;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? location;
  final List<String>? interests;
  final double? rating;
  final String? createdAt;
  final String? updatedAt;

  UserProfileModel({
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.bio,
    this.avatarUrl,
    this.dateOfBirth,
    this.location,
    this.interests,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      dateOfBirth: json['dateOfBirth'],
      location: json['location'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (userId != null) data['userId'] = userId;
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (role != null) data['role'] = role;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
    if (location != null) data['location'] = location;
    if (interests != null) data['interests'] = interests;
    if (createdAt != null) data['createdAt'] = createdAt;
    if (updatedAt != null) data['updatedAt'] = updatedAt;
    return data;
  }
}
