import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/notification/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('round-trip with full data', () {
      final json = {
        'userId': 'u1',
        'sortKey': 'NOTIF#2024-01-01T00:00:00Z',
        'title': 'New message',
        'message': 'You have a new message from Alice',
        'type': 'message',
        'data': {'senderId': 'u2', 'sessionId': 's1'},
        'isRead': false,
        'createdAt': '2024-01-01T00:00:00Z',
      };
      final result = NotificationModel.fromJson(json);
      expect(result.userId, 'u1');
      expect(result.sortKey, 'NOTIF#2024-01-01T00:00:00Z');
      expect(result.title, 'New message');
      expect(result.message, 'You have a new message from Alice');
      expect(result.type, 'message');
      expect(result.data, {'senderId': 'u2', 'sessionId': 's1'});
      expect(result.isRead, false);
      expect(result.createdAt, '2024-01-01T00:00:00Z');
    });

    test('missing isRead field leaves isRead as null', () {
      final result = NotificationModel.fromJson({
        'userId': 'u1',
        'title': 'Test',
        'message': 'Body',
      });
      expect(result.isRead, isNull);
    });

    test('isRead true is preserved', () {
      final result = NotificationModel.fromJson({
        'userId': 'u1',
        'isRead': true,
      });
      expect(result.isRead, true);
    });

    test('missing data field is null', () {
      final result = NotificationModel.fromJson({'userId': 'u1'});
      expect(result.data, isNull);
    });

    test('all optional fields missing does not throw', () {
      final result = NotificationModel.fromJson({});
      expect(result.userId, isNull);
      expect(result.title, isNull);
      expect(result.isRead, isNull);
    });
  });

  group('NotificationListResponse.fromJson', () {
    test('round-trip with one notification', () {
      final json = {
        'notifications': [
          {
            'userId': 'u1',
            'title': 'Hello',
            'message': 'World',
            'isRead': false,
          }
        ],
        'count': 1,
      };
      final result = NotificationListResponse.fromJson(json);
      expect(result.notifications.length, 1);
      expect(result.notifications.first.title, 'Hello');
      expect(result.count, 1);
    });

    test('empty list does not throw', () {
      final result = NotificationListResponse.fromJson({
        'notifications': [],
        'count': 0,
      });
      expect(result.notifications, isEmpty);
      expect(result.count, 0);
    });

    test('missing notifications key does not throw', () {
      final result = NotificationListResponse.fromJson({'count': 0});
      expect(result.notifications, isEmpty);
    });

    test('null notifications value does not throw', () {
      final result = NotificationListResponse.fromJson({
        'notifications': null,
        'count': 0,
      });
      expect(result.notifications, isEmpty);
    });
  });
}
