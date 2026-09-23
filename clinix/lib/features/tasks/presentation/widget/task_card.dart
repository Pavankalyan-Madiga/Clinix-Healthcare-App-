import 'package:clinix/features/tasks/domain/entites/task.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    final statusBackground = _statusBackground(task.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8ECF2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(task.status),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152A5B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667494),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.dueDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667494),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF667494),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFF147DE5);
      case TaskStatus.inProgress:
        return const Color(0xFFE39A00);
      case TaskStatus.completed:
        return const Color(0xFF18A567);
    }
  }

  Color _statusBackground(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFFEAF4FF);
      case TaskStatus.inProgress:
        return const Color(0xFFFFF5DD);
      case TaskStatus.completed:
        return const Color(0xFFEAF9F2);
    }
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.assignment_outlined;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.completed:
        return Icons.check;
    }
  }
}