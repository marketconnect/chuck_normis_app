import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chuck_normis_app/application/notes_notifier.dart';
import 'package:chuck_normis_app/domain/models/note.dart';
import 'package:chuck_normis_app/presentation/note_edit_screen.dart';
import 'package:chuck_normis_app/presentation/note_view_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NotesScreenView();
  }
}

class _NotesScreenView extends StatefulWidget {
  const _NotesScreenView();

  @override
  State<_NotesScreenView> createState() => _NotesScreenViewState();
}

class _NotesScreenViewState extends State<_NotesScreenView> {
  @override
  void initState() {
    super.initState();
    // Refresh notes when the screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesNotifier>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotesNotifier>();

    return Scaffold(
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifier.notes.isEmpty
              ? _buildEmptyState(context)
              : _buildNotesList(notifier.notes),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NoteEditScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ещё ни одной записи.\nЧак считает, что пора начать.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NoteEditScreen()),
              );
            },
            child: const Text('Создать заметку'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteCard(note: note);
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;

  const _NoteCard({required this.note});

  static const Map<String, String> typeEmojis = {
    'workout': '🏋️',
    'sleep': '🌙',
    'mood': '💭',
    'nutrition': '🍎',
    'recovery': '🧘',
    'insight': '💡',
  };

  @override
  Widget build(BuildContext context) {
    final typeEmoji = typeEmojis[note.type] ?? '📝';
    final moodEmoji = note.moodEmoji ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteViewScreen(noteId: note.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$typeEmoji $moodEmoji',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.textContent,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}