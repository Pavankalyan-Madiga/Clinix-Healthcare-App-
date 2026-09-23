
import 'package:clinix/features/tasks/domain/entites/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.patientId,
    required super.title,
    required super.description,
    required super.assignedTo,
    required super.dueDate,
    required super.status,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      patientId: json['patient_id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assigned_to'],
      dueDate: json['due_date'],
      status: TaskStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'due_date': dueDate,
      'status': status.name,
    };
  }
  
  @override
  TaskModel copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    String? assignedTo,
    String? dueDate,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
}