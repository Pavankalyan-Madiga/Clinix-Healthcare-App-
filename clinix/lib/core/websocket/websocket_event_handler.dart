import 'dart:async';

import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/network/api_client.dart';
import 'package:clinix/core/websocket/websocket_service.dart';
import 'package:drift/drift.dart';

class WebSocketEventHandler {
  final AppDatabase _database;
  final WebSocketService _webSocketService;
  final ApiClient _apiClient;

  StreamSubscription<Map<String, dynamic>>?
      _eventSubscription;

  StreamSubscription<void>?
      _reconnectedSubscription;

  bool _started = false;
  bool _recovering = false;

  WebSocketEventHandler(
    this._database,
    this._webSocketService,
    this._apiClient,
  );

  void start() {
    if (_started) {
      return;
    }

    _started = true;

    _eventSubscription =
        _webSocketService.events.listen(
      _handleEvent,
    );

    _reconnectedSubscription =
        _webSocketService.reconnected.listen(
      (_) {
        recoverMissedChanges();
      },
    );
  }

  Future<void> recoverMissedChanges() async {
    if (_recovering) {
      return;
    }

    _recovering = true;

    try {
      print(
        '[WebSocket] Recovering missed changes',
      );

      final changes =
          await _apiClient.getChanges();

      for (final change in changes) {
        await _handleEvent({
          'type': 'SYNC_UPDATE',
          ...change,
        });
      }

      print(
        '[WebSocket] Recovery completed: '
        '${changes.length} changes checked',
      );
    } catch (error) {
      print(
        '[WebSocket] Recovery failed: $error',
      );
    } finally {
      _recovering = false;
    }
  }

  Future<void> _handleEvent(
    Map<String, dynamic> event,
  ) async {
    if (event['type'] != 'SYNC_UPDATE') {
      return;
    }

    final entityType =
        event['entity_type']?.toString();

    final entityId =
        event['entity_id']?.toString();

    final operationType =
        event['operation_type']?.toString();

    final payload = event['payload'];

    final serverVersion =
        event['server_version'];

    if (entityType == null ||
        entityId == null ||
        serverVersion is! int) {
      return;
    }

    final currentVersion =
        await _database.entityVersionsDao
            .getVersion(
      entityType,
      entityId,
    );

    if (currentVersion != null &&
        serverVersion <=
            currentVersion.version) {
      print(
        '[WebSocket] Ignoring stale/duplicate event '
        '$entityType/$entityId '
        'v$serverVersion '
        '(local v${currentVersion.version})',
      );

      return;
    }

    if (entityType == 'MESSAGE' &&
        operationType == 'DELETE') {
      await _deleteMessage(
        entityId,
        serverVersion,
      );

      return;
    }

    if (payload is! Map<String, dynamic>) {
      return;
    }

    switch (entityType) {
      case 'TASK':
        await _updateTask(
          payload,
          serverVersion,
        );
        break;

      case 'PATIENT':
        await _updatePatient(
          payload,
          serverVersion,
        );
        break;

      case 'MESSAGE':
        await _updateMessage(
          payload,
          serverVersion,
        );
        break;

      default:
        return;
    }
  }

  Future<void> _updateTask(
    Map<String, dynamic> payload,
    int serverVersion,
  ) async {
    final taskId =
        payload['id']?.toString();

    if (taskId == null ||
        taskId.isEmpty) {
      return;
    }

    await _database.taskDao.updateTask(
      TasksCompanion(
        id: Value(taskId),
        patientId: Value(
          payload['patient_id']?.toString() ?? '',
        ),
        title: Value(
          payload['title']?.toString() ?? '',
        ),
        description: Value(
          payload['description']?.toString() ?? '',
        ),
        assignedTo: Value(
          payload['assigned_to']?.toString() ?? '',
        ),
        dueDate: Value(
          payload['due_date']?.toString() ?? '',
        ),
        status: Value(
          payload['status']?.toString() ??
              'pending',
        ),
      ),
    );

    await _database.entityVersionsDao
        .setVersion(
      entityType: 'TASK',
      entityId: taskId,
      version: serverVersion,
    );

    await _updatePatientStatus(
      payload,
    );
  }

