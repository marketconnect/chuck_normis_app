import 'dart:math';
import 'package:provider/provider.dart';
import 'package:chuck_normis_app/application/agent_entry_notifier.dart';
import 'package:chuck_normis_app/data/services/websocket_service.dart';
import 'package:chuck_normis_app/domain/models/training_session.dart' hide Set;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chuck_normis_app/domain/models/chat_message.dart';
import 'package:chuck_normis_app/presentation/edit_workout_screen.dart';
import 'package:chuck_normis_app/domain/models/clarifying_form.dart';
import 'package:chuck_normis_app/presentation/clarifying_question_form_screen.dart';

class AgentEntry extends StatelessWidget {
  const AgentEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentEntryView();
  }
}

class AgentEntryView extends StatefulWidget {
  const AgentEntryView({super.key});

  @override
  State<AgentEntryView> createState() => _AgentEntryViewState();
}

class _AgentEntryViewState extends State<AgentEntryView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _openedClarifying = <String>{};

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AgentEntryNotifier>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Auto-open clarifying form for newest unseen clarifying message
      final clarifyingToOpen = notifier.messages
          .where(
            (m) =>
                m.type == MessageType.clarifying &&
                !_openedClarifying.contains(m.id),
          )
          .toList();

      if (clarifyingToOpen.isNotEmpty) {
        final m = clarifyingToOpen.last;
        _openedClarifying.add(m.id);
        Future.microtask(() async {
          final result = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                ClarifyingQuestionFormScreen(form: m.clarifyingForm!),
          );
          if (result != null && result.trim().isNotEmpty) {
            if (context.mounted) {
              context.read<AgentEntryNotifier>().sendMessage(result.trim());
            }
          }
        });
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatusIndicator(notifier.connectionStatus),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount:
                  notifier.messages.length +
                  (notifier.isWaitingForResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (notifier.isWaitingForResponse &&
                    index == notifier.messages.length) {
                  return const _TypingIndicator();
                }
                final message = notifier.messages[index];
                // В зависимости от типа сообщения показываем разный виджет
                switch (message.type) {
                  case MessageType.text:
                    return _TextMessageBubble(message: message);
                  case MessageType.workout:
                    return _WorkoutMessageBubble(
                      trainingSession: message.trainingSession!,
                    );
                  case MessageType.clarifying:
                    return _ClarifyingMessageBubble(
                      form: message.clarifyingForm!,
                    );
                  case MessageType.error:
                    return _ErrorMessageBubble(message: message);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildMessageInput(notifier),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AgentEntryNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(labelText: 'Позвать Чака'),
            onSubmitted: (_) => _sendMessage(notifier),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: notifier.isWaitingForResponse
              ? null
              : () => _sendMessage(notifier),
          icon: const Icon(Icons.send),
          tooltip: 'Отправить',
        ),
      ],
    );
  }

  void _sendMessage(AgentEntryNotifier notifier) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();

    final isConnected = notifier.connectionStatus == ConnectionStatus.connected;
    if (!isConnected) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Нет соединения. Сообщение поставлено в очередь и будет отправлено при восстановлении.',
          ),
          action: SnackBarAction(
            label: 'Подключить',
            onPressed: () {
              notifier.initiateConnection();
            },
          ),
        ),
      );
    }

    notifier.sendMessage(text);
    // Dismiss keyboard after sending
    FocusScope.of(context).unfocus();
    _textController.clear();
  }

  Widget _buildStatusIndicator(ConnectionStatus status) {
    if (status == ConnectionStatus.connected) {
      return const SizedBox.shrink();
    }
    String text;
    Color color;
    switch (status) {
      case ConnectionStatus.connecting:
        text = 'Подключение...';
        color = Colors.orange;
        break;
      case ConnectionStatus.disconnected:
        text = 'Отключено';
        color = Colors.grey;
        break;
      case ConnectionStatus.error:
        text = 'Ошибка соединения';
        color = Colors.red;
        break;
      case ConnectionStatus.connected:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color),
      ),
    );
  }
}

// Переименовываем _MessageBubble в _TextMessageBubble
class _TextMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _TextMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserMessage = message.sender == MessageSender.user;
    final alignment = isUserMessage
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = isUserMessage
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Align(
      alignment: alignment,
      child: Card(
        color: color,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SelectableText(message.text!),
        ),
      ),
    );
  }
}

// Новый виджет для отображения тренировки
class _WorkoutMessageBubble extends StatelessWidget {
  final TrainingSession trainingSession;
  const _WorkoutMessageBubble({required this.trainingSession});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Готовая тренировка:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(trainingSession.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Блоков: ${trainingSession.blocks.length}'),
              // Could add more details here
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Открыть и сохранить'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditWorkoutScreen(trainingSession: trainingSession),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClarifyingMessageBubble extends StatelessWidget {
  final ClarifyingForm form;
  const _ClarifyingMessageBubble({required this.form});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Уточняющие вопросы', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(form.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.question_answer),
                  label: const Text('Ответить'),
                  onPressed: () async {
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return ClarifyingQuestionFormScreen(form: form);
                      },
                    );
                    if (!context.mounted) return;
                    if (result != null && result.trim().isNotEmpty) {
                      context.read<AgentEntryNotifier>().sendMessage(
                        result.trim(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _ErrorMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        color: theme.colorScheme.errorContainer,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SelectableText(
                  message.text!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final bounce = sin(
                    (_controller.value * 2 * pi) + (index * pi * 0.5),
                  ).abs();
                  return Transform.translate(
                    offset: Offset(0, -bounce * 6), // Bounce height
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
