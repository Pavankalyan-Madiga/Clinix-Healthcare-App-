class WoundPhotoEntity {
  final String id;
  final String patientId;
  final String filePath;
  final String serverFilePath;
  final String note;
  final DateTime capturedAt;
  final String capturedBy;
  final String status;

  const WoundPhotoEntity({
    required this.id,
    required this.patientId,
    required this.filePath,
    required this.serverFilePath,
    required this.note,
    required this.capturedAt,
    required this.capturedBy,
    required this.status,
  });
}