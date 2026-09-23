import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/core/sync/sync_repository.dart';
import 'package:clinix/features/patients/data/model/patient_model.dart';
import 'package:clinix/features/patients/data/repositories/patient_repository.dart';
import 'package:clinix/features/tasks/data/model/task_model.dart';
import 'package:clinix/features/tasks/data/repositories/task_repository.dart';
import 'package:clinix/features/tasks/domain/entites/task.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncRepository syncRepository;
  late SyncQueue syncQueue;
  late PatientRepository patientRepository;
  late TaskRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    syncRepository = SyncRepository(database);
    syncQueue = SyncQueue(syncRepository);

    patientRepository = PatientRepository(
      database,
      syncQueue,
    );

    repository = TaskRepository(
      database,
      syncQueue,
      patientRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertTestPatient(
    String patientId,
  ) async {
    await patientRepository.insertPatient(
      PatientModel(
        id: patientId,
        firstName: 'Test',
        lastName: 'Patient',
        dateOfBirth: '1990-01-01',
        gender: 'Male',
        room: '201',
        condition: 'Stable',
        status: 'Stable',
      ),
    );
  }

  test(
    'task can be inserted and read from local database',
    () async {
      await insertTestPatient('P-1001');

      final task = TaskModel(
        id: 'T-TEST-001',
        patientId: 'P-1001',
        title: 'Check patient vitals',
        description:
            'Record temperature and blood pressure',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      await repository.insertTask(task);

      final result =
          await repository.getTaskById(
        'T-TEST-001',
      );

      expect(result, isNotNull);
      expect(result!.id, 'T-TEST-001');
      expect(result.patientId, 'P-1001');
      expect(
        result.title,
        'Check patient vitals',
      );
      expect(
        result.status,
        TaskStatus.pending,
      );
      expect(
        result.assignedTo,
        'STAFF-001',
      );
    },
  );

  test(
    'task creation creates a pending sync operation',
    () async {
      await insertTestPatient('P-1002');

      final task = TaskModel(
        id: 'T-TEST-002',
        patientId: 'P-1002',
        title: 'Review patient',
        description:
            'Review clinical information',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      await repository.insertTask(task);

      final pendingOperations =
          await syncRepository.getPendingOperations();

      expect(
        pendingOperations.length,
        1,
      );

      expect(
        pendingOperations.first.entityType,
        'TASK',
      );

      expect(
        pendingOperations.first.entityId,
        'T-TEST-002',
      );

      expect(
        pendingOperations.first.operationType,
        'CREATE',
      );
    },
  );

  test(
    'task update creates a pending sync operation',
    () async {
      await insertTestPatient('P-1003');

      final task = TaskModel(
        id: 'T-TEST-003',
        patientId: 'P-1003',
        title: 'Monitor patient',
        description:
            'Monitor patient condition',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      await repository.insertTask(task);

      final updatedTask = TaskModel(
        id: 'T-TEST-003',
        patientId: 'P-1003',
        title: 'Monitor patient',
        description:
            'Monitor patient condition',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.inProgress,
      );

      await repository.updateTask(
        updatedTask,
      );

      final pendingOperations =
          await syncRepository.getPendingOperations();

      expect(
        pendingOperations.length,
        3,
      );

      final taskUpdateOperations =
          pendingOperations.where(
        (operation) =>
            operation.entityType == 'TASK' &&
            operation.entityId == 'T-TEST-003' &&
            operation.operationType == 'UPDATE',
      );

      expect(
        taskUpdateOperations.length,
        1,
      );

      final taskUpdate =
          taskUpdateOperations.first;

      expect(
        taskUpdate.entityType,
        'TASK',
      );

      expect(
        taskUpdate.entityId,
        'T-TEST-003',
      );

      expect(
        taskUpdate.operationType,
        'UPDATE',
      );
    },
  );

  test(
    'task update is persisted locally',
    () async {
      await insertTestPatient('P-1004');

      final task = TaskModel(
        id: 'T-TEST-004',
        patientId: 'P-1004',
        title: 'Monitor patient',
        description:
            'Monitor patient condition',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      await repository.insertTask(task);

      final updatedTask = TaskModel(
        id: 'T-TEST-004',
        patientId: 'P-1004',
        title: 'Monitor patient',
        description:
            'Monitor patient condition',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.completed,
      );

      await repository.updateTask(
        updatedTask,
      );

      final result =
          await repository.getTaskById(
        'T-TEST-004',
      );

      expect(result, isNotNull);
      expect(
        result!.status,
        TaskStatus.completed,
      );
    },
  );

  test(
    'tasks can be retrieved by patient',
    () async {
      await insertTestPatient('P-1005');
      await insertTestPatient('P-1006');

      final task1 = TaskModel(
        id: 'T-TEST-005',
        patientId: 'P-1005',
        title: 'Check vitals',
        description:
            'Check patient vitals',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      final task2 = TaskModel(
        id: 'T-TEST-006',
        patientId: 'P-1005',
        title: 'Review notes',
        description:
            'Review clinical notes',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      final task3 = TaskModel(
        id: 'T-TEST-007',
        patientId: 'P-1006',
        title: 'Check medication',
        description:
            'Review medication schedule',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      await repository.insertTask(task1);
      await repository.insertTask(task2);
      await repository.insertTask(task3);

      final results =
          await repository.getTasksByPatientId(
        'P-1005',
      );

      expect(
        results.length,
        2,
      );

      expect(
        results.any(
          (task) => task.id == 'T-TEST-005',
        ),
        true,
      );

      expect(
        results.any(
          (task) => task.id == 'T-TEST-006',
        ),
        true,
      );

      expect(
        results.any(
          (task) => task.id == 'T-TEST-007',
        ),
        false,
      );
    },
  );

  test(
    'task can be deleted locally and creates delete operation',
    () async {
      await insertTestPatient('P-1007');

      final task = TaskModel(
        id: 'T-TEST-008',
        patientId: 'P-1007',
        title: 'Delete test task',
        description: 'Temporary task',
        assignedTo: 'STAFF-001',
        dueDate: '2026-09-22',
        status: TaskStatus.pending,
      );

      await repository.insertTask(task);

      await repository.deleteTask(
        'T-TEST-008',
      );

      final result =
          await repository.getTaskById(
        'T-TEST-008',
      );

      expect(
        result,
        isNull,
      );

      final pendingOperations =
          await syncRepository.getPendingOperations();

      final deleteOperation =
          pendingOperations.firstWhere(
        (operation) =>
            operation.entityType == 'TASK' &&
            operation.entityId == 'T-TEST-008' &&
            operation.operationType == 'DELETE',
      );

      expect(
        deleteOperation.entityType,
        'TASK',
      );

      expect(
        deleteOperation.entityId,
        'T-TEST-008',
      );

      expect(
        deleteOperation.operationType,
        'DELETE',
      );
    },
  );
}