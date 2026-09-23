
import 'package:clinix/features/voice_notes/domain/voice_note.dart';

class VoiceNoteModel extends VoiceNote {
  const VoiceNoteModel({
    required super.id,
    required super.patientId,
    required super.filePath,
    required super.createdAt,
    required super.durationSeconds,
  });

  factory VoiceNoteModel.fromJson(Map<String, dynamic> json) {
    return VoiceNoteModel(
      id: json['id'],
      patientId: json['patient_id'],
      filePath: json['file_path'],
      createdAt: json['created_at'],
      durationSeconds: json['duration_seconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'file_path': filePath,
      'created_at': createdAt,
      'duration_seconds': durationSeconds,
    };
  }
}