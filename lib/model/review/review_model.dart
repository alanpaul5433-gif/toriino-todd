class ReviewModel {
  final String? targetId;
  final String? reviewId;
  final String? reviewerId;
  final int? rating;
  final String? comment;
  final String? targetType;
  final String? createdAt;

  ReviewModel({
    this.targetId,
    this.reviewId,
    this.reviewerId,
    this.rating,
    this.comment,
    this.targetType,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      targetId: json['targetId'],
      reviewId: json['reviewId'],
      reviewerId: json['reviewerId'],
      rating: json['rating'],
      comment: json['comment'],
      targetType: json['targetType'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'rating': rating,
      'comment': comment,
      'targetType': targetType,
    };
  }
}

class ReviewListResponse {
  final List<ReviewModel> reviews;
  final int count;

  ReviewListResponse({required this.reviews, required this.count});

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    return ReviewListResponse(
      reviews: (json['reviews'] as List)
          .map((e) => ReviewModel.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
