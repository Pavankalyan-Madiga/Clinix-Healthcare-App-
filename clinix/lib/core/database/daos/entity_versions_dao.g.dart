// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_versions_dao.dart';

// ignore_for_file: type=lint
mixin _$EntityVersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EntityVersionsTable get entityVersions => attachedDatabase.entityVersions;
  EntityVersionsDaoManager get managers => EntityVersionsDaoManager(this);
}

class EntityVersionsDaoManager {
  final _$EntityVersionsDaoMixin _db;
  EntityVersionsDaoManager(this._db);
  $$EntityVersionsTableTableManager get entityVersions =>
      $$EntityVersionsTableTableManager(
        _db.attachedDatabase,
        _db.entityVersions,
      );
}
