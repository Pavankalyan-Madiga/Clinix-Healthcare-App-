import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(
  tables: [
    Tasks,
  ],
)
class TaskDao extends DatabaseAccessor<AppDatabase>
    with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<List<Task>> getAllTasks() {
    return select(tasks).get();
  }

  Future<Task?> getTaskById(String id) {
    return (select(tasks)
          ..where(
            (task) => task.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<List<Task>> getTasksByPatientId(
    String patientId,
  ) {
    return (select(tasks)
          ..where(
            (task) => task.patientId.equals(patientId),
          ))
        .get();
  }

  Future<void> insertTask(
    TasksCompanion task,
  ) {
    return into(tasks).insert(
      task,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateTask(
    TasksCompanion task,
  ) {
    final taskId = task.id.value;

    return (update(tasks)
          ..where(
            (item) => item.id.equals(taskId),
          ))
        .write(task);
  }

  Future<void> deleteTask(String id) {
    return (delete(tasks)
          ..where(
            (task) => task.id.equals(id),
          ))
        .go();
  }
}