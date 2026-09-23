import 'package:clinix/features/tasks/data/model/task_model.dart';
import 'package:clinix/features/tasks/domain/entites/task.dart';
import 'package:clinix/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDetailsPage extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailsPage({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailsPage> createState() =>
      _TaskDetailsPageState();
}

class _TaskDetailsPageState
    extends ConsumerState<TaskDetailsPage> {
  late TaskStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.task.status;
  }

  Future<void> _saveChanges() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updatedTask = widget.task.copyWith(
        status: _status,
      );

      final repository =
          ref.read(taskRepositoryProvider);

      await repository.updateTask(updatedTask);

      if (!mounted) return;

      Navigator.pop(
        context,
        updatedTask,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save task: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF152A5B),
          ),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('Task Information'),
            const SizedBox(height: 12),
            _buildInformation(),
            const SizedBox(height: 24),
            _buildSectionTitle('Update Status'),
            const SizedBox(height: 12),
            _buildStatusSelector(),
            const SizedBox(height: 30),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF147DE5),
              size: 27,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152A5B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF667494),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF152A5B),
      ),
    );
  }

  Widget _buildInformation() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow(
            'Task ID',
            widget.task.id,
          ),
          const Divider(height: 24),
          _infoRow(
            'Patient ID',
            widget.task.patientId,
          ),
          const Divider(height: 24),
          _infoRow(
            'Assigned To',
            widget.task.assignedTo,
          ),
          const Divider(height: 24),
          _infoRow(
            'Due Date',
            widget.task.dueDate,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667494),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152A5B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _statusOption(
            TaskStatus.pending,
            'Pending',
            'Task has not started',
            Icons.assignment_outlined,
          ),
          _statusOption(
            TaskStatus.inProgress,
            'In Progress',
            'Task is currently being handled',
            Icons.timelapse,
          ),
          _statusOption(
            TaskStatus.completed,
            'Completed',
            'Task has been completed',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _statusOption(
    TaskStatus status,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final selected = _status == status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving
            ? null
            : () {
                setState(() {
                  _status = status;
                });
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEAF4FF)
                      : const Color(0xFFF5F6F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF147DE5)
                      : const Color(0xFF667494),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152A5B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667494),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? const Color(0xFF147DE5)
                    : const Color(0xFFB4BBC8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _saving
            ? null
            : _saveChanges,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF147DE5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFE8ECF2),
      ),
    );
  }
}