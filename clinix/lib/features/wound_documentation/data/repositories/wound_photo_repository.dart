import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/database/daos/wound_photo_dao.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:drift/drift.dart';

import '../model/wound_photo_model.dart';

class WoundPhotoRepository {
  final WoundPhotoDao _dao;
  final SyncQueue _syncQueue;

  WoundPhotoRepository(
    AppDatabase database,
    this._syncQueue,
  ) : _dao = database.woundPhotoDao;

  Future<List<WoundPhotoModel>> getWoundPhotosByPatientId(
    String patientId,
  ) async {
    final photos = await _dao.getWoundPhotosByPatientId(patientId);
    return photos.map(_toModel).toList();
  }

  Future<WoundPhotoModel?> getWoundPhotoById(String id) async {
    final photo = await _dao.getWoundPhotoById(id);

    if (photo == null) {
      return null;
    }

    return _toModel(photo);
  }

  Future<void> addWoundPhoto(WoundPhotoModel photo) async {
    await _dao.insertWoundPhoto(
      WoundPhotosCompanion.insert(
        id: photo.id,
        patientId: photo.patientId,
        filePath: photo.filePath,
        serverFilePath: Value(photo.serverFilePath),
        note: photo.note,
        capturedAt: photo.capturedAt,
        capturedBy: photo.capturedBy,
        status: photo.status,
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'WOUND_PHOTO',
      entityId: photo.id,
      operationType: 'CREATE',
      payload: photo.toJson(),
      baseVersion: 1,
    );
  }

  Future<void> updateWoundPhoto(WoundPhotoModel photo) async {
    await _dao.updateWoundPhoto(
      WoundPhotosCompanion(
        id: Value(photo.id),
        patientId: Value(photo.patientId),
        filePath: Value(photo.filePath),
        serverFilePath: Value(photo.serverFilePath),
        note: Value(photo.note),
        capturedAt: Value(photo.capturedAt),
        capturedBy: Value(photo.capturedBy),
        status: Value(photo.status),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'WOUND_PHOTO',
      entityId: photo.id,
      operationType: 'UPDATE',
      payload: photo.toJson(),
      baseVersion: 1,
    );
  }

  Future<void> deleteWoundPhoto(String id) async {
    await _dao.deleteWoundPhoto(id);

    await _syncQueue.enqueue(
      entityType: 'WOUND_PHOTO',
      entityId: id,
      operationType: 'DELETE',
      payload: {'id': id},
      baseVersion: 1,
    );
  }

  WoundPhotoModel _toModel(dynamic photo) {
    return WoundPhotoModel(
      id: photo.id,
      patientId: photo.patientId,
      filePath: photo.filePath,
      serverFilePath: photo.serverFilePath,
      note: photo.note,
      capturedAt: photo.capturedAt,
      capturedBy: photo.capturedBy,
      status: photo.status,
    );
  }
}