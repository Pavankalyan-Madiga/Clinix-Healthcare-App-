enum VitalType {
  bloodPressure,
  heartRate,
  temperature,
  oxygenSaturation,
  respiratoryRate,
}

class Vital {
  final String id;
  final String patientId;
  final VitalType type;
  final String value;
  final String unit;
  final DateTime recordedAt;
  final String recordedBy;

  const Vital({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.recordedBy,
  });
}