// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wound_photo_dao.dart';

// ignore_for_file: type=lint
mixin _$WoundPhotoDaoMixin on DatabaseAccessor<AppDatabase> {
  $WoundPhotosTable get woundPhotos => attachedDatabase.woundPhotos;
  WoundPhotoDaoManager get managers => WoundPhotoDaoManager(this);
}

class WoundPhotoDaoManager {
  final _$WoundPhotoDaoMixin _db;
  WoundPhotoDaoManager(this._db);
  $$WoundPhotosTableTableManager get woundPhotos =>
      $$WoundPhotosTableTableManager(_db.attachedDatabase, _db.woundPhotos);
}
