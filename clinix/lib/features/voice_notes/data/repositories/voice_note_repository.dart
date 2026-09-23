import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/features/voice_notes/data/model/voice_note_model.dart';

class VoiceNoteRepository {
  final AppDatabase _database;
  final SyncQueue _syncQueue;

  VoiceNoteRepository(
    this._database,
    this._syncQueue,
  );

  Future<List<VoiceNoteModel>> getVoiceNotesByPatient(
    String patientId,
  ) async {
    final notes = await _database.voiceNoteDao.getVoiceNotesByPatient(
      patientId,
    );

    return notes.map(_toModel).toList();
  }

  Stream<List<VoiceNoteModel>> watchVoiceNotesByPatient(
    String patientId,
  ) {
    return _database.voiceNoteDao
        .watchVoiceNotesByPatient(patientId)
        .map(
          (notes) => notes.map(_toModel).toList(),
        );
  }

  Future<VoiceNoteModel> addVoiceNote({
    required String patientId,
    required String filePath,
    required int durationSeconds,
  }) async {
    final voiceNote = VoiceNoteModel(
      id: 'VN-${DateTime.now().microsecondsSinceEpoch}',
      patientId: patientId,
      filePath: filePath,
      createdAt: DateTime.now().toIso8601String(),
      durationSeconds: durationSeconds,
    );

    await _database.voiceNoteDao.insertVoiceNote(
      VoiceNotesCompanion.insert(
        id: voiceNote.id,
        patientId: voiceNote.patientId,
        filePath: voiceNote.filePath,
        createdAt: DateTime.parse(voiceNote.createdAt),
        durationSeconds: voiceNote.durationSeconds,
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'VOICE_NOTE',
      entityId: voiceNote.id,
      operationType: 'CREATE',
      payload: voiceNote.toJson(),
      baseVersion: 1,
    );

    return voiceNote;
  }

  Future<void> deleteVoiceNote(String id) async {
    final existing = await _database.voiceNoteDao.getVoiceNoteById(id);

    if (existing == null) return;

    await _database.voiceNoteDao.deleteVoiceNote(id);

    await _syncQueue.enqueue(
      entityType: 'VOICE_NOTE',
      entityId: id,
      operationType: 'DELETE',
      payload: {
        'id': id,
        'patient_id': existing.patientId,
        'file_path': existing.filePath,
      },
      baseVersion: 1,
    );
  }

  VoiceNoteModel _toModel(VoiceNote note) {
    return VoiceNoteModel(
      id: note.id,
      patientId: note.patientId,
      filePath: note.filePath,
      createdAt: note.createdAt.toIso8601String(),
      durationSeconds: note.durationSeconds,
    );
  }
}