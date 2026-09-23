import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(
  tables: [
    Notes,
  ],
)
class NotesDao extends DatabaseAccessor<AppDatabase>
    with _$NotesDaoMixin {
  NotesDao(super.db);

  Future<List<Note>> getAllNotes() {
    return select(notes).get();
  }

  Future<List<Note>> getNotesByPatientId(String patientId) {
    return (select(notes)
          ..where((note) => note.patientId.equals(patientId)))
        .get();
  }

  Future<Note?> getNoteById(String id) {
    return (select(notes)
          ..where((note) => note.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertNote(NotesCompanion note) {
    return into(notes).insert(
      note,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateNote(NotesCompanion note) {
    return update(notes).write(note);
  }

  Future<void> deleteNote(String id) {
    return (delete(notes)
          ..where((note) => note.id.equals(id)))
        .go();
  }
}