import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/network/api_client.dart';
import 'package:clinix/core/network/connectivity_service.dart';
import 'package:clinix/core/sync/conflict_repository.dart';
import 'package:clinix/core/sync/sync_engine.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/core/sync/sync_repository.dart';

class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService({
    this.online = true,
  });

  bool online;

  @override
  Future<bool> isOnline() async {
    return online;
  }
}

class FakeHttpClient extends http.BaseClient {
  final List<http.Request> requests = [];

  int responseStatusCode = 200;

  Map<String, dynamic> responseBody = {
    'operation_id': 'operation-1',
    'status': 'SYNCED',
    'server_version': 2,
    'synced_at': '2026-09-22T00:00:00Z',
  };

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
  ) async {
    if (request is http.Request) {
      requests.add(request);
    }

    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode(responseBody),
        ),
      ),
      responseStatusCode,
      headers: {
        'content-type': 'application/json',
      },
      request: request,
    );
  }
}

void main() {
  late AppDatabase database;
  late SyncRepository repository;
  late SyncQueue queue;
  late ConflictRepository conflictRepository;
  late FakeConnectivityService connectivity;
  late FakeHttpClient httpClient;
  late ApiClient apiClient;
  late SyncEngine syncEngine;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    repository = SyncRepository(database);
    queue = SyncQueue(repository);

    conflictRepository = ConflictRepository(
      database,
    );

    connectivity = FakeConnectivityService();

    httpClient = FakeHttpClient();

    apiClient = ApiClient(
      baseUrl: 'http://test-server',
      client: httpClient,
    );

    syncEngine = SyncEngine(
      repository,
      conflictRepository,
      connectivity,
      apiClient,
      database.entityVersionsDao,
      database,
    );
  });

  tearDown(() async {
    apiClient.dispose();
    await database.close();
  });

  test(
    'enqueue creates a pending sync operation',
    () async {
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
    },
  );

  test(
    'pendingCount returns number of pending operations',
    () async {
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
    },
  );

  test(
    'hasPendingOperations returns true when queue is not empty',
    () async {
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
    },
  );

  test(
    'hasPendingOperations returns false after operation is completed',
    () async {
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
    },
  );

  test(
    'sync successfully completes a pending operation',
    () async {
      await queue.enqueue(
        entityType: 'PATIENT',
        entityId: 'P-TEST-001',
        operationType: 'UPDATE',
        payload: {
          'id': 'P-TEST-001',
          'status': 'Stable',
        },
        baseVersion: 1,
      );

      var pendingOperations =
          await repository.getPendingOperations();

      expect(
        pendingOperations,
        hasLength(1),
      );

      await syncEngine.sync();

      pendingOperations =
          await repository.getPendingOperations();

      expect(
        pendingOperations,
        isEmpty,
      );

      final operations =
          await repository.getAllOperations();

      expect(
        operations,
        hasLength(1),
      );

      expect(
        operations.first.status,
        'COMPLETED',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'PATIENT',
        'P-TEST-001',
      );

      expect(
        version,
        isNotNull,
      );

      expect(
        version!.version,
        2,
      );

      expect(
        httpClient.requests,
        hasLength(1),
      );

      expect(
        httpClient.requests.first.url.path,
        '/sync/operations',
      );
    },
  );

  test(
    'sync does nothing when device is offline',
    () async {
      connectivity.online = false;

      await queue.enqueue(
        entityType: 'PATIENT',
        entityId: 'P-TEST-002',
        operationType: 'UPDATE',
        payload: {
          'id': 'P-TEST-002',
          'status': 'Stable',
        },
        baseVersion: 1,
      );

      await syncEngine.sync();

      final pendingOperations =
          await repository.getPendingOperations();

      expect(
        pendingOperations,
        hasLength(1),
      );

      expect(
        httpClient.requests,
        isEmpty,
      );
    },
  );

  test(
    'sync marks operation as failed when server request fails',
    () async {
      httpClient.responseStatusCode = 500;

      httpClient.responseBody = {
        'detail': 'Internal server error',
      };

      await queue.enqueue(
        entityType: 'PATIENT',
        entityId: 'P-TEST-003',
        operationType: 'UPDATE',
        payload: {
          'id': 'P-TEST-003',
          'status': 'Stable',
        },
        baseVersion: 1,
      );

      await syncEngine.sync();

      final operations =
          await repository.getAllOperations();

      expect(
        operations,
        hasLength(1),
      );

      expect(
        operations.first.status,
        'FAILED',
      );

      expect(
        operations.first.retryCount,
        1,
      );

      expect(
        httpClient.requests,
        hasLength(1),
      );
    },
  );

  test(
    'sync stores conflict and marks operation as conflict',
    () async {
      httpClient.responseStatusCode = 409;

      httpClient.responseBody = {
        'detail': {
          'client_version': 5,
          'server_version': 6,
          'server_payload': {
            'id': 'P-TEST-004',
            'status': 'Needs Attention',
          },
        },
      };

      await queue.enqueue(
        entityType: 'PATIENT',
        entityId: 'P-TEST-004',
        operationType: 'UPDATE',
        payload: {
          'id': 'P-TEST-004',
          'status': 'Stable',
        },
        baseVersion: 5,
      );

      final operations =
          await repository.getPendingOperations();

      expect(
        operations,
        hasLength(1),
      );

      final operationId =
          operations.first.operationId;

      await syncEngine.sync();

      final allOperations =
          await repository.getAllOperations();

      expect(
        allOperations,
        hasLength(1),
      );

      expect(
        allOperations.first.status,
        'CONFLICT',
      );

      final conflicts =
          await conflictRepository.getConflicts();

      expect(
        conflicts,
        hasLength(1),
      );

      expect(
        conflicts.first.operationId,
        operationId,
      );

      expect(
        conflicts.first.entityType,
        'PATIENT',
      );

      expect(
        conflicts.first.entityId,
        'P-TEST-004',
      );

      expect(
        conflicts.first.clientVersion,
        5,
      );

      expect(
        conflicts.first.serverVersion,
        6,
      );

      expect(
        conflicts.first.status,
        'PENDING',
      );
    },
  );
}