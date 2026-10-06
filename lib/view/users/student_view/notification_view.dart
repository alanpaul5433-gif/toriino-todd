import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/model/notification/notification_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/view/users/student_view/chips.dart';
import 'package:toriino_todd/viewmodel/controller/common/notification_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationViewmodel vm = Get.put(NotificationViewmodel());
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 5,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Notification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Rethink Sans',
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                ],
              ),
              ChipSelection(),
              Expanded(
                child: Obx(() {
                  final state = vm.rxNotifications.value;
                  if (state.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (state.status == Status.error) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          Text('Could not load notifications', style: const TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: vm.fetchNotifications,
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }
                  final notifications = state.data?.notifications ?? [];
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text('No notifications yet', style: TextStyle(color: Colors.white70)),
                    );
                  }
                  return ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _NotificationCard(notification: n, onTap: () => vm.markAsRead(n.sortKey ?? ''));
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  String _iconAsset(String? type) {
    switch (type) {
      case 'payment':
        return 'assets/icons/invoice.svg';
      case 'alert':
        return 'assets/icons/information-square.svg';
      default:
        return 'assets/icons/checkmark-circle-02.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isRead == false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnread
              ? AppColor.white.withValues(alpha: 0.13)
              : AppColor.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white.withValues(alpha: 0.10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    _iconAsset(notification.type),
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: AppColor.red, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
