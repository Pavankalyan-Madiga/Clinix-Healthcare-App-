import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/voice_notes_table.dart';

part 'voice_note_dao.g.dart';

@DriftAccessor(tables: [VoiceNotes])
class VoiceNoteDao extends DatabaseAccessor<AppDatabase>
    with _$VoiceNoteDaoMixin {
  VoiceNoteDao(AppDatabase db) : super(db);

  Future<List<VoiceNote>> getVoiceNotesByPatient(
    String patientId,
  ) {
    final query = select(voiceNotes)
      ..where((voiceNote) => voiceNote.patientId.equals(patientId))
      ..orderBy([
        (voiceNote) => OrderingTerm.desc(voiceNote.createdAt),
      ]);

    return query.get();
  }

  Stream<List<VoiceNote>> watchVoiceNotesByPatient(
    String patientId,
  ) {
    final query = select(voiceNotes)
      ..where((voiceNote) => voiceNote.patientId.equals(patientId))
      ..orderBy([
        (voiceNote) => OrderingTerm.desc(voiceNote.createdAt),
      ]);

    return query.watch();
  }

  Future<VoiceNote?> getVoiceNoteById(String id) {
    return (select(voiceNotes)
          ..where((voiceNote) => voiceNote.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertVoiceNote(
    VoiceNotesCompanion voiceNote,
  ) async {
    await into(voiceNotes).insert(voiceNote);
  }

  Future<void> deleteVoiceNote(String id) async {
    await (delete(voiceNotes)
          ..where((voiceNote) => voiceNote.id.equals(id)))
        .go();
  }

  Future<void> updateStatus(
    String id,
    String status,
  ) async {
    await (update(voiceNotes)
          ..where((voiceNote) => voiceNote.id.equals(id)))
        .write(
      VoiceNotesCompanion(
        status: Value(status),
      ),
    );
  }
}