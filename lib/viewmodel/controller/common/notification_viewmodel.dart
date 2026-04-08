import 'package:get/get.dart';
import 'package:getxmvvm/data/response/api_response.dart';
import 'package:getxmvvm/model/notification/notification_model.dart';
import 'package:getxmvvm/repository/mock/mock_repo.dart';

class NotificationViewmodel extends GetxController {
  final rxNotifications =
      Rx<ApiResponse<NotificationListResponse>>(ApiResponse.loading());

  RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  void fetchNotifications() {
    rxNotifications.value = ApiResponse.loading();
    MockRepo.getNotifications().then((value) {
      final response = NotificationListResponse.fromJson(value);
      rxNotifications.value = ApiResponse.success(response);
      unreadCount.value =
          response.notifications.where((n) => n.isRead == false).length;
    }).onError((error, _) {
      rxNotifications.value = ApiResponse.error(error.toString());
    });
  }

  void markAsRead(String sortKey) {
    MockRepo.markNotificationRead(sortKey).then((_) {
      fetchNotifications();
    });
  }
}
