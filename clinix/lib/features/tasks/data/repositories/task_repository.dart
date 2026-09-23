import 'package:clinix/core/database/daos/entity_versions_dao.dart' as database;
import 'package:clinix/core/database/daos/task_dao.dart' as database;
import 'package:clinix/features/tasks/domain/entites/task.dart' as domain;
import 'package:drift/drift.dart';

import 'package:clinix/core/database/app_database.dart'
    as database;
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/features/patients/data/repositories/patient_repository.dart';

import '../model/task_model.dart';

class TaskRepository {
  final database.TaskDao _dao;
  final database.EntityVersionsDao _versionDao;
  final SyncQueue _syncQueue;
  final PatientRepository _patientRepository;

  TaskRepository(
    database.AppDatabase db,
    this._syncQueue,
    this._patientRepository,
  )   : _dao = db.taskDao,
        _versionDao = db.entityVersionsDao;

  Future<List<TaskModel>> getTasks() async {
    final tasks = await _dao.getAllTasks();

    return tasks.map(_toModel).toList();
  }

  Future<TaskModel?> getTaskById(
    String id,
  ) async {
    final task = await _dao.getTaskById(id);

    if (task == null) {
      return null;
    }

    return _toModel(task);
  }

  Future<List<TaskModel>> getTasksByPatientId(
    String patientId,
  ) async {
    final tasks =
        await _dao.getTasksByPatientId(patientId);

    return tasks.map(_toModel).toList();
  }

  Future<void> insertTask(
    TaskModel task,
  ) async {
    await _dao.insertTask(
      database.TasksCompanion.insert(
        id: task.id,
        patientId: task.patientId,
        title: task.title,
        description: task.description,
        assignedTo: task.assignedTo,
        dueDate: task.dueDate,
        status: task.status.name,
      ),
    );

    await _versionDao.setVersion(
      entityType: 'TASK',
      entityId: task.id,
      version: 1,
    );

    await _syncQueue.enqueue(
      entityType: 'TASK',
      entityId: task.id,
      operationType: 'CREATE',
      payload: task.toJson(),
      baseVersion: 1,
    );
  }

  Future<void> updateTask(
    TaskModel task,
  ) async {
    final existingVersion =
        await _versionDao.getVersion(
      'TASK',
      task.id,
    );

    final baseVersion =
        existingVersion?.version ?? 1;

    await _dao.updateTask(
      database.TasksCompanion(
        id: Value(task.id),
        patientId: Value(task.patientId),
        title: Value(task.title),
        description: Value(task.description),
        assignedTo: Value(task.assignedTo),
        dueDate: Value(task.dueDate),
        status: Value(task.status.name),
      ),
    );

    await _updatePatientStatus(task);

    await _syncQueue.enqueue(
      entityType: 'TASK',
      entityId: task.id,
      operationType: 'UPDATE',
      payload: task.toJson(),
      baseVersion: baseVersion,
    );
  }

  Future<void> deleteTask(
    String id,
  ) async {
    final existingVersion =
        await _versionDao.getVersion(
      'TASK',
      id,
    );

    final baseVersion =
        existingVersion?.version ?? 1;

    await _dao.deleteTask(id);

    await _syncQueue.enqueue(
      entityType: 'TASK',
      entityId: id,
      operationType: 'DELETE',
      payload: {
        'id': id,
      },
      baseVersion: baseVersion,
    );
  }

  Future<void> _updatePatientStatus(
    TaskModel task,
  ) async {
    final patientStatus =
        task.status == domain.TaskStatus.completed
            ? 'Stable'
            : 'Needs Attention';

    await _patientRepository.updatePatientStatus(
      task.patientId,
      patientStatus,
    );
  }

  TaskModel _toModel(
    database.Task task,
  ) {
    return TaskModel(
      id: task.id,
      patientId: task.patientId,
      title: task.title,
      description: task.description,
      assignedTo: task.assignedTo,
      dueDate: task.dueDate,
      status: domain.TaskStatus.values.firstWhere(
        (status) => status.name == task.status,
        orElse: () => domain.TaskStatus.pending,
      ),
    );
  }
}