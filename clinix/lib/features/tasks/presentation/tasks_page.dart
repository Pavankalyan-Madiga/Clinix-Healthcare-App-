import 'package:clinix/features/tasks/presentation/task_detail_page.dart';
import 'package:clinix/features/tasks/presentation/widget/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/task_providers.dart';
import '../data/model/task_model.dart';
import '../domain/entites/task.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  List<TaskModel> _tasks = [];
  bool _loading = true;

  TaskStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    final tasks = await repository.getTasks();

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _openTask(TaskModel task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsPage(
          task: task,
        ),
      ),
    );

    if (!mounted) return;

    await _loadTasks();
  }

  List<TaskModel> get _filteredTasks {
    if (_selectedFilter == null) {
      return _tasks;
    }

    return _tasks
        .where(
          (task) => task.status == _selectedFilter,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            24,
                          ),
                          itemCount: filteredTasks.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];

                            return TaskCard(
                              task: task,
                              onTap: () => _openTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tasks',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF152A5B),
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_list,
              color: Color(0xFF147DE5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        children: [
          _buildFilterChip(
            label: 'All',
            selected: _selectedFilter == null,
            onSelected: () {
              setState(() {
                _selectedFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Pending',
            selected:
                _selectedFilter == TaskStatus.pending,
            onSelected: () {
              setState(() {
                _selectedFilter = TaskStatus.pending;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'In Progress',
            selected:
                _selectedFilter == TaskStatus.inProgress,
            onSelected: () {
              setState(() {
                _selectedFilter = TaskStatus.inProgress;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Completed',
            selected:
                _selectedFilter == TaskStatus.completed,
            onSelected: () {
              setState(() {
                _selectedFilter = TaskStatus.completed;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected
            ? FontWeight.w600
            : FontWeight.w500,
        color: selected
            ? const Color(0xFF147DE5)
            : const Color(0xFF667494),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFEAF4FF),
      side: BorderSide(
        color: selected
            ? const Color(0xFF147DE5)
            : const Color(0xFFE1E6EE),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;

    if (_selectedFilter == TaskStatus.pending) {
      message = 'No pending tasks';
    } else if (_selectedFilter == TaskStatus.inProgress) {
      message = 'No tasks in progress';
    } else if (_selectedFilter == TaskStatus.completed) {
      message = 'No completed tasks';
    } else {
      message = 'No tasks found';
    }

    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF667494),
        ),
      ),
    );
  }
}