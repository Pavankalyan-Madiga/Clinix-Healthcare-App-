import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ConflictResolver {
  final AppDatabase _database;

  ConflictResolver(this._database);

  Future<void> applyServerPayload({
    required String operationId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required int serverVersion,
  }) async {
    switch (entityType) {
      case 'TASK':
        await _applyTask(
          payload: payload,
          serverVersion: serverVersion,
        );
        break;

      case 'PATIENT':
        await _applyPatient(
          payload: payload,
          serverVersion: serverVersion,
        );
        break;

      default:
        throw UnsupportedError(
          'Unsupported conflict entity: $entityType',
        );
    }

    await _database.syncOperationsDao.markAsCompleted(
      operationId,
    );

    await _database.syncConflictsDao.deleteConflict(
      operationId,
    );
  }

  Future<void> _applyTask({
    required Map<String, dynamic> payload,
    required int serverVersion,
  }) async {
    final taskId = payload['id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      throw const FormatException(
        'Task payload is missing id',
      );
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
          payload['status']?.toString() ?? 'pending',
        ),
      ),
    );

    await _database.entityVersionsDao.setVersion(
      entityType: 'TASK',
      entityId: taskId,
      version: serverVersion,
    );
  }

  Future<void> _applyPatient({
    required Map<String, dynamic> payload,
    required int serverVersion,
  }) async {
    final patientId = payload['id']?.toString();

    if (patientId == null || patientId.isEmpty) {
      throw const FormatException(
        'Patient payload is missing id',
      );
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
          payload['condition']?.toString() ?? 'Stable',
        ),
        status: Value(
          payload['status']?.toString() ?? 'Stable',
        ),
      ),
    );

    await _database.entityVersionsDao.setVersion(
      entityType: 'PATIENT',
      entityId: patientId,
      version: serverVersion,
    );
  }
}