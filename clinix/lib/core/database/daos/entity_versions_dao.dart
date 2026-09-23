import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/entity_versions_table.dart';

part 'entity_versions_dao.g.dart';

@DriftAccessor(
  tables: [
    EntityVersions,
  ],
)
class EntityVersionsDao
    extends DatabaseAccessor<AppDatabase>
    with _$EntityVersionsDaoMixin {
  EntityVersionsDao(super.db);

  Future<EntityVersion?> getVersion(
    String entityType,
    String entityId,
  ) {
    return (select(entityVersions)
          ..where(
            (item) =>
                item.entityType.equals(entityType) &
                item.entityId.equals(entityId),
          ))
        .getSingleOrNull();
  }

  Future<int> getLatestVersion() async {
    final result = await customSelect(
      'SELECT MAX(version) AS max_version '
      'FROM entity_versions',
    ).getSingle();

    return result.read<int?>('max_version') ?? 0;
  }

  Future<void> createVersion({
    required String entityType,
    required String entityId,
    int version = 1,
  }) {
    return into(entityVersions).insert(
      EntityVersionsCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        version: Value(version),
        updatedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateVersion({
    required String entityType,
    required String entityId,
    required int version,
  }) {
    return (update(entityVersions)
          ..where(
            (item) =>
                item.entityType.equals(entityType) &
                item.entityId.equals(entityId),
          ))
        .write(
      EntityVersionsCompanion(
        version: Value(version),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setVersion({
    required String entityType,
    required String entityId,
    required int version,
  }) async {
    final existing = await getVersion(
      entityType,
      entityId,
    );

    if (existing == null) {
      await createVersion(
        entityType: entityType,
        entityId: entityId,
        version: version,
      );
      return;
    }

    await updateVersion(
      entityType: entityType,
      entityId: entityId,
      version: version,
    );
  }
}