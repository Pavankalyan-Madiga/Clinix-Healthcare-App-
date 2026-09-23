
import 'package:clinix/features/notes/domain/entites/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.patientId,
    required super.content,
    required super.author,
    required super.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      patientId: json['patient_id'],
      content: json['content'],
      author: json['author'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'content': content,
      'author': author,
      'created_at': createdAt,
    };
  }
}