import 'package:chuck_normis_app/data/datasources/database_helper.dart';
import 'package:chuck_normis_app/domain/models/note.dart';
import 'package:chuck_normis_app/domain/models/training_info.dart';
import 'package:chuck_normis_app/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DatabaseHelper _databaseHelper;

  NoteRepositoryImpl(this._databaseHelper);

  @override
  Future<void> deleteNote(String id) {
    return _databaseHelper.deleteNote(id);
  }

  @override
  Future<List<Note>> getAllNotes() {
    return _databaseHelper.getAllNotes();
  }

  @override
  Future<Note?> getNoteById(String id) {
    return _databaseHelper.getNoteById(id);
  }

  @override
  Future<void> saveNote(Note note) {
    return _databaseHelper.saveNote(note);
  }

  @override
  Future<List<TrainingInfo>> getAllTrainings() {
    return _databaseHelper.getAllTrainings();
  }
}
