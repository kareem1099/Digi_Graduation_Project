import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIAssistantController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isTyping = false.obs;

  final GeminiService _geminiService = GeminiService();

  final List<String> suggestions = [
    "When to start solids?",
    "6-Month purees menu",
    "Allergy safety tips",
    "Transitioning to cup",
  ];

  @override
  void onInit() {
    super.onInit();
    // Add initial welcome message
    messages.add(ChatMessage(
      text: "Hello! I am your AI Food Assistant. 🍼\nI can help you with solid food introductions, baby recipes, feeding schedules, and allergen guidance. Ask me anything!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    
    isTyping.value = true;
    messageController.clear();
    scrollToBottom();

    // Map complete conversation history into standard Gemini format
    final history = messages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ]
      };
    }).toList();

    // Fetch response from Gemini API
    _geminiService.getResponse(history).then((responseText) {
      isTyping.value = false;
      messages.add(ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      scrollToBottom();
    }).catchError((error) {
      isTyping.value = false;
      messages.add(ChatMessage(
        text: "An error occurred: $error",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      scrollToBottom();
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
