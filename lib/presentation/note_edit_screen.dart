import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chuck_normis_app/application/notes_notifier.dart';
import 'package:chuck_normis_app/domain/models/note.dart';
import 'package:chuck_normis_app/domain/models/training_info.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({super.key, this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late Note _note;
  bool _isNewNote = true;

  final _textController = TextEditingController();
  final _tagsController = TextEditingController();

  final Map<String, String> _noteTypes = {
    'workout': '🏋️ Тренировка',
    'sleep': '🌙 Сон',
    'mood': '💭 Настроение',
    'nutrition': '🍎 Питание',
    'recovery': '🧘 Восстановление',
    'insight': '💡 Инсайт',
  };

  final List<String> _moodEmojis = [
    '😀',
    '🙂',
    '😐',
    '😕',
    '😫',
    '💪',
    '🧘',
    '🔥',
  ];

  @override
  void initState() {
    super.initState();
    final notifier = context.read<NotesNotifier>();
    if (widget.note != null) {
      _note = widget.note!.copyWith();
      _isNewNote = false;
    } else {
      _note = Note(
        id: notifier.generateId(),
        type: 'mood',
        createdAt: DateTime.now(),
        textContent: '',
      );
    }
    _textController.text = _note.textContent;
    _tagsController.text = _note.tags.join(', ');

    // Fetch trainings if the type is workout
    if (_note.type == 'workout') {
      notifier.loadTrainings();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    _note.textContent = _textController.text.trim();
    _note.tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_note.textContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заметка не может быть пустой')),
      );
      return;
    }

    final notifier = context.read<NotesNotifier>();
    await notifier.saveNote(_note);

    if (mounted) {
      HapticFeedback.vibrate();
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _note.createdAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_note.createdAt),
    );
    if (time == null) return;

    setState(() {
      _note.createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                _addImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Камера'),
              onTap: () {
                _addImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addImage(ImageSource source) async {
    final path = await context.read<NotesNotifier>().pickImage(source);
    if (path != null) {
      setState(() {
        _note.photoPaths.add(path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotesNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewNote ? 'Новая заметка' : 'Редактировать'),
        actions: [
          if (!_isNewNote)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Удалить заметку?'),
                    content: const Text('Это действие нельзя будет отменить.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await notifier.deleteNote(_note.id);
                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNote),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Тип заметки'),
          Wrap(
            spacing: 8.0,
            children: _noteTypes.entries.map((entry) {
              return ChoiceChip(
                label: Text(entry.value),
                selected: _note.type == entry.key,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _note.type = entry.key;
                      if (_note.type == 'workout') {
                        notifier.loadTrainings();
                      } else {
                        _note.workoutId = null;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          if (_note.type == 'workout') ...[
            const SizedBox(height: 16),
            _buildWorkoutSelector(notifier.trainings),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle('Дата и время'),
          InkWell(
            onTap: _pickDateTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                DateFormat('dd MMMM yyyy, HH:mm').format(_note.createdAt),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Настроение'),
          Wrap(
            spacing: 8.0,
            children: _moodEmojis.map((emoji) {
              return ChoiceChip(
                label: Text(emoji, style: const TextStyle(fontSize: 24)),
                selected: _note.moodEmoji == emoji,
                onSelected: (selected) {
                  setState(() {
                    _note.moodEmoji = selected ? emoji : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Основной текст'),
          TextField(
            controller: _textController,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Как прошёл день? Что запомнилось?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Теги (через запятую)'),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              hintText: 'энергия, усталость, фокус...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Фотографии'),
          _buildPhotoGallery(),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Скрыть от Чака'),
            value: _note.isHiddenFromAi,
            onChanged: (value) {
              setState(() {
                _note.isHiddenFromAi = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildWorkoutSelector(List<TrainingInfo> trainings) {
    if (trainings.isEmpty) {
      return const Text('Нет доступных тренировок.');
    }
    return DropdownButtonFormField<String>(
      value: _note.workoutId,
      hint: const Text('Выберите тренировку'),
      onChanged: (String? newValue) {
        setState(() {
          _note.workoutId = newValue;
        });
      },
      items: trainings.map<DropdownMenuItem<String>>((TrainingInfo training) {
        return DropdownMenuItem<String>(
          value: training.id,
          child: Text(training.name),
        );
      }).toList(),
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }

  Widget _buildPhotoGallery() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        ..._note.photoPaths.map(
          (path) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _note.photoPaths.remove(path);
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _showImageSourceActionSheet,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }
}
