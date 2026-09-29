import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/notification/notification_model.dart';
import 'package:toriino_todd/repository/notification_repo.dart';

class NotificationViewmodel extends GetxController {
  final _notificationRepo = NotificationRepo();

  final rxNotifications = Rx<ApiResponse<NotificationListResponse>>(ApiResponse.loading());
  RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  void fetchNotifications() {
    rxNotifications.value = ApiResponse.loading();
    _notificationRepo.getNotifications().then((value) {
      final response = NotificationListResponse.fromJson(value);
      rxNotifications.value = ApiResponse.success(response);
      unreadCount.value = response.notifications.where((n) => n.isRead == false).length;
    }).onError((error, _) {
      rxNotifications.value = ApiResponse.error(error.toString());
    });
  }

  void markAsRead(String sortKey) {
    _notificationRepo.markAsRead(sortKey).then((_) {
      fetchNotifications();
    }).onError((_, __) {});
  }
}
