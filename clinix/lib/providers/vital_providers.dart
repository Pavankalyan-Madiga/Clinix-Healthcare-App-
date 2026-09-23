import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/vitals/data/repositories/vital_repository.dart';
import 'database_providers.dart';
import 'sync_providers.dart';

final vitalRepositoryProvider =
    Provider<VitalRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final syncQueue = ref.watch(syncQueueProvider);

  return VitalRepository(
    database,
    syncQueue,
  );
});