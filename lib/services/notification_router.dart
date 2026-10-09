import 'package:get/get.dart';
import 'package:toriino_todd/resources/routes/routes_name.dart';

/// Routes an FCM notification tap to the correct screen using named routes.
class NotificationRouter {
  static void handleTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    switch (type) {
      case 'session':
        if (id != null) {
          Get.toNamed(
            RoutesName.liveSession,
            arguments: {'sessionId': id, 'isMentor': false},
          );
        }
        break;
      case 'lesson':
        // Navigate to course detail when a lesson deep-link is available.
        // Get.toNamed(RoutesName.lessonVideo, arguments: {...});
        break;
      default:
        // Navigate to the notifications screen.
        break;
    }
  }
}
