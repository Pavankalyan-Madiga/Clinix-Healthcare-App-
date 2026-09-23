enum TaskStatus {
  pending,
  inProgress,
  completed,
}

class Task {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final String assignedTo;
  final String dueDate;
  final TaskStatus status;

  const Task({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    required this.status,
  });

  Task copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    String? assignedTo,
    String? dueDate,
    TaskStatus? status,
  }) {
    return Task(
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