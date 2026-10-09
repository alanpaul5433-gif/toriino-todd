import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/user/user_profile_model.dart';

void main() {
  group('UserProfileModel.fromJson', () {
    test('round-trip with full data', () {
      final json = {
        'userId': 'user-001',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': '+12025551234',
        'role': 'student',
        'bio': 'Lifelong learner',
        'avatarUrl': 'https://example.com/jane.jpg',
        'dateOfBirth': '1995-03-15',
        'location': 'New York, USA',
        'interests': ['Math', 'Science', 'Art'],
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-06-01T00:00:00Z',
      };
      final result = UserProfileModel.fromJson(json);
      expect(result.userId, 'user-001');
      expect(result.name, 'Jane Doe');
      expect(result.email, 'jane@example.com');
      expect(result.phone, '+12025551234');
      expect(result.role, 'student');
      expect(result.bio, 'Lifelong learner');
      expect(result.avatarUrl, 'https://example.com/jane.jpg');
      expect(result.dateOfBirth, '1995-03-15');
      expect(result.location, 'New York, USA');
      expect(result.interests, ['Math', 'Science', 'Art']);
      expect(result.createdAt, '2024-01-01T00:00:00Z');
      expect(result.updatedAt, '2024-06-01T00:00:00Z');
    });

    test('all optional fields missing does not throw', () {
      final result = UserProfileModel.fromJson({});
      expect(result.userId, isNull);
      expect(result.name, isNull);
      expect(result.email, isNull);
      expect(result.interests, isNull);
    });

    test('null interests field is null', () {
      final result = UserProfileModel.fromJson({
        'userId': 'u1',
        'interests': null,
      });
      expect(result.interests, isNull);
    });

    test('empty interests list is preserved', () {
      final result = UserProfileModel.fromJson({
        'userId': 'u2',
        'interests': <String>[],
      });
      expect(result.interests, isEmpty);
    });

    test('toJson includes only non-null fields', () {
      final model = UserProfileModel(
        userId: 'u3',
        name: 'Bob',
        email: 'bob@example.com',
      );
      final json = model.toJson();
      expect(json['userId'], 'u3');
      expect(json['name'], 'Bob');
      expect(json['email'], 'bob@example.com');
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('bio'), isFalse);
    });
  });
}
