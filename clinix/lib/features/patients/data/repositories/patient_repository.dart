import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/database/daos/entity_versions_dao.dart';
import 'package:clinix/core/database/daos/patient_dao.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:drift/drift.dart';

import '../model/patient_model.dart';

class PatientRepository {
  final PatientDao _dao;
  final EntityVersionsDao _versionDao;
  final SyncQueue _syncQueue;

  PatientRepository(
    AppDatabase database,
    this._syncQueue,
  )   : _dao = database.patientDao,
        _versionDao = database.entityVersionsDao;

  Future<List<PatientModel>> getPatients() async {
    final patients = await _dao.getAllPatients();

    return patients.map(_toModel).toList();
  }

  Future<PatientModel?> getPatientById(
    String id,
  ) async {
    final patient = await _dao.getPatientById(id);

    if (patient == null) {
      return null;
    }

    return _toModel(patient);
  }

  Future<void> insertPatient(
    PatientModel patient,
  ) async {
    await _dao.insertPatient(
      PatientsCompanion.insert(
        id: patient.id,
        firstName: patient.firstName,
        lastName: patient.lastName,
        dateOfBirth: patient.dateOfBirth,
        gender: patient.gender,
        room: patient.room,
        condition: patient.condition,
        status: patient.status,
      ),
    );
  }

  Future<void> updatePatient(
    PatientModel patient,
  ) async {
    await _dao.updatePatient(
      PatientsCompanion(
        id: Value(patient.id),
        firstName: Value(patient.firstName),
        lastName: Value(patient.lastName),
        dateOfBirth: Value(patient.dateOfBirth),
        gender: Value(patient.gender),
        room: Value(patient.room),
        condition: Value(patient.condition),
        status: Value(patient.status),
      ),
    );

    await _enqueuePatientUpdate(patient);
  }

  Future<void> updatePatientStatus(
    String patientId,
    String status,
  ) async {
    final patient = await getPatientById(patientId);

    if (patient == null) {
      return;
    }

    final updatedPatient = PatientModel(
      id: patient.id,
      firstName: patient.firstName,
      lastName: patient.lastName,
      dateOfBirth: patient.dateOfBirth,
      gender: patient.gender,
      room: patient.room,
      condition: patient.condition,
      status: status,
    );

    await _dao.updatePatient(
      PatientsCompanion(
        id: Value(patientId),
        status: Value(status),
      ),
    );

    await _enqueuePatientUpdate(updatedPatient);
  }

  Future<void> deletePatient(
    String id,
  ) async {
    await _dao.deletePatient(id);
  }

  Future<void> _enqueuePatientUpdate(
    PatientModel patient,
  ) async {
    final existingVersion =
        await _versionDao.getVersion(
      'PATIENT',
      patient.id,
    );

    final baseVersion =
        existingVersion?.version ?? 1;

    await _versionDao.setVersion(
      entityType: 'PATIENT',
      entityId: patient.id,
      version: baseVersion,
    );

    await _syncQueue.enqueue(
      entityType: 'PATIENT',
      entityId: patient.id,
      operationType: 'UPDATE',
      payload: patient.toJson(),
      baseVersion: baseVersion,
    );
  }

  PatientModel _toModel(
    Patient patient,
  ) {
    return PatientModel(
      id: patient.id,
      firstName: patient.firstName,
      lastName: patient.lastName,
      dateOfBirth: patient.dateOfBirth,
      gender: patient.gender,
      room: patient.room,
      condition: patient.condition,
      status: patient.status,
    );
  }
}