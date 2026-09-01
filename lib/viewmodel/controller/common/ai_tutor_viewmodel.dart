import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/model/ai/chat_message_model.dart';
import 'package:toriino_todd/services/gemini_service.dart';

export 'package:toriino_todd/model/ai/chat_message_model.dart';

class AiTutorViewmodel extends GetxController {
  final messageController = TextEditingController();
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isTyping = false.obs;

  // Rolling conversation history passed to Gemini for context
  final List<String> _history = [];

  // Optional: set this when the student is inside a specific course
  String? courseTopic;

  @override
  void onInit() {
    super.onInit();
    const welcome = 'Hello! I\'m your AI Tutor powered by Toriino. '
        'Ask me anything about your courses, homework, or any academic topic. '
        'I\'m here to help you learn!';
    messages.add(ChatMessageModel(
      id: _id(),
      text: welcome,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    // Seed the history so Gemini knows its role from the first message
    _history.add(
      courseTopic != null
          ? 'You are a helpful AI study tutor on the Toriino platform for the topic: "$courseTopic". Be concise and educational.'
          : 'You are a helpful AI study tutor on the Toriino platform. Be concise and educational.',
    );
    _history.add(welcome);
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messages.add(ChatMessageModel(
      id: _id(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    messageController.clear();
    isTyping.value = true;

    // Keep last 20 turns to stay within context window
    final recentHistory = _history.length > 20
        ? _history.sublist(_history.length - 20)
        : List<String>.from(_history);

    GeminiService.instance
        .askStudyAssistant(
          question: text,
          courseTopic: courseTopic,
          history: recentHistory,
        )
        .then((reply) {
      isTyping.value = false;
      _history.add(text);
      _history.add(reply);
      messages.add(ChatMessageModel(
        id: _id(),
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }).catchError((e) {
      isTyping.value = false;
      messages.add(ChatMessageModel(
        id: _id(),
        text: 'Sorry, I couldn\'t reach the AI right now. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
