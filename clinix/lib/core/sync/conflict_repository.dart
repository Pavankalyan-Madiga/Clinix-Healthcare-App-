import 'dart:convert';

import 'package:clinix/core/database/daos/sync_conflicts_dao.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ConflictRepository {
  final SyncConflictsDao _dao;

  ConflictRepository(AppDatabase database)
      : _dao = database.syncConflictsDao;

  Future<List<SyncConflict>> getConflicts() async {
    final conflicts = await _dao.getAllConflicts();

    print(
      '[Conflict] Local conflicts: ${conflicts.length}',
    );

    for (final conflict in conflicts) {
      print(
        '[Conflict] '
        'operation=${conflict.operationId} '
        '${conflict.entityType}/${conflict.entityId} '
        'client=${conflict.clientVersion} '
        'server=${conflict.serverVersion} '
        'status=${conflict.status}',
      );
    }

    return conflicts;
  }

  Future<SyncConflict?> getConflict(
    String operationId,
  ) {
    return _dao.getConflictByOperationId(
      operationId,
    );
  }

  Future<void> addConflict({
    required String operationId,
    required String entityType,
    required String entityId,
    required int clientVersion,
    required int serverVersion,
    Map<String, dynamic>? clientPayload,
    Map<String, dynamic>? serverPayload,
  }) async {
    await _dao.insertConflict(
      SyncConflictsCompanion.insert(
        id: operationId,
        operationId: operationId,
        entityType: entityType,
        entityId: entityId,
        clientVersion: clientVersion,
        serverVersion: serverVersion,
        clientPayload: Value(
          clientPayload == null
              ? null
              : jsonEncode(clientPayload),
        ),
        serverPayload: Value(
          serverPayload == null
              ? null
              : jsonEncode(serverPayload),
        ),
        status: 'PENDING',
        createdAt: DateTime.now(),
      ),
    );

    print(
      '[Conflict] Stored conflict '
      '$entityType/$entityId '
      'client=$clientVersion '
      'server=$serverVersion',
    );
  }

  Future<void> resolveConflict(
    String operationId,
  ) async {
    final conflict =
        await _dao.getConflictByOperationId(
      operationId,
    );

    if (conflict == null) {
      return;
    }

    await _dao.insertConflict(
      SyncConflictsCompanion(
        id: Value(conflict.id),
        operationId: Value(
          conflict.operationId,
        ),
        entityType: Value(
          conflict.entityType,
        ),
        entityId: Value(
          conflict.entityId,
        ),
        clientVersion: Value(
          conflict.clientVersion,
        ),
        serverVersion: Value(
          conflict.serverVersion,
        ),
        clientPayload: Value(
          conflict.clientPayload,
        ),
        serverPayload: Value(
          conflict.serverPayload,
        ),
        status: const Value('RESOLVED'),
        createdAt: Value(
          conflict.createdAt,
        ),
      ),
    );
  }

  Future<void> deleteConflict(
    String operationId,
  ) {
    return _dao.deleteConflict(operationId);
  }

  Future<void> clearAllConflicts() async {
    final conflicts = await _dao.getAllConflicts();

    for (final conflict in conflicts) {
      await _dao.deleteConflict(
        conflict.operationId,
      );
    }

    print(
      '[Conflict] Cleared ${conflicts.length} conflicts',
    );
  }
}