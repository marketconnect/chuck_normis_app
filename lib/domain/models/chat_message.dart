import 'package:chuck_normis_app/domain/models/training_session.dart';
import 'package:chuck_normis_app/domain/models/clarifying_form.dart';

enum MessageSender { user, assistant }

enum MessageType { text, workout, clarifying, error }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageType type;

  final String? text;
  final TrainingSession? trainingSession;
  final ClarifyingForm? clarifyingForm;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.timestamp,
    this.type = MessageType.text,
    this.text,
    this.trainingSession,
    this.clarifyingForm,
  }) : assert(
         (type == MessageType.text && text != null) ||
             (type == MessageType.workout && trainingSession != null) ||
             (type == MessageType.clarifying && clarifyingForm != null) ||
             (type == MessageType.error && text != null),
         'Для текстовых сообщений нужен text, для тренировок — trainingSession, для уточняющих форм — clarifyingForm.',
       );

  // Для простоты в БД будем сохранять только текстовые сообщения
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sender': sender.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      text: map['text'],
      sender: MessageSender.values.byName(map['sender']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: MessageType.text, // Все сообщения из БД считаем текстовыми
    );
  }
}
