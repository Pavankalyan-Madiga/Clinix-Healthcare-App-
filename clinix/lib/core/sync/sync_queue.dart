import 'dart:convert';

import 'sync_repository.dart';

class SyncQueue {
  final SyncRepository _repository;

  SyncQueue(this._repository);

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
    int? baseVersion,
  }) async {
    final operationId =
        '${entityType}_${entityId}_${DateTime.now().microsecondsSinceEpoch}';

    await _repository.addOperation(
      id: operationId,
      operationId: operationId,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: jsonEncode(payload),
      baseVersion: baseVersion,
    );
  }

  Future<bool> hasPendingOperations() async {
    final operations = await _repository.getPendingOperations();
    return operations.isNotEmpty;
  }

  Future<int> pendingCount() async {
    final operations = await _repository.getPendingOperations();
    return operations.length;
  }
}