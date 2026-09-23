import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/wound_photos_table.dart';

part 'wound_photo_dao.g.dart';

@DriftAccessor(
  tables: [
    WoundPhotos,
  ],
)
class WoundPhotoDao
    extends DatabaseAccessor<AppDatabase>
    with _$WoundPhotoDaoMixin {
  WoundPhotoDao(super.db);

  Future<List<WoundPhoto>> getAllWoundPhotos() {
    return (select(woundPhotos)
          ..orderBy([
            (photo) => OrderingTerm.desc(
              photo.capturedAt,
            ),
          ]))
        .get();
  }

  Future<List<WoundPhoto>> getWoundPhotosByPatientId(
    String patientId,
  ) {
    return (select(woundPhotos)
          ..where(
            (photo) =>
                photo.patientId.equals(patientId),
          )
          ..orderBy([
            (photo) => OrderingTerm.desc(
              photo.capturedAt,
            ),
          ]))
        .get();
  }

  Future<WoundPhoto?> getWoundPhotoById(
    String id,
  ) {
    return (select(woundPhotos)
          ..where(
            (photo) => photo.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<void> insertWoundPhoto(
    WoundPhotosCompanion photo,
  ) {
    return into(woundPhotos).insert(
      photo,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateWoundPhoto(
    WoundPhotosCompanion photo,
  ) {
    final photoId = photo.id.value;

    return (update(woundPhotos)
          ..where(
            (item) => item.id.equals(photoId),
          ))
        .write(photo);
  }

  Future<void> deleteWoundPhoto(
    String id,
  ) {
    return (delete(woundPhotos)
          ..where(
            (photo) => photo.id.equals(id),
          ))
        .go();
  }
}