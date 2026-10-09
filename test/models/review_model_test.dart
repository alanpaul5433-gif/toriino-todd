import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/review/review_model.dart';

void main() {
  group('ReviewModel.fromJson', () {
    test('round-trip with full data', () {
      final json = {
        'targetId': 'course-123',
        'reviewId': 'rev-456',
        'reviewerId': 'student-789',
        'rating': 5,
        'comment': 'Excellent course!',
        'targetType': 'course',
        'createdAt': '2024-06-01T12:00:00Z',
      };
      final result = ReviewModel.fromJson(json);
      expect(result.targetId, 'course-123');
      expect(result.reviewId, 'rev-456');
      expect(result.reviewerId, 'student-789');
      expect(result.rating, 5);
      expect(result.comment, 'Excellent course!');
      expect(result.targetType, 'course');
      expect(result.createdAt, '2024-06-01T12:00:00Z');
    });

    test('all optional fields missing does not throw', () {
      final result = ReviewModel.fromJson({});
      expect(result.targetId, isNull);
      expect(result.reviewId, isNull);
      expect(result.rating, isNull);
      expect(result.comment, isNull);
    });

    test('missing comment is null', () {
      final result = ReviewModel.fromJson({
        'targetId': 'mentor-1',
        'rating': 4,
      });
      expect(result.comment, isNull);
      expect(result.rating, 4);
    });
  });

  group('ReviewListResponse.fromJson', () {
    test('round-trip with one review', () {
      final json = {
        'reviews': [
          {
            'targetId': 'course-1',
            'reviewId': 'r1',
            'rating': 4,
            'comment': 'Good',
          }
        ],
        'count': 1,
      };
      final result = ReviewListResponse.fromJson(json);
      expect(result.reviews.length, 1);
      expect(result.reviews.first.reviewId, 'r1');
      expect(result.count, 1);
    });

    test('empty list does not throw', () {
      final result = ReviewListResponse.fromJson({'reviews': [], 'count': 0});
      expect(result.reviews, isEmpty);
      expect(result.count, 0);
    });

    test('missing reviews key does not throw', () {
      final result = ReviewListResponse.fromJson({'count': 0});
      expect(result.reviews, isEmpty);
    });

    test('null reviews value does not throw', () {
      final result = ReviewListResponse.fromJson({'reviews': null, 'count': 0});
      expect(result.reviews, isEmpty);
    });
  });
}
