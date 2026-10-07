import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/repository/notification_repo.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background: ${message.messageId}');
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('[FCM] Firebase not initialized — skipping FCM setup');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
      _showInAppBanner(message);
    });

    _messaging.onTokenRefresh.listen((token) => _registerToken(token));
  }

  static Future<void> registerAfterLogin() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  static void _showInAppBanner(RemoteMessage message) {
    final context = Get.context;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.notification?.title != null)
                        Text(message.notification!.title!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      if (message.notification?.body != null)
                        Text(message.notification!.body!,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                  onPressed: () => entry.remove(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      try { entry.remove(); } catch (_) {}
    });
  }

  static Future<void> _registerToken(String token) async {
    try {
      await NotificationRepo().registerFcmToken(
        token,
        platform: Platform.isAndroid ? 'android' : 'ios',
      );
    } catch (e) {
      debugPrint('FCM register token error: $e');
    }
  }
}
