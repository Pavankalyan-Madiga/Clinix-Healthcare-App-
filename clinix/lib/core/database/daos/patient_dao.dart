import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/patients_table.dart';

part 'patient_dao.g.dart';

@DriftAccessor(
  tables: [
    Patients,
  ],
)
class PatientDao extends DatabaseAccessor<AppDatabase>
    with _$PatientDaoMixin {
  PatientDao(super.db);

  Future<List<Patient>> getAllPatients() {
    return select(patients).get();
  }

  Future<Patient?> getPatientById(String id) {
    return (select(patients)
          ..where(
            (patient) => patient.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<void> insertPatient(
    PatientsCompanion patient,
  ) {
    return into(patients).insert(
      patient,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updatePatient(
    PatientsCompanion patient,
  ) {
    final patientId = patient.id.value;

    return (update(patients)
          ..where(
            (item) => item.id.equals(patientId),
          ))
        .write(patient);
  }

  Future<void> deletePatient(String id) {
    return (delete(patients)
          ..where(
            (patient) => patient.id.equals(id),
          ))
        .go();
  }
}