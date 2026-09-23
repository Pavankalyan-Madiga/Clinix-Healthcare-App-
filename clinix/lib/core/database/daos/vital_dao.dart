import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/vitals_table.dart';

part 'vital_dao.g.dart';

@DriftAccessor(
  tables: [
    Vitals,
  ],
)
class VitalDao extends DatabaseAccessor<AppDatabase>
    with _$VitalDaoMixin {
  VitalDao(super.db);

  Future<List<Vital>> getAllVitals() {
    return (select(vitals)
          ..orderBy([
            (vital) => OrderingTerm.desc(
              vital.recordedAt,
            ),
          ]))
        .get();
  }

  Future<List<Vital>> getVitalsByPatientId(
    String patientId,
  ) {
    return (select(vitals)
          ..where(
            (vital) => vital.patientId.equals(
              patientId,
            ),
          )
          ..orderBy([
            (vital) => OrderingTerm.desc(
              vital.recordedAt,
            ),
          ]))
        .get();
  }

  Future<Vital?> getVitalById(
    String id,
  ) {
    return (select(vitals)
          ..where(
            (vital) => vital.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<void> insertVital(
    VitalsCompanion vital,
  ) {
    return into(vitals).insert(
      vital,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateVital(
    VitalsCompanion vital,
  ) {
    final vitalId = vital.id.value;

    return (update(vitals)
          ..where(
            (item) => item.id.equals(vitalId),
          ))
        .write(vital);
  }

  Future<void> deleteVital(
    String id,
  ) {
    return (delete(vitals)
          ..where(
            (vital) => vital.id.equals(id),
          ))
        .go();
  }
}