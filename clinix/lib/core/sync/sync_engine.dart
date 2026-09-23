import 'dart:convert';
import 'dart:io';

import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/database/daos/entity_versions_dao.dart';
import 'package:clinix/core/network/api_client.dart';
import 'package:clinix/core/network/connectivity_service.dart';
import 'package:clinix/core/sync/conflict_repository.dart';
import 'package:clinix/core/sync/sync_repository.dart';
import 'package:clinix/features/sync/retry_policy.dart';
import 'package:drift/drift.dart';

class SyncEngine {
  final SyncRepository _repository;
  final ConflictRepository _conflictRepository;
  final ConnectivityService _connectivityService;
  final ApiClient _apiClient;
  final EntityVersionsDao _versionDao;
  final AppDatabase _database;

  bool _isRunning = false;

  SyncEngine(
    this._repository,
    this._conflictRepository,
    this._connectivityService,
    this._apiClient,
    this._versionDao,
    this._database,
  );

  Future<void> sync() async {
    if (_isRunning) {
      return;
    }

    final online =
        await _connectivityService.isOnline();

    if (!online) {
      return;
    }

    _isRunning = true;

    try {
      final operations =
          await _repository.getPendingOperations();

      for (final operation in operations) {
        if (!_shouldRetry(
          operation.retryCount,
          operation.updatedAt,
        )) {
          continue;
        }

        await _processOperation(operation);
      }
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _processOperation(
    SyncOperation operation,
  ) async {
    await _repository.markAsSyncing(
      operation.operationId,
    );

    try {
      final response =
          await _sendOperation(operation);

      final serverVersion =
          response['server_version'] as int;

      await _versionDao.setVersion(
        entityType: operation.entityType,
        entityId: operation.entityId,
        version: serverVersion,
      );

      if (operation.entityType ==
              'WOUND_PHOTO' &&
          operation.operationType != 'DELETE') {
        await _updateLocalWoundPhoto(
          operation,
          response,
        );
      }

      if (operation.entityType ==
              'VOICE_NOTE' &&
          operation.operationType != 'DELETE') {
        await _updateLocalVoiceNote(
          operation,
        );
      }

      await _repository.markAsCompleted(
        operation.operationId,
      );
    } on ConflictException catch (error) {
      await _handleConflict(
        operation,
        error,
      );
    } catch (error) {
      await _repository.incrementRetryCount(
        operation.operationId,
      );

      await _repository.markAsFailed(
        operation.operationId,
        error.toString(),
      );
    }
  }

  Future<void> _updateLocalWoundPhoto(
    SyncOperation operation,
    Map<String, dynamic> response,
  ) async {
    final payload =
        Map<String, dynamic>.from(
      jsonDecode(operation.payload)
          as Map<String, dynamic>,
    );

    final serverFilePath =
        response['payload'] is Map
            ? (response['payload']
                        ['server_file_path']
                    ?.toString() ??
                '')
            : '';

    if (serverFilePath.isEmpty) {
      return;
    }

    final existing =
        await _database.woundPhotoDao
            .getWoundPhotoById(
      operation.entityId,
    );

    if (existing == null) {
      return;
    }

    await _database.woundPhotoDao
        .updateWoundPhoto(
      WoundPhotosCompanion(
        id: Value(existing.id),
        patientId:
            Value(existing.patientId),
        filePath:
            Value(existing.filePath),
        serverFilePath:
            Value(serverFilePath),
        note: Value(
          payload['note']?.toString() ??
              existing.note,
        ),
        capturedAt:
            Value(existing.capturedAt),
        capturedBy:
            Value(existing.capturedBy),
        status:
            const Value('synced'),
      ),
    );
  }

  Future<void> _updateLocalVoiceNote(
    SyncOperation operation,
  ) async {
    await _database.voiceNoteDao.updateStatus(
      operation.entityId,
      'synced',
    );
  }

  Future<void> _handleConflict(
    SyncOperation operation,
    ConflictException error,
  ) async {
    final conflict = error.conflict;

    final clientVersion =
        conflict['client_version'] as int;

    final serverVersion =
        conflict['server_version'] as int;

    await _conflictRepository.addConflict(
      operationId: operation.operationId,
      entityType: operation.entityType,
      entityId: operation.entityId,
      clientVersion: clientVersion,
      serverVersion: serverVersion,
      clientPayload: jsonDecode(
        operation.payload,
      ),
      serverPayload:
          error.serverPayload,
    );

    await _repository.markAsConflict(
      operation.operationId,
    );
  }

  bool _shouldRetry(
    int retryCount,
    DateTime updatedAt,
  ) {
    if (retryCount == 0) {
      return true;
    }

    if (!RetryPolicy.canRetry(
      retryCount,
    )) {
      return false;
    }

    final delay =
        RetryPolicy.getDelay(
      retryCount - 1,
    );

    return DateTime.now().isAfter(
      updatedAt.add(delay),
    );
  }

  Future<void> start() async {
    await sync();

    _connectivityService
        .onConnectivityChanged
        .listen(
      (online) {
        if (online) {
          sync();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _sendOperation(
    SyncOperation operation,
  ) async {
    if (operation.entityType ==
        'WOUND_PHOTO') {
      return _sendWoundPhotoOperation(
        operation,
      );
    }

    if (operation.entityType ==
        'VOICE_NOTE') {
      return _sendVoiceNoteOperation(
        operation,
      );
    }

    return _apiClient.post(
      '/sync/operations',
      {
        'operation_id':
            operation.operationId,
        'entity_type':
            operation.entityType,
        'entity_id':
            operation.entityId,
        'operation_type':
            operation.operationType,
        'payload':
            jsonDecode(operation.payload),
        'base_version':
            operation.baseVersion,
      },
    );
  }

  Future<Map<String, dynamic>>
      _sendWoundPhotoOperation(
    SyncOperation operation,
  ) async {
    final payload =
        Map<String, dynamic>.from(
      jsonDecode(operation.payload)
          as Map<String, dynamic>,
    );

    if (operation.operationType ==
        'DELETE') {
      return _apiClient.post(
        '/sync/operations',
        {
          'operation_id':
              operation.operationId,
          'entity_type':
              operation.entityType,
          'entity_id':
              operation.entityId,
          'operation_type':
              operation.operationType,
          'payload': payload,
          'base_version':
              operation.baseVersion,
        },
      );
    }

    final localFilePath =
        payload['file_path']?.toString();

    if (localFilePath == null ||
        localFilePath.isEmpty) {
      throw const ApiException(
        400,
        'Wound photo file path is missing',
      );
    }

    final file = File(localFilePath);

    if (!await file.exists()) {
      throw const ApiException(
        404,
        'Wound photo file does not exist',
      );
    }

    final uploadResponse =
        await _apiClient.uploadFile(
      path:
          '/sync/wound-photos/upload',
      file: file,
    );

    final serverFilePath =
        uploadResponse['file_path']
            ?.toString();

    if (serverFilePath == null ||
        serverFilePath.isEmpty) {
      throw const ApiException(
        500,
        'Server did not return wound photo path',
      );
    }

    final syncedPayload =
        Map<String, dynamic>.from(
      payload,
    );

    syncedPayload[
        'server_file_path'] =
        serverFilePath;

    final response =
        await _apiClient.post(
      '/sync/operations',
      {
        'operation_id':
            operation.operationId,
        'entity_type':
            operation.entityType,
        'entity_id':
            operation.entityId,
        'operation_type':
            operation.operationType,
        'payload': syncedPayload,
        'base_version':
            operation.baseVersion,
      },
    );

    response['payload'] =
        syncedPayload;

    return response;
  }

  Future<Map<String, dynamic>>
      _sendVoiceNoteOperation(
    SyncOperation operation,
  ) async {
    final payload =
        Map<String, dynamic>.from(
      jsonDecode(operation.payload)
          as Map<String, dynamic>,
    );

    if (operation.operationType ==
        'DELETE') {
      return _apiClient.post(
        '/sync/operations',
        {
          'operation_id':
              operation.operationId,
          'entity_type':
              operation.entityType,
          'entity_id':
              operation.entityId,
          'operation_type':
              operation.operationType,
          'payload': payload,
          'base_version':
              operation.baseVersion,
        },
      );
    }

    final localFilePath =
        payload['file_path']?.toString();

    if (localFilePath == null ||
        localFilePath.isEmpty) {
      throw const ApiException(
        400,
        'Voice note file path is missing',
      );
    }

    final file = File(localFilePath);

    if (!await file.exists()) {
      throw const ApiException(
        404,
        'Voice note audio file does not exist',
      );
    }

    final uploadResponse =
        await _apiClient.uploadFile(
      path:
          '/sync/voice-notes/upload',
      file: file,
    );

    final serverFilePath =
        uploadResponse['file_path']
            ?.toString();

    if (serverFilePath == null ||
        serverFilePath.isEmpty) {
      throw const ApiException(
        500,
        'Server did not return voice note path',
      );
    }

    final syncedPayload =
        Map<String, dynamic>.from(
      payload,
    );

    syncedPayload[
        'server_file_path'] =
        serverFilePath;

    final response =
        await _apiClient.post(
      '/sync/operations',
      {
        'operation_id':
            operation.operationId,
        'entity_type':
            operation.entityType,
        'entity_id':
            operation.entityId,
        'operation_type':
            operation.operationType,
        'payload': syncedPayload,
        'base_version':
            operation.baseVersion,
      },
    );

    response['payload'] =
        syncedPayload;

    return response;
  }
}