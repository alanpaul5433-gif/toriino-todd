import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/model/ai/chat_message_model.dart';
import 'package:toriino_todd/services/auth_service.dart';

export 'package:toriino_todd/model/ai/chat_message_model.dart';

class AiTutorViewmodel extends GetxController {
  final messageController = TextEditingController();
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isTyping = false.obs;

  // Rolling conversation history (index 0 = AI welcome, 1 = user, 2 = AI, ...)
  final List<Map<String, dynamic>> _history = [];

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
    _history.add({'text': welcome, 'isUser': false});
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

    _sendViaLambda(text);
  }

  Future<void> _sendViaLambda(String text) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception('Not logged in');

      final headers = await AuthInterceptor.getAuthHeaders();
      final recentHistory = _history.length > 20
          ? _history.sublist(_history.length - 20)
          : List<Map<String, dynamic>>.from(_history);

      final response = await http.post(
        Uri.parse(AppUrl.aiChat(userId)),
        headers: headers,
        body: jsonEncode({
          'message': text,
          if (courseTopic != null) 'sessionContext': courseTopic,
          'history': recentHistory,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = (data['aiMessage']?['text'] as String?) ?? 'No response.';
        isTyping.value = false;
        _history.add({'text': text, 'isUser': true});
        _history.add({'text': reply, 'isUser': false});
        messages.add(ChatMessageModel(
          id: _id(),
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        throw _AiHttpError(response.statusCode);
      }
    } catch (e) {
      isTyping.value = false;
      // 503 = the AI backend is not configured yet (Gemini key NOT_SET); 402 = premium required.
      // Say so instead of a generic "couldn't reach" (UAT L8).
      final code = e is _AiHttpError ? e.statusCode : null;
      final text = code == 503
          ? 'The AI Tutor is not available yet: it has not been set up on the server.'
          : code == 402
              ? 'The AI Tutor is part of Premium. See Upgrade to Premium for plans.'
              : 'Sorry, I couldn\'t reach the AI right now. Please try again.';
      messages.add(ChatMessageModel(
        id: _id(),
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void resetChat() {
    messages.clear();
    _history.clear();
    isTyping.value = false;
    const welcome = 'Hello! I\'m your AI Tutor powered by Toriino. '
        'Ask me anything about your courses, homework, or any academic topic. '
        'I\'m here to help you learn!';
    messages.add(ChatMessageModel(
      id: _id(),
      text: welcome,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _history.add({'text': welcome, 'isUser': false});
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}

class _AiHttpError implements Exception {
  final int statusCode;
  const _AiHttpError(this.statusCode);
  @override
  String toString() => 'HTTP $statusCode';
}
