import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/patients/data/repositories/patient_repository.dart';
import 'database_providers.dart';
import 'sync_providers.dart';

final patientRepositoryProvider =
    Provider<PatientRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final syncQueue = ref.watch(syncQueueProvider);

  return PatientRepository(
    database,
    syncQueue,
  );
});