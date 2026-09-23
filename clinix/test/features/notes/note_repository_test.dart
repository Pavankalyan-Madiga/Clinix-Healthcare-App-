import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/features/notes/data/model/note_model.dart';
import 'package:clinix/features/notes/data/repositories/note_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late NoteRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = NoteRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'addNote persists note locally',
    () async {
      final note = NoteModel(
        id: 'NOTE-001',
        patientId: 'P-1001',
        content: 'Patient condition reviewed.',
        author: 'STAFF-001',
        createdAt: '2026-09-22T09:00:00Z',
      );

      await repository.addNote(note);

      final saved =
          await repository.getNoteById('NOTE-001');

      expect(saved, isNotNull);
      expect(saved!.id, 'NOTE-001');
      expect(saved.patientId, 'P-1001');
      expect(
        saved.content,
        'Patient condition reviewed.',
      );
      expect(saved.author, 'STAFF-001');
      expect(
        saved.createdAt,
        '2026-09-22T09:00:00Z',
      );
    },
  );

  test(
    'getNotesByPatientId returns patient notes',
    () async {
      await repository.addNote(
        NoteModel(
          id: 'NOTE-002',
          patientId: 'P-1002',
          content: 'First note.',
          author: 'STAFF-001',
          createdAt: '2026-09-22T09:00:00Z',
        ),
      );

      await repository.addNote(
        NoteModel(
          id: 'NOTE-003',
          patientId: 'P-1002',
          content: 'Second note.',
          author: 'STAFF-002',
          createdAt: '2026-09-22T10:00:00Z',
        ),
      );

      await repository.addNote(
        NoteModel(
          id: 'NOTE-004',
          patientId: 'P-1003',
          content: 'Different patient.',
          author: 'STAFF-001',
          createdAt: '2026-09-22T11:00:00Z',
        ),
      );

      final notes =
          await repository.getNotesByPatientId(
        'P-1002',
      );

      expect(notes, hasLength(2));
      expect(notes[0].id, 'NOTE-002');
      expect(notes[1].id, 'NOTE-003');
    },
  );

  test(
    'getNoteById returns null for missing note',
    () async {
      final note =
          await repository.getNoteById('NOTE-MISSING');

      expect(note, isNull);
    },
  );

  test(
    'updateNote persists updated content',
    () async {
      await repository.addNote(
        NoteModel(
          id: 'NOTE-005',
          patientId: 'P-1001',
          content: 'Original note.',
          author: 'STAFF-001',
          createdAt: '2026-09-22T09:00:00Z',
        ),
      );

      await repository.updateNote(
        NoteModel(
          id: 'NOTE-005',
          patientId: 'P-1001',
          content: 'Updated note.',
          author: 'STAFF-001',
          createdAt: '2026-09-22T09:00:00Z',
        ),
      );

      final note =
          await repository.getNoteById('NOTE-005');

      expect(note, isNotNull);
      expect(
        note!.content,
        'Updated note.',
      );
    },
  );

  test(
    'deleteNote removes note',
    () async {
      await repository.addNote(
        NoteModel(
          id: 'NOTE-006',
          patientId: 'P-1001',
          content: 'Temporary note.',
          author: 'STAFF-001',
          createdAt: '2026-09-22T09:00:00Z',
        ),
      );

      expect(
        await repository.getNoteById('NOTE-006'),
        isNotNull,
      );

      await repository.deleteNote('NOTE-006');

      expect(
        await repository.getNoteById('NOTE-006'),
        isNull,
      );
    },
  );

  test(
    'notes remain persisted after repository is recreated',
    () async {
      final note = NoteModel(
        id: 'NOTE-007',
        patientId: 'P-1001',
        content: 'Persistent clinical note.',
        author: 'STAFF-001',
        createdAt: '2026-09-22T12:00:00Z',
      );

      await repository.addNote(note);

      final secondRepository =
          NoteRepository(database);

      final saved =
          await secondRepository.getNoteById(
        'NOTE-007',
      );

      expect(saved, isNotNull);
      expect(
        saved!.content,
        'Persistent clinical note.',
      );
      expect(
        saved.createdAt,
        '2026-09-22T12:00:00Z',
      );
    },
  );
}