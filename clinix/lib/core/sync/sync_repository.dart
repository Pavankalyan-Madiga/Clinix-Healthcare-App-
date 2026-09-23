import 'package:clinix/core/database/daos/sync_operations_dao.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SyncRepository {
  final SyncOperationsDao _dao;

  SyncRepository(AppDatabase database)
      : _dao = database.syncOperationsDao;

  Future<List<SyncOperation>> getPendingOperations() {
    return _dao.getPendingOperations();
  }

  Future<List<SyncOperation>> getAllOperations() {
    return _dao.getAllOperations();
  }

  Future<SyncOperation?> getOperationById(
    String operationId,
  ) {
    return _dao.getOperationById(operationId);
  }

  Future<void> addOperation({
    required String id,
    required String operationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payload,
    int? baseVersion,
  }) async {
    await _dao.insertOperation(
      SyncOperationsCompanion.insert(
        id: id,
        operationId: operationId,
        entityType: entityType,
        entityId: entityId,
        operationType: operationType,
        payload: payload,
        status: 'PENDING',
        baseVersion: Value(baseVersion),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> markAsSyncing(
    String operationId,
  ) {
    return _dao.markAsSyncing(operationId);
  }

  Future<void> markAsCompleted(
    String operationId,
  ) {
    return _dao.markAsCompleted(operationId);
  }

  Future<void> resolveOperation(
    String operationId,
  ) {
    return _dao.markAsCompleted(operationId);
  }

  Future<void> markAsFailed(
    String operationId,
    String error,
  ) {
    return _dao.markAsFailed(
      operationId,
      error,
    );
  }

  Future<void> markAsConflict(
    String operationId,
  ) {
    return _dao.markAsConflict(operationId);
  }

  Future<void> incrementRetryCount(
    String operationId,
  ) {
    return _dao.incrementRetryCount(operationId);
  }

  Future<void> deleteOperation(
    String operationId,
  ) {
    return _dao.deleteOperation(operationId);
  }

  Future<void> clearAllOperations() {
    return _dao.clearAllOperations();
  }
}