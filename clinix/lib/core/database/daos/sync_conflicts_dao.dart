import 'package:clinix/core/database/tables/sync_conflicts_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'sync_conflicts_dao.g.dart';

@DriftAccessor(
  tables: [
    SyncConflicts,
  ],
)
class SyncConflictsDao extends DatabaseAccessor<AppDatabase>
    with _$SyncConflictsDaoMixin {
  SyncConflictsDao(super.db);

  Future<List<SyncConflict>> getAllConflicts() {
    return select(syncConflicts).get();
  }

  Future<SyncConflict?> getConflictByOperationId(
    String operationId,
  ) {
    return (select(syncConflicts)
          ..where(
            (conflict) =>
                conflict.operationId.equals(operationId),
          ))
        .getSingleOrNull();
  }

  Future<void> insertConflict(
    SyncConflictsCompanion conflict,
  ) {
    return into(syncConflicts).insert(
      conflict,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteConflict(String operationId) {
    return (delete(syncConflicts)
          ..where(
            (conflict) =>
                conflict.operationId.equals(operationId),
          ))
        .go();
  }
}