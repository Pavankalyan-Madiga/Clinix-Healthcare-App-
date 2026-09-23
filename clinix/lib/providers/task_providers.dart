import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/tasks/data/repositories/task_repository.dart';
import 'database_providers.dart';
import 'patient_providers.dart';
import 'sync_providers.dart';

final taskRepositoryProvider =
    Provider<TaskRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  final patientRepository =
      ref.watch(patientRepositoryProvider);

  return TaskRepository(
    database,
    syncQueue,
    patientRepository,
  );
});