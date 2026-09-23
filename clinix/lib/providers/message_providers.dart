import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/messaging/data/repositories/message_repository.dart';
import 'database_providers.dart';
import 'sync_providers.dart';

final messageRepositoryProvider =
    Provider<MessageRepository>((ref) {
  final database =
      ref.watch(databaseProvider);

  final syncQueue =
      ref.watch(syncQueueProvider);

  return MessageRepository(
    database,
    syncQueue,
  );
});