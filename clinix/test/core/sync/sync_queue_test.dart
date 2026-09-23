import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/core/sync/sync_repository.dart';

void main() {
  late AppDatabase database;
  late SyncRepository repository;
  late SyncQueue queue;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SyncRepository(database);
    queue = SyncQueue(repository);
  });

  tearDown(() async {
    await database.close();
  });

  test('enqueue creates a pending sync operation', () async {
    await queue.enqueue(
      entityType: 'PATIENT',
      entityId: 'P-1001',
      operationType: 'UPDATE',
      payload: {
        'id': 'P-1001',
        'status': 'Stable',
      },
      baseVersion: 1,
    );

    final operations =
        await repository.getPendingOperations();

    expect(operations, hasLength(1));

    expect(
      operations.first.entityType,
      'PATIENT',
    );

    expect(
      operations.first.entityId,
      'P-1001',
    );

    expect(
      operations.first.operationType,
      'UPDATE',
    );

    expect(
      operations.first.baseVersion,
      1,
    );

    expect(
      operations.first.status,
      'PENDING',
    );
  });

  test('pendingCount returns number of pending operations', () async {
    await queue.enqueue(
      entityType: 'PATIENT',
      entityId: 'P-1001',
      operationType: 'UPDATE',
      payload: {
        'status': 'Stable',
      },
    );

    await queue.enqueue(
      entityType: 'TASK',
      entityId: 'T-1001',
      operationType: 'UPDATE',
      payload: {
        'status': 'completed',
      },
    );

    expect(
      await queue.pendingCount(),
      2,
    );
  });

  test('hasPendingOperations returns true when queue is not empty', () async {
    expect(
      await queue.hasPendingOperations(),
      false,
    );

    await queue.enqueue(
      entityType: 'MESSAGE',
      entityId: 'MSG-001',
      operationType: 'CREATE',
      payload: {
        'content': 'Hello',
      },
    );

    expect(
      await queue.hasPendingOperations(),
      true,
    );
  });

  test('hasPendingOperations returns false after operation is completed', () async {
    await queue.enqueue(
      entityType: 'PATIENT',
      entityId: 'P-1001',
      operationType: 'UPDATE',
      payload: {
        'status': 'Stable',
      },
    );

    final operations =
        await repository.getPendingOperations();

    expect(operations, hasLength(1));

    await repository.markAsCompleted(
      operations.first.operationId,
    );

    expect(
      await queue.hasPendingOperations(),
      false,
    );

    expect(
      await queue.pendingCount(),
      0,
    );
  });
}