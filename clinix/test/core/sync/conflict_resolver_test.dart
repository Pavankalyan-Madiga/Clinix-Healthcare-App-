import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/sync/conflict_resolver.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ConflictResolver resolver;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    resolver = ConflictResolver(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'applyServerPayload applies patient payload and updates version',
    () async {
      await database.patientDao.insertPatient(
        PatientsCompanion.insert(
          id: 'P-CONFLICT-001',
          firstName: 'Maria',
          lastName: 'Garcia',
          dateOfBirth: '1985-04-12',
          gender: 'Female',
          room: '101',
          condition: 'Diabetes',
          status: 'Stable',
        ),
      );

      await database.syncOperationsDao.insertOperation(
        SyncOperationsCompanion.insert(
          id: 'OP-CONFLICT-001',
          operationId: 'OP-CONFLICT-001',
          entityType: 'PATIENT',
          entityId: 'P-CONFLICT-001',
          operationType: 'UPDATE',
          payload: '{}',
          status: 'CONFLICT',
          retryCount: const Value(0),
          baseVersion: const Value(5),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await database.syncConflictsDao.insertConflict(
        SyncConflictsCompanion.insert(
          id: 'OP-CONFLICT-001',
          operationId: 'OP-CONFLICT-001',
          entityType: 'PATIENT',
          entityId: 'P-CONFLICT-001',
          clientVersion: 5,
          serverVersion: 6,
          status: 'PENDING',
          createdAt: DateTime.now(),
        ),
      );

      await resolver.applyServerPayload(
        operationId: 'OP-CONFLICT-001',
        entityType: 'PATIENT',
        entityId: 'P-CONFLICT-001',
        payload: {
          'id': 'P-CONFLICT-001',
          'first_name': 'Maria',
          'last_name': 'Garcia',
          'date_of_birth': '1985-04-12',
          'gender': 'Female',
          'room': '101',
          'condition': 'Diabetes',
          'status': 'Needs Attention',
        },
        serverVersion: 7,
      );

      final patient =
          await database.patientDao.getPatientById(
        'P-CONFLICT-001',
      );

      expect(patient, isNotNull);
      expect(
        patient!.status,
        'Needs Attention',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'PATIENT',
        'P-CONFLICT-001',
      );

      expect(version, isNotNull);
      expect(version!.version, 7);

      final operation =
          await database.syncOperationsDao.getOperationById(
        'OP-CONFLICT-001',
      );

      expect(operation, isNotNull);
      expect(
        operation!.status,
        'COMPLETED',
      );

      final conflict =
          await database.syncConflictsDao
              .getConflictByOperationId(
        'OP-CONFLICT-001',
      );

      expect(conflict, isNull);
    },
  );

  test(
    'applyServerPayload applies task payload and updates version',
    () async {
      await database.taskDao.insertTask(
        TasksCompanion.insert(
          id: 'T-CONFLICT-001',
          patientId: 'P-1001',
          title: 'Review patient',
          description: 'Review patient condition',
          assignedTo: 'STAFF-001',
          dueDate: '2026-09-22',
          status: 'pending',
        ),
      );

      await database.syncOperationsDao.insertOperation(
        SyncOperationsCompanion.insert(
          id: 'OP-CONFLICT-002',
          operationId: 'OP-CONFLICT-002',
          entityType: 'TASK',
          entityId: 'T-CONFLICT-001',
          operationType: 'UPDATE',
          payload: '{}',
          status: 'CONFLICT',
          retryCount: const Value(0),
          baseVersion: const Value(5),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await database.syncConflictsDao.insertConflict(
        SyncConflictsCompanion.insert(
          id: 'OP-CONFLICT-002',
          operationId: 'OP-CONFLICT-002',
          entityType: 'TASK',
          entityId: 'T-CONFLICT-001',
          clientVersion: 5,
          serverVersion: 6,
          status: 'PENDING',
          createdAt: DateTime.now(),
        ),
      );

      await resolver.applyServerPayload(
        operationId: 'OP-CONFLICT-002',
        entityType: 'TASK',
        entityId: 'T-CONFLICT-001',
        payload: {
          'id': 'T-CONFLICT-001',
          'patient_id': 'P-1001',
          'title': 'Review patient urgently',
          'description': 'Review updated condition',
          'assigned_to': 'STAFF-001',
          'due_date': '2026-09-22',
          'status': 'completed',
        },
        serverVersion: 8,
      );

      final task =
          await database.taskDao.getTaskById(
        'T-CONFLICT-001',
      );

      expect(task, isNotNull);
      expect(
        task!.title,
        'Review patient urgently',
      );
      expect(
        task.status,
        'completed',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'TASK',
        'T-CONFLICT-001',
      );

      expect(version, isNotNull);
      expect(version!.version, 8);

      final operation =
          await database.syncOperationsDao.getOperationById(
        'OP-CONFLICT-002',
      );

      expect(operation, isNotNull);
      expect(
        operation!.status,
        'COMPLETED',
      );

      final conflict =
          await database.syncConflictsDao
              .getConflictByOperationId(
        'OP-CONFLICT-002',
      );

      expect(conflict, isNull);
    },
  );

  test(
    'applyServerPayload rejects unsupported entity type',
    () async {
      expect(
        () => resolver.applyServerPayload(
          operationId: 'OP-CONFLICT-003',
          entityType: 'MESSAGE',
          entityId: 'MSG-001',
          payload: {
            'id': 'MSG-001',
          },
          serverVersion: 2,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );

  test(
    'applyServerPayload rejects patient payload without id',
    () async {
      expect(
        () => resolver.applyServerPayload(
          operationId: 'OP-CONFLICT-004',
          entityType: 'PATIENT',
          entityId: 'P-CONFLICT-002',
          payload: {
            'status': 'Stable',
          },
          serverVersion: 3,
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'applyServerPayload rejects task payload without id',
    () async {
      expect(
        () => resolver.applyServerPayload(
          operationId: 'OP-CONFLICT-005',
          entityType: 'TASK',
          entityId: 'T-CONFLICT-002',
          payload: {
            'status': 'completed',
          },
          serverVersion: 3,
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );
}