  Future<void> _updatePatient(
    Map<String, dynamic> payload,
    int serverVersion,
  ) async {
    final patientId =
        payload['id']?.toString();

    if (patientId == null ||
        patientId.isEmpty) {
      return;
    }

    await _database.patientDao.updatePatient(
      PatientsCompanion(
        id: Value(patientId),
        firstName: Value(
          payload['first_name']?.toString() ?? '',
        ),
        lastName: Value(
          payload['last_name']?.toString() ?? '',
        ),
        dateOfBirth: Value(
          payload['date_of_birth']?.toString() ?? '',
        ),
        gender: Value(
          payload['gender']?.toString() ?? '',
        ),
        room: Value(
          payload['room']?.toString() ?? '',
        ),
        condition: Value(
          payload['condition']?.toString() ?? '',
        ),
        status: Value(
          payload['status']?.toString() ??
              'Stable',
        ),
      ),
    );

    await _database.entityVersionsDao
        .setVersion(
      entityType: 'PATIENT',
      entityId: patientId,
      version: serverVersion,
    );
  }

  Future<void> _updateMessage(
    Map<String, dynamic> payload,
    int serverVersion,
  ) async {
    final messageId =
        payload['id']?.toString();

    if (messageId == null ||
        messageId.isEmpty) {
      return;
    }

    final conversationId =
        payload['conversation_id']
            ?.toString();

    final senderId =
        payload['sender_id']?.toString();

    final senderName =
        payload['sender_name']?.toString();

    final receiverId =
        payload['receiver_id']?.toString();

    final receiverName =
        payload['receiver_name']?.toString();

    final content =
        payload['content']?.toString();

    final createdAt =
        payload['created_at']?.toString();

    final status =
        payload['status']?.toString();

    if (conversationId == null ||
        senderId == null ||
        senderName == null ||
        receiverId == null ||
        receiverName == null ||
        content == null ||
        createdAt == null) {
      return;
    }

    final existing =
        await _database.messageDao
            .getMessageById(
      messageId,
    );

    if (existing == null) {
      await _database.messageDao
          .insertMessage(
        MessagesCompanion.insert(
          id: messageId,
          conversationId:
              conversationId,
          senderId: senderId,
          senderName: senderName,
          receiverId: receiverId,
          receiverName:
              receiverName,
          content: content,
          createdAt:
              DateTime.parse(
            createdAt,
          ),
          status:
              status ?? 'sent',
        ),
      );
    } else {
      await _database.messageDao
          .updateMessage(
        MessagesCompanion(
          id: Value(messageId),
          conversationId:
              Value(conversationId),
          senderId:
              Value(senderId),
          senderName:
              Value(senderName),
          receiverId:
              Value(receiverId),
          receiverName:
              Value(receiverName),
          content:
              Value(content),
          createdAt:
              Value(
            DateTime.parse(
              createdAt,
            ),
          ),
          status:
              Value(
            status ?? 'sent',
          ),
        ),
      );
    }

    await _database.entityVersionsDao
        .setVersion(
      entityType: 'MESSAGE',
      entityId: messageId,
      version: serverVersion,
    );

    print(
      '[WebSocket] Message synchronized '
      '$messageId '
      'v$serverVersion',
    );
  }

  Future<void> _deleteMessage(
    String messageId,
    int serverVersion,
  ) async {
    if (messageId.isEmpty) {
      return;
    }

    await _database.messageDao
        .deleteMessage(
      messageId,
    );

    await _database.entityVersionsDao
        .setVersion(
      entityType: 'MESSAGE',
      entityId: messageId,
      version: serverVersion,
    );

    print(
      '[WebSocket] Message deleted '
      '$messageId '
      'v$serverVersion',
    );
  }

  Future<void> _updatePatientStatus(
    Map<String, dynamic> payload,
  ) async {
    final patientId =
        payload['patient_id']?.toString();

    if (patientId == null ||
        patientId.isEmpty) {
      return;
    }

    final taskStatus =
        payload['status']?.toString();

    final patientStatus =
        taskStatus == 'completed'
            ? 'Stable'
            : 'Needs Attention';

    final patient =
        await _database.patientDao
            .getPatientById(
      patientId,
    );

    if (patient == null) {
      return;
    }

    await _database.patientDao
        .updatePatient(
      PatientsCompanion(
        id: Value(patient.id),
        firstName:
            Value(patient.firstName),
        lastName:
            Value(patient.lastName),
        dateOfBirth:
            Value(patient.dateOfBirth),
        gender:
            Value(patient.gender),
        room:
            Value(patient.room),
        condition:
            Value(patient.condition),
        status:
            Value(patientStatus),
      ),
    );
  }

  Future<void> dispose() async {
    _started = false;
    _recovering = false;

    await _eventSubscription?.cancel();
    await _reconnectedSubscription?.cancel();

    _eventSubscription = null;
    _reconnectedSubscription = null;
  }
}