class VoiceNote {
  final String id;
  final String patientId;
  final String filePath;
  final String createdAt;
  final int durationSeconds;

  const VoiceNote({
    required this.id,
    required this.patientId,
    required this.filePath,
    required this.createdAt,
    required this.durationSeconds,
  });
}