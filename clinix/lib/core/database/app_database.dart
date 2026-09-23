import 'package:drift/drift.dart';

import 'database_connection.dart';

import 'daos/entity_versions_dao.dart';
import 'daos/message_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/patient_dao.dart';
import 'daos/sync_conflicts_dao.dart';
import 'daos/sync_operations_dao.dart';
import 'daos/task_dao.dart';
import 'daos/vital_dao.dart';
import 'daos/voice_note_dao.dart';
import 'daos/wound_photo_dao.dart';

import 'tables/entity_versions_table.dart';
import 'tables/messages_table.dart';
import 'tables/notes_table.dart';
import 'tables/patients_table.dart';
import 'tables/sync_conflicts_table.dart';
import 'tables/sync_operations_table.dart';
import 'tables/tasks_table.dart';
import 'tables/vitals_table.dart';
import 'tables/voice_notes_table.dart';
import 'tables/wound_photos_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Patients,
    Tasks,
    Notes,
    SyncOperations,
    SyncConflicts,
    EntityVersions,
    Vitals,
    Messages,
    WoundPhotos,
    VoiceNotes,
  ],
  daos: [
    PatientDao,
    TaskDao,
    NotesDao,
    SyncOperationsDao,
    SyncConflictsDao,
    EntityVersionsDao,
    VitalDao,
    MessageDao,
    WoundPhotoDao,
    VoiceNoteDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Existing migration
          }

          if (from < 3) {
            // Existing migration
          }

          if (from < 4) {
            // Existing migration
          }

          if (from < 5) {
            // Existing migration
          }

          if (from < 6) {
            // Existing migration
          }

          if (from < 8) {
            await m.addColumn(
              woundPhotos,
              woundPhotos.serverFilePath,
            );
          }

          if (from < 9) {
            await m.createTable(voiceNotes);
          }
        },
      );
}