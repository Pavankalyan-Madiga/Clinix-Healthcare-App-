// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vital_dao.dart';

// ignore_for_file: type=lint
mixin _$VitalDaoMixin on DatabaseAccessor<AppDatabase> {
  $VitalsTable get vitals => attachedDatabase.vitals;
  VitalDaoManager get managers => VitalDaoManager(this);
}

class VitalDaoManager {
  final _$VitalDaoMixin _db;
  VitalDaoManager(this._db);
  $$VitalsTableTableManager get vitals =>
      $$VitalsTableTableManager(_db.attachedDatabase, _db.vitals);
}
