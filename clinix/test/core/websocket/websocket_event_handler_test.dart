import 'dart:async';
import 'dart:convert';

import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/network/api_client.dart';
import 'package:clinix/core/websocket/websocket_event_handler.dart';
import 'package:clinix/core/websocket/websocket_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class FakeWebSocketService extends WebSocketService {
  final StreamController<Map<String, dynamic>> eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<void> reconnectController =
      StreamController<void>.broadcast();

  FakeWebSocketService()
      : super(
          url: 'ws://test-server',
        );

  @override
  Stream<Map<String, dynamic>> get events =>
      eventController.stream;

  @override
  Stream<void> get reconnected =>
      reconnectController.stream;

  Future<void> emitEvent(
    Map<String, dynamic> event,
  ) async {
    eventController.add(event);
    await Future<void>.delayed(
      const Duration(milliseconds: 10),
    );
  }

  Future<void> emitReconnect() async {
    reconnectController.add(null);
    await Future<void>.delayed(
      const Duration(milliseconds: 10),
    );
  }

  @override
  Future<void> dispose() async {
    await eventController.close();
    await reconnectController.close();
  }
}

class FakeHttpClient extends http.BaseClient {
  final List<http.Request> requests = [];

  Map<String, dynamic> changesResponse = {
    'changes': [],
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
          jsonEncode(changesResponse),
        ),
      ),
      200,
      headers: {
        'content-type': 'application/json',
      },
      request: request,
    );
  }
}

