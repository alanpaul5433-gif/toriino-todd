import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/session/session_model.dart';

void main() {
  group('SessionListResponse.fromJson', () {
    test('empty sessions list does not throw', () {
      final result = SessionListResponse.fromJson({'sessions': [], 'count': 0});
      expect(result.sessions, isEmpty);
    });

    test('missing sessions key does not throw', () {
      final result = SessionListResponse.fromJson({'count': 0});
      expect(result.sessions, isEmpty);
    });

    test('null sessions value does not throw', () {
      final result = SessionListResponse.fromJson({'sessions': null});
      expect(result.sessions, isEmpty);
    });
  });
}
