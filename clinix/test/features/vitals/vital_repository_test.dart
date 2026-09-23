import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/core/sync/sync_repository.dart';
import 'package:clinix/features/vitals/data/model/vital_model.dart';
import 'package:clinix/features/vitals/data/repositories/vital_repository.dart';
import 'package:clinix/features/vitals/domain/entities/vital.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncQueue syncQueue;
  late VitalRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    final syncRepository = SyncRepository(database);

    syncQueue = SyncQueue(syncRepository);

    repository = VitalRepository(
      database,
      syncQueue,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts and retrieves a vital', () async {
    final vital = VitalModel(
      id: 'V-1001',
      patientId: 'P-1001',
      type: VitalType.heartRate,
      value: '78',
      unit: 'bpm',
      recordedAt: DateTime(2026, 9, 21, 10, 30),
      recordedBy: 'STAFF-001',
    );

    await repository.insertVital(vital);

    final result = await repository.getVitalById('V-1001');

    expect(result, isNotNull);
    expect(result!.id, 'V-1001');
    expect(result.patientId, 'P-1001');
    expect(result.type, VitalType.heartRate);
    expect(result.value, '78');
    expect(result.unit, 'bpm');
  });

  test('retrieves vitals by patient', () async {
    final vital1 = VitalModel(
      id: 'V-1001',
      patientId: 'P-1001',
      type: VitalType.heartRate,
      value: '78',
      unit: 'bpm',
      recordedAt: DateTime(2026, 9, 21, 10, 30),
      recordedBy: 'STAFF-001',
    );

    final vital2 = VitalModel(
      id: 'V-1002',
      patientId: 'P-1001',
      type: VitalType.temperature,
      value: '37.2',
      unit: '°C',
      recordedAt: DateTime(2026, 9, 21, 11, 00),
      recordedBy: 'STAFF-001',
    );

    await repository.insertVital(vital1);
    await repository.insertVital(vital2);

    final results =
        await repository.getVitalsByPatientId('P-1001');

    expect(results.length, 2);
    expect(
      results.map((vital) => vital.id),
      containsAll(['V-1001', 'V-1002']),
    );
  });

  test('inserting a vital creates a sync operation', () async {
    final vital = VitalModel(
      id: 'V-1003',
      patientId: 'P-1001',
      type: VitalType.bloodPressure,
      value: '120/80',
      unit: 'mmHg',
      recordedAt: DateTime(2026, 9, 21, 12, 00),
      recordedBy: 'STAFF-001',
    );

    await repository.insertVital(vital);

    final operations =
        await database.syncOperationsDao.getAllOperations();

    final operation = operations.firstWhere(
      (operation) =>
          operation.entityType == 'VITAL' &&
          operation.entityId == 'V-1003' &&
          operation.operationType == 'CREATE',
    );

    expect(operation.status, 'PENDING');
    expect(operation.entityType, 'VITAL');
    expect(operation.entityId, 'V-1003');
  });

  test('deletes a vital', () async {
    final vital = VitalModel(
      id: 'V-1004',
      patientId: 'P-1001',
      type: VitalType.oxygenSaturation,
      value: '98',
      unit: '%',
      recordedAt: DateTime(2026, 9, 21, 13, 00),
      recordedBy: 'STAFF-001',
    );

    await repository.insertVital(vital);

    await repository.deleteVital('V-1004');

    final result = await repository.getVitalById('V-1004');

    expect(result, isNull);
  });

  test('deleting a vital creates a delete sync operation', () async {
    final vital = VitalModel(
      id: 'V-1005',
      patientId: 'P-1001',
      type: VitalType.respiratoryRate,
      value: '18',
      unit: 'breaths/min',
      recordedAt: DateTime(2026, 9, 21, 14, 00),
      recordedBy: 'STAFF-001',
    );

    await repository.insertVital(vital);

    await repository.deleteVital('V-1005');

    final operations =
        await database.syncOperationsDao.getAllOperations();

    final deleteOperation = operations.firstWhere(
      (operation) =>
          operation.entityType == 'VITAL' &&
          operation.entityId == 'V-1005' &&
          operation.operationType == 'DELETE',
    );

    expect(deleteOperation.status, 'PENDING');
    expect(deleteOperation.operationType, 'DELETE');
  });
}