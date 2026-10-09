import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/course/course_model.dart';

void main() {
  group('CourseListResponse.fromJson', () {
    test('round-trip with full data', () {
      final json = {
        'courses': [
          {
            'courseId': 'c1',
            'title': 'Test Course',
            'description': 'desc',
            'teacherId': 'u1',
            'price': 99.0,
            'category': 'Math',
            'level': 'beginner',
            'imageUrl': 'https://example.com/img.jpg',
            'status': 'published',
            'enrollmentCount': 5,
            'rating': 4.5,
            'duration': '120',
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-01T00:00:00Z',
          }
        ],
        'count': 1,
      };
      final result = CourseListResponse.fromJson(json);
      expect(result.courses.length, 1);
      expect(result.courses.first.courseId, 'c1');
    });

    test('empty courses list does not throw', () {
      final result = CourseListResponse.fromJson({'courses': [], 'count': 0});
      expect(result.courses, isEmpty);
    });

    test('missing courses key does not throw', () {
      final result = CourseListResponse.fromJson({'count': 0});
      expect(result.courses, isEmpty);
    });

    test('null courses value does not throw', () {
      final result = CourseListResponse.fromJson({'courses': null, 'count': 0});
      expect(result.courses, isEmpty);
    });
  });
}
