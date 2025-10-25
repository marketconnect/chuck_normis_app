import 'dart:async';
import 'package:chuck_normis_app/data/services/websocket_service.dart';
import 'package:chuck_normis_app/domain/models/chat_message.dart';

abstract class ChatRepository {
  Stream<String> get messages;
  Stream<ConnectionStatus> get status;
  Future<void> connect();
  void sendMessage(String message);
  void dispose();
  Future<List<ChatMessage>> getChatHistory();
  Future<void> saveChatMessage(ChatMessage message);
  Future<void> deleteOldChatMessages();
}
