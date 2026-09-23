import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/entity_versions_dao.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/sync/conflict_repository.dart';
import '../core/sync/conflict_resolver.dart';
import '../core/sync/sync_engine.dart';
import '../core/sync/sync_queue.dart';
import '../core/sync/sync_repository.dart';
import '../features/voice_notes/data/repositories/voice_note_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: 'http://172.29.180.139:8000',
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final database = ref.read(appDatabaseProvider);

  return SyncRepository(database);
});

final syncQueueProvider = Provider<SyncQueue>((ref) {
  final repository = ref.read(syncRepositoryProvider);

  return SyncQueue(repository);
});

final voiceNoteRepositoryProvider =
    Provider<VoiceNoteRepository>((ref) {
  return VoiceNoteRepository(
    ref.read(appDatabaseProvider),
    ref.read(syncQueueProvider),
  );
});

final conflictRepositoryProvider =
    Provider<ConflictRepository>((ref) {
  final database = ref.read(appDatabaseProvider);

  return ConflictRepository(database);
});

final conflictResolverProvider =
    Provider<ConflictResolver>((ref) {
  final database = ref.read(appDatabaseProvider);

  return ConflictResolver(database);
});

final entityVersionsDaoProvider =
    Provider<EntityVersionsDao>((ref) {
  final database = ref.read(appDatabaseProvider);

  return database.entityVersionsDao;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final database = ref.read(appDatabaseProvider);

  return SyncEngine(
    ref.read(syncRepositoryProvider),
    ref.read(conflictRepositoryProvider),
    ref.read(connectivityServiceProvider),
    ref.read(apiClientProvider),
    ref.read(entityVersionsDaoProvider),
    database,
  );
});