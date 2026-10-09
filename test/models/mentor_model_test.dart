import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';

void main() {
  group('MentorModel.fromJson', () {
    test('round-trip with full data', () {
      final json = {
        'userId': 'u1',
        'name': 'Alice Mentor',
        'email': 'alice@example.com',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'bio': 'Experienced Flutter developer',
        'expertise': ['Flutter', 'Dart', 'Firebase'],
        'hourlyRate': 75.0,
        'rating': 4.8,
        'totalSessions': 42,
        'totalStudents': 20,
        'introVideoUrl': 'https://example.com/intro.mp4',
        'createdAt': '2024-01-01T00:00:00Z',
      };
      final result = MentorModel.fromJson(json);
      expect(result.userId, 'u1');
      expect(result.name, 'Alice Mentor');
      expect(result.email, 'alice@example.com');
      expect(result.avatarUrl, 'https://example.com/avatar.jpg');
      expect(result.bio, 'Experienced Flutter developer');
      expect(result.expertise, ['Flutter', 'Dart', 'Firebase']);
      expect(result.hourlyRate, 75.0);
      expect(result.rating, 4.8);
      expect(result.totalSessions, 42);
      expect(result.totalStudents, 20);
      expect(result.introVideoUrl, 'https://example.com/intro.mp4');
      expect(result.createdAt, '2024-01-01T00:00:00Z');
    });

    test('missing optional fields default to null', () {
      final result = MentorModel.fromJson({'userId': 'u2'});
      expect(result.userId, 'u2');
      expect(result.name, isNull);
      expect(result.email, isNull);
      expect(result.bio, isNull);
      expect(result.expertise, isNull);
      expect(result.hourlyRate, isNull);
      expect(result.rating, isNull);
      expect(result.totalSessions, isNull);
      expect(result.introVideoUrl, isNull);
    });

    test('expertise as empty list', () {
      final result = MentorModel.fromJson({
        'userId': 'u3',
        'expertise': <String>[],
      });
      expect(result.expertise, isEmpty);
    });

    test('hourlyRate and rating parsed from int JSON values', () {
      final result = MentorModel.fromJson({
        'userId': 'u4',
        'hourlyRate': 50,
        'rating': 5,
      });
      expect(result.hourlyRate, 50.0);
      expect(result.rating, 5.0);
    });
  });

  group('MentorListResponse.fromJson', () {
    test('round-trip with one mentor', () {
      final json = {
        'mentors': [
          {'userId': 'm1', 'name': 'Bob'},
        ],
        'count': 1,
      };
      final result = MentorListResponse.fromJson(json);
      expect(result.mentors.length, 1);
      expect(result.mentors.first.userId, 'm1');
      expect(result.count, 1);
    });

    test('empty list does not throw', () {
      final result = MentorListResponse.fromJson({'mentors': [], 'count': 0});
      expect(result.mentors, isEmpty);
      expect(result.count, 0);
    });

    test('missing mentors key does not throw', () {
      final result = MentorListResponse.fromJson({'count': 0});
      expect(result.mentors, isEmpty);
    });

    test('null mentors value does not throw', () {
      final result = MentorListResponse.fromJson({'mentors': null, 'count': 0});
      expect(result.mentors, isEmpty);
    });

    test('GET /mentors shape: mentorId and specialties map to userId and expertise', () {
      final result = MentorListResponse.fromJson({
        'mentors': [
          {'mentorId': 'sub-123', 'name': 'M', 'specialties': ['Math', 'Physics'], 'hourlyRate': 40}
        ],
        'count': 1,
      });
      expect(result.mentors.first.userId, 'sub-123');
      expect(result.mentors.first.expertise, ['Math', 'Physics']);
    });
  });
}