void main() {
  late AppDatabase database;
  late FakeWebSocketService webSocketService;
  late FakeHttpClient httpClient;
  late ApiClient apiClient;
  late WebSocketEventHandler handler;

  setUp(() {
    database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );

    webSocketService = FakeWebSocketService();

    httpClient = FakeHttpClient();

    apiClient = ApiClient(
      baseUrl: 'http://test-server',
      client: httpClient,
    );

    handler = WebSocketEventHandler(
      database,
      webSocketService,
      apiClient,
    );

    handler.start();
  });

  tearDown(() async {
    await webSocketService.dispose();
    apiClient.dispose();
    await database.close();
  });

  test(
    'SYNC_UPDATE patient event updates local patient',
    () async {
      await database.patientDao.insertPatient(
        PatientsCompanion.insert(
          id: 'P-WS-001',
          firstName: 'Maria',
          lastName: 'Garcia',
          dateOfBirth: '1985-04-12',
          gender: 'Female',
          room: '101',
          condition: 'Diabetes',
          status: 'Stable',
        ),
      );

      await webSocketService.emitEvent({
        'type': 'SYNC_UPDATE',
        'entity_type': 'PATIENT',
        'entity_id': 'P-WS-001',
        'operation_type': 'UPDATE',
        'server_version': 2,
        'payload': {
          'id': 'P-WS-001',
          'first_name': 'Maria',
          'last_name': 'Garcia',
          'date_of_birth': '1985-04-12',
          'gender': 'Female',
          'room': '101',
          'condition': 'Diabetes',
          'status': 'Needs Attention',
        },
      });

      final patient =
          await database.patientDao.getPatientById(
        'P-WS-001',
      );

      expect(patient, isNotNull);
      expect(
        patient!.status,
        'Needs Attention',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'PATIENT',
        'P-WS-001',
      );

      expect(version, isNotNull);
      expect(version!.version, 2);
    },
  );

  test(
    'stale patient event is ignored',
    () async {
      await database.patientDao.insertPatient(
        PatientsCompanion.insert(
          id: 'P-WS-002',
          firstName: 'Robert',
          lastName: 'Johnson',
          dateOfBirth: '1978-09-21',
          gender: 'Male',
          room: '103',
          condition: 'Hypertension',
          status: 'Stable',
        ),
      );

      await database.entityVersionsDao.setVersion(
        entityType: 'PATIENT',
        entityId: 'P-WS-002',
        version: 5,
      );

      await webSocketService.emitEvent({
        'type': 'SYNC_UPDATE',
        'entity_type': 'PATIENT',
        'entity_id': 'P-WS-002',
        'operation_type': 'UPDATE',
        'server_version': 4,
        'payload': {
          'id': 'P-WS-002',
          'first_name': 'Robert',
          'last_name': 'Johnson',
          'date_of_birth': '1978-09-21',
          'gender': 'Male',
          'room': '103',
          'condition': 'Hypertension',
          'status': 'Needs Attention',
        },
      });

      final patient =
          await database.patientDao.getPatientById(
        'P-WS-002',
      );

      expect(
        patient!.status,
        'Stable',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'PATIENT',
        'P-WS-002',
      );

      expect(
        version!.version,
        5,
      );
    },
  );

  test(
    'incoming message event is stored locally',
    () async {
      await webSocketService.emitEvent({
        'type': 'SYNC_UPDATE',
        'entity_type': 'MESSAGE',
        'entity_id': 'MSG-WS-001',
        'operation_type': 'CREATE',
        'server_version': 1,
        'payload': {
          'id': 'MSG-WS-001',
          'conversation_id': 'STAFF-001__STAFF-002',
          'sender_id': 'STAFF-002',
          'sender_name': 'Jane Smith',
          'receiver_id': 'STAFF-001',
          'receiver_name': 'John Smith',
          'content': 'Patient is ready for review.',
          'created_at': '2026-09-22T00:00:00Z',
          'status': 'sent',
        },
      });

      final message =
          await database.messageDao.getMessageById(
        'MSG-WS-001',
      );

      expect(message, isNotNull);
      expect(
        message!.content,
        'Patient is ready for review.',
      );
      expect(
        message.senderId,
        'STAFF-002',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'MESSAGE',
        'MSG-WS-001',
      );

      expect(version, isNotNull);
      expect(version!.version, 1);
    },
  );

  test(
    'message delete event removes local message',
    () async {
      await database.messageDao.insertMessage(
        MessagesCompanion.insert(
          id: 'MSG-WS-002',
          conversationId: 'STAFF-001__STAFF-002',
          senderId: 'STAFF-002',
          senderName: 'Jane Smith',
          receiverId: 'STAFF-001',
          receiverName: 'John Smith',
          content: 'Delete this message',
          createdAt: DateTime.parse(
            '2026-09-22T00:00:00Z',
          ),
          status: 'sent',
        ),
      );

      await webSocketService.emitEvent({
        'type': 'SYNC_UPDATE',
        'entity_type': 'MESSAGE',
        'entity_id': 'MSG-WS-002',
        'operation_type': 'DELETE',
        'server_version': 2,
      });

      final message =
          await database.messageDao.getMessageById(
        'MSG-WS-002',
      );

      expect(message, isNull);

      final version =
          await database.entityVersionsDao.getVersion(
        'MESSAGE',
        'MSG-WS-002',
      );

      expect(version, isNotNull);
      expect(version!.version, 2);
    },
  );

  test(
    'reconnect triggers missed changes recovery',
    () async {
      httpClient.changesResponse = {
        'changes': [],
      };

      await webSocketService.emitReconnect();

      await Future<void>.delayed(
        const Duration(milliseconds: 20),
      );

      expect(
        httpClient.requests,
        hasLength(1),
      );

      expect(
        httpClient.requests.first.url.path,
        '/sync/changes',
      );
    },
  );

  test(
    'duplicate event is ignored after first version is applied',
    () async {
      await database.patientDao.insertPatient(
        PatientsCompanion.insert(
          id: 'P-WS-003',
          firstName: 'Emily',
          lastName: 'Davis',
          dateOfBirth: '1992-03-18',
          gender: 'Female',
          room: '104',
          condition: 'Post Surgery',
          status: 'Stable',
        ),
      );

      final event = {
        'type': 'SYNC_UPDATE',
        'entity_type': 'PATIENT',
        'entity_id': 'P-WS-003',
        'operation_type': 'UPDATE',
        'server_version': 3,
        'payload': {
          'id': 'P-WS-003',
          'first_name': 'Emily',
          'last_name': 'Davis',
          'date_of_birth': '1992-03-18',
          'gender': 'Female',
          'room': '104',
          'condition': 'Post Surgery',
          'status': 'Needs Attention',
        },
      };

      await webSocketService.emitEvent(event);
      await webSocketService.emitEvent(event);

      final patient =
          await database.patientDao.getPatientById(
        'P-WS-003',
      );

      expect(
        patient!.status,
        'Needs Attention',
      );

      final version =
          await database.entityVersionsDao.getVersion(
        'PATIENT',
        'P-WS-003',
      );

      expect(
        version!.version,
        3,
      );
    },
  );
}