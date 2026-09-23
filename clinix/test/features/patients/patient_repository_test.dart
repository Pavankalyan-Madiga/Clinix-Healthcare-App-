import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/core/sync/sync_repository.dart';
import 'package:clinix/features/patients/data/model/patient_model.dart';
import 'package:clinix/features/patients/data/repositories/patient_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncRepository syncRepository;
  late SyncQueue syncQueue;
  late PatientRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    syncRepository = SyncRepository(database);
    syncQueue = SyncQueue(syncRepository);

    repository = PatientRepository(
      database,
      syncQueue,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'patient can be inserted and read from local database',
    () async {
      final patient = PatientModel(
        id: 'P-TEST-001',
        firstName: 'Test',
        lastName: 'Patient',
        dateOfBirth: '1990-01-01',
        gender: 'Male',
        room: '201',
        condition: 'Stable',
        status: 'Stable',
      );

      await repository.insertPatient(patient);

      final result =
          await repository.getPatientById(
        'P-TEST-001',
      );

      expect(result, isNotNull);
      expect(result!.id, 'P-TEST-001');
      expect(result.firstName, 'Test');
      expect(result.lastName, 'Patient');
      expect(result.room, '201');
      expect(result.condition, 'Stable');
      expect(result.status, 'Stable');
    },
  );

  test(
    'patient update creates a pending sync operation',
    () async {
      final patient = PatientModel(
        id: 'P-TEST-002',
        firstName: 'Offline',
        lastName: 'Patient',
        dateOfBirth: '1985-05-10',
        gender: 'Female',
        room: '202',
        condition: 'Diabetes',
        status: 'Stable',
      );

      await repository.insertPatient(patient);

      final updatedPatient = PatientModel(
        id: 'P-TEST-002',
        firstName: 'Offline',
        lastName: 'Patient',
        dateOfBirth: '1985-05-10',
        gender: 'Female',
        room: '202',
        condition: 'Diabetes',
        status: 'Needs Attention',
      );

      await repository.updatePatient(
        updatedPatient,
      );

      final pendingOperations =
          await syncRepository.getPendingOperations();

      expect(
        pendingOperations.length,
        1,
      );

      expect(
        pendingOperations.first.entityType,
        'PATIENT',
      );

      expect(
        pendingOperations.first.entityId,
        'P-TEST-002',
      );

      expect(
        pendingOperations.first.operationType,
        'UPDATE',
      );
    },
  );

  test(
    'patient update is persisted locally',
    () async {
      final patient = PatientModel(
        id: 'P-TEST-003',
        firstName: 'Persistent',
        lastName: 'Patient',
        dateOfBirth: '1978-08-20',
        gender: 'Male',
        room: '203',
        condition: 'Hypertension',
        status: 'Stable',
      );

      await repository.insertPatient(patient);

      final updatedPatient = PatientModel(
        id: 'P-TEST-003',
        firstName: 'Persistent',
        lastName: 'Patient',
        dateOfBirth: '1978-08-20',
        gender: 'Male',
        room: '204',
        condition: 'Hypertension',
        status: 'Needs Attention',
      );

      await repository.updatePatient(
        updatedPatient,
      );

      final result =
          await repository.getPatientById(
        'P-TEST-003',
      );

      expect(result, isNotNull);
      expect(
        result!.status,
        'Needs Attention',
      );
      expect(
        result.room,
        '204',
      );
    },
  );
}