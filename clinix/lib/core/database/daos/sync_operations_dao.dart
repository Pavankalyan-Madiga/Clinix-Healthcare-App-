import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_operations_table.dart';

part 'sync_operations_dao.g.dart';

@DriftAccessor(tables: [SyncOperations])
class SyncOperationsDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOperationsDaoMixin {
  SyncOperationsDao(super.db);

  Future<List<SyncOperation>> getPendingOperations() {
    return (select(syncOperations)
          ..where(
            (operation) =>
                operation.status.equals('PENDING') |
                operation.status.equals('FAILED'),
          )
          ..orderBy([
            (operation) =>
                OrderingTerm.asc(operation.createdAt),
          ]))
        .get();
  }

  Future<List<SyncOperation>> getAllOperations() {
    return (select(syncOperations)
          ..orderBy([
            (operation) =>
                OrderingTerm.asc(operation.createdAt),
          ]))
        .get();
  }

  Future<SyncOperation?> getOperationById(
    String operationId,
  ) {
    return (select(syncOperations)
          ..where(
            (operation) =>
                operation.operationId.equals(operationId),
          ))
        .getSingleOrNull();
  }

  Future<void> insertOperation(
    SyncOperationsCompanion operation,
  ) {
    return into(syncOperations).insert(operation);
  }

  Future<void> updateOperation(
    String operationId,
    SyncOperationsCompanion operation,
  ) {
    return (update(syncOperations)
          ..where(
            (item) =>
                item.operationId.equals(operationId),
          ))
        .write(operation);
  }

  Future<void> markAsSyncing(
    String operationId,
  ) {
    return (update(syncOperations)
          ..where(
            (operation) =>
                operation.operationId.equals(operationId),
          ))
        .write(
      SyncOperationsCompanion(
        status: const Value('SYNCING'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAsCompleted(
    String operationId,
  ) {
    return (update(syncOperations)
          ..where(
            (operation) =>
                operation.operationId.equals(operationId),
          ))
        .write(
      SyncOperationsCompanion(
        status: const Value('COMPLETED'),
        updatedAt: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markAsFailed(
    String operationId,
    String error,
  ) {
    return (update(syncOperations)
          ..where(
            (operation) =>
                operation.operationId.equals(operationId),
          ))
        .write(
      SyncOperationsCompanion(
        status: const Value('FAILED'),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAsConflict(
    String operationId,
  ) {
    return (update(syncOperations)
          ..where(
            (operation) =>
                operation.operationId.equals(operationId),
          ))
        .write(
      SyncOperationsCompanion(
        status: const Value('CONFLICT'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> incrementRetryCount(
    String operationId,
  ) async {
    final operation =
        await getOperationById(operationId);

    if (operation == null) {
      return;
    }

    await (update(syncOperations)
          ..where(
            (item) =>
                item.operationId.equals(operationId),
          ))
        .write(
      SyncOperationsCompanion(
        retryCount: Value(
          operation.retryCount + 1,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteOperation(
    String operationId,
  ) {
    return (delete(syncOperations)
          ..where(
            (operation) =>
                operation.operationId.equals(operationId),
          ))
        .go();
  }

  Future<void> clearAllOperations() {
    return delete(syncOperations).go();
  }
}