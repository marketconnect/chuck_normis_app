import 'package:chuck_normis_app/domain/models/note.dart';
import 'package:chuck_normis_app/domain/models/training_info.dart';

abstract class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(String id);
  Future<void> saveNote(Note note);
  Future<void> deleteNote(String id);
  Future<List<TrainingInfo>> getAllTrainings();
}
