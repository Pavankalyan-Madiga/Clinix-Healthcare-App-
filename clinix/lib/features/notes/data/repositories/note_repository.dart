import 'package:clinix/core/database/daos/notes_dao.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../model/note_model.dart';

class NoteRepository {
  final NotesDao _dao;

  NoteRepository(AppDatabase database) : _dao = database.notesDao;

  Future<List<NoteModel>> getNotesByPatientId(
    String patientId,
  ) async {
    final notes = await _dao.getNotesByPatientId(patientId);

    return notes.map(_toModel).toList();
  }

  Future<NoteModel?> getNoteById(String id) async {
    final note = await _dao.getNoteById(id);

    if (note == null) {
      return null;
    }

    return _toModel(note);
  }

  Future<void> addNote(NoteModel note) async {
    await _dao.insertNote(
      NotesCompanion.insert(
        id: note.id,
        patientId: note.patientId,
        content: note.content,
        author: note.author,
        createdAt: note.createdAt,
      ),
    );
  }

  Future<void> updateNote(NoteModel note) async {
    await _dao.updateNote(
      NotesCompanion(
        id: Value(note.id),
        patientId: Value(note.patientId),
        content: Value(note.content),
        author: Value(note.author),
        createdAt: Value(note.createdAt),
      ),
    );
  }

  Future<void> deleteNote(String id) async {
    await _dao.deleteNote(id);
  }

  NoteModel _toModel(Note note) {
    return NoteModel(
      id: note.id,
      patientId: note.patientId,
      content: note.content,
      author: note.author,
      createdAt: note.createdAt,
    );
  }
}