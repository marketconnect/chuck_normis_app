import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuck_normis_app/domain/models/note.dart';
import 'package:chuck_normis_app/domain/models/training_info.dart';
import 'package:chuck_normis_app/domain/repositories/note_repository.dart';

class NotesNotifier extends ChangeNotifier {
  final NoteRepository _noteRepository;
  final ImagePicker _imagePicker = ImagePicker();

  NotesNotifier(this._noteRepository) {
    loadNotes();
  }

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TrainingInfo> _trainings = [];
  List<TrainingInfo> get trainings => _trainings;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    _notes = await _noteRepository.getAllNotes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTrainings() async {
    _trainings = await _noteRepository.getAllTrainings();
    notifyListeners();
  }

  Future<Note?> fetchNoteById(String id) {
    return _noteRepository.getNoteById(id);
  }

  Future<void> saveNote(Note note) async {
    await _noteRepository.saveNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _noteRepository.deleteNote(id);
    await loadNotes();
  }

  String generateId() {
    return 'note-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '')}-${Random().nextInt(999999).toRadixString(16)}';
  }

  Future<String?> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      return pickedFile?.path;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
