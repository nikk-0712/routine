import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/tables/tasks_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'data/tasks_repository.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/task_card.dart';

/// Tasks screen - task management and scheduling
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Task stats
                  tasksAsync.when(
                    data: (tasks) {
                      final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
                      final total = tasks.length;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$completed/$total done',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Task list
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildTaskList(context, ref, tasks);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading tasks',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first task',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, List<Task> tasks) {
    // Separate pending and completed tasks
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Pending tasks
        if (pendingTasks.isNotEmpty) ...[
          Text(
            'To Do',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...pendingTasks.map((task) => TaskCard(
                key: ValueKey(task.id),
                task: task,
                onComplete: () => _completeTask(ref, task.id),
                onDelete: () => _deleteTask(ref, task.id),
              )),
        ],

        // Completed tasks
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Completed',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...completedTasks.map((task) => TaskCard(
                key: ValueKey(task.id),
                task: task,
                onComplete: null,
                onDelete: () => _deleteTask(ref, task.id),
              )),
        ],

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );
  }

  Future<void> _completeTask(WidgetRef ref, String taskId) async {
    final repository = ref.read(tasksRepositoryProvider);
    await repository.completeTask(taskId);
  }

  Future<void> _deleteTask(WidgetRef ref, String taskId) async {
    final repository = ref.read(tasksRepositoryProvider);
    await repository.deleteTask(taskId);
  }
}
