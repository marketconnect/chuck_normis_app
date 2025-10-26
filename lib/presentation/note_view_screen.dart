import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chuck_normis_app/application/notes_notifier.dart';
import 'package:chuck_normis_app/domain/models/note.dart';
import 'package:chuck_normis_app/presentation/note_edit_screen.dart';

class NoteViewScreen extends StatelessWidget {
  final String noteId;

  const NoteViewScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Note?>(
      future: context.read<NotesNotifier>().fetchNoteById(noteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Не удалось загрузить заметку')),
          );
        }
        final note = snapshot.data!;
        return _NoteView(note: note);
      },
    );
  }
}

class _NoteView extends StatelessWidget {
  final Note note;

  const _NoteView({required this.note});

  static const Map<String, String> typeEmojis = {
    'workout': '🏋️ Тренировка',
    'sleep': '🌙 Сон',
    'mood': '💭 Настроение',
    'nutrition': '🍎 Питание',
    'recovery': '🧘 Восстановление',
    'insight': '💡 Инсайт',
  };

  @override
  Widget build(BuildContext context) {
    final typeDisplay = typeEmojis[note.type] ?? note.type;
    final moodEmoji = note.moodEmoji ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('dd MMMM yyyy, HH:mm').format(note.createdAt)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => NoteEditScreen(note: note),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Text(
                '$typeDisplay $moodEmoji',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const Divider(height: 24),
          if (note.workoutName != null) ...[
            Text(
              'Тренировка: ${note.workoutName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
          ],
          SelectableText(
            note.textContent,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (note.photoPaths.isNotEmpty) _buildPhotoGallery(context),
          if (note.tags.isNotEmpty) _buildTags(context),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                note.isHiddenFromAi ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Text(
                note.isHiddenFromAi ? 'Скрыто от Чака' : 'Видно Чаку',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фотографии', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: note.photoPaths.length,
            itemBuilder: (context, index) {
              final path = note.photoPaths[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(path),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Теги', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: note.tags.map((tag) => Chip(label: Text(tag))).toList(),
        ),
      ],
    );
  }
}
