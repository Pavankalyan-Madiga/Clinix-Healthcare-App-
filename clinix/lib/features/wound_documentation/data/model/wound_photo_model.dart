import '../../domain/entites/wound_photo.dart';

class WoundPhotoModel extends WoundPhotoEntity {
  const WoundPhotoModel({
    required super.id,
    required super.patientId,
    required super.filePath,
    required super.serverFilePath,
    required super.note,
    required super.capturedAt,
    required super.capturedBy,
    required super.status,
  });

  factory WoundPhotoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return WoundPhotoModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      serverFilePath:
          json['server_file_path']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      capturedAt: DateTime.parse(
        json['captured_at'].toString(),
      ),
      capturedBy:
          json['captured_by']?.toString() ?? '',
      status:
          json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'file_path': filePath,
      'server_file_path': serverFilePath,
      'note': note,
      'captured_at':
          capturedAt.toIso8601String(),
      'captured_by': capturedBy,
      'status': status,
    };
  }
}