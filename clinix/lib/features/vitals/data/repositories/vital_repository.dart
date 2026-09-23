import 'package:clinix/core/database/app_database.dart';
import 'package:clinix/core/database/daos/vital_dao.dart';
import 'package:clinix/core/sync/sync_queue.dart';

import '../../domain/entities/vital.dart' hide Vital;
import '../model/vital_model.dart';

class VitalRepository {
  final VitalDao _dao;
  final SyncQueue _syncQueue;

  VitalRepository(
    AppDatabase database,
    this._syncQueue,
  ) : _dao = database.vitalDao;

  Future<List<VitalModel>> getVitalsByPatientId(
    String patientId,
  ) async {
    final vitals =
        await _dao.getVitalsByPatientId(
      patientId,
    );

    return vitals.map(_toModel).toList();
  }

  Future<VitalModel?> getVitalById(
    String id,
  ) async {
    final vital =
        await _dao.getVitalById(id);

    if (vital == null) {
      return null;
    }

    return _toModel(vital);
  }

  Future<void> insertVital(
    VitalModel vital,
  ) async {
    await _dao.insertVital(
      VitalsCompanion.insert(
        id: vital.id,
        patientId: vital.patientId,
        type: vital.type.name,
        value: vital.value,
        unit: vital.unit,
        recordedAt: vital.recordedAt,
        recordedBy: vital.recordedBy,
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'VITAL',
      entityId: vital.id,
      operationType: 'CREATE',
      payload: vital.toJson(),
      baseVersion: 1,
    );
  }

  Future<void> deleteVital(
    String id,
  ) async {
    await _dao.deleteVital(id);

    await _syncQueue.enqueue(
      entityType: 'VITAL',
      entityId: id,
      operationType: 'DELETE',
      payload: {
        'id': id,
      },
      baseVersion: 1,
    );
  }

  VitalModel _toModel(Vital vital) {
    return VitalModel(
      id: vital.id,
      patientId: vital.patientId,
      type: VitalType.values.firstWhere(
        (type) => type.name == vital.type,
        orElse: () => VitalType.heartRate,
      ),
      value: vital.value,
      unit: vital.unit,
      recordedAt: vital.recordedAt,
      recordedBy: vital.recordedBy,
    );
  }
}