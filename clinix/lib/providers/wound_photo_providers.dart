import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/wound_documentation/data/repositories/wound_photo_repository.dart';
import 'database_providers.dart';
import 'sync_providers.dart';

final woundPhotoRepositoryProvider =
    Provider<WoundPhotoRepository>((ref) {
  final database =
      ref.watch(databaseProvider);

  final syncQueue =
      ref.watch(syncQueueProvider);

  return WoundPhotoRepository(
    database,
    syncQueue,
  );
});