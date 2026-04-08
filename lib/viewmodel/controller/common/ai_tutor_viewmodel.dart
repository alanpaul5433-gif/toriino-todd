import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/repository/mock/mock_ai_tutor.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class AiTutorViewmodel extends GetxController {
  final messageController = TextEditingController();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Add welcome message
    messages.add(ChatMessage(
      text: 'Hello! I\'m your AI Tutor powered by Toriino. Ask me anything about your courses, homework, or any academic topic. I\'m here to help you learn!',
      isUser: false,
      time: _formatTime(),
    ));
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    messages.add(ChatMessage(
      text: text,
      isUser: true,
      time: _formatTime(),
    ));
    messageController.clear();

    // Show typing indicator
    isTyping.value = true;

    // Get AI response
    MockAiTutor.getResponse(text).then((response) {
      isTyping.value = false;
      messages.add(ChatMessage(
        text: response,
        isUser: false,
        time: _formatTime(),
      ));
    });
  }

  String _formatTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${now.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
