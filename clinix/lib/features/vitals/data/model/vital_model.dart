import '../../domain/entities/vital.dart';

class VitalModel extends Vital {
  const VitalModel({
    required super.id,
    required super.patientId,
    required super.type,
    required super.value,
    required super.unit,
    required super.recordedAt,
    required super.recordedBy,
  });

  factory VitalModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VitalModel(
      id: json['id'],
      patientId: json['patient_id'],
      type: VitalType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => VitalType.heartRate,
      ),
      value: json['value'],
      unit: json['unit'],
      recordedAt: DateTime.parse(
        json['recorded_at'],
      ),
      recordedBy: json['recorded_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
      'recorded_by': recordedBy,
    };
  }
}