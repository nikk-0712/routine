import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks_table.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Individual task card widget
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    this.onComplete,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPriorityColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isCompleted ? null : onEdit, // Tap to edit
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Completion checkbox
                  _buildCheckbox(isCompleted),
                  const SizedBox(width: 12),

                  // Task content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          task.title,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),

                        // Category & Due date
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Category chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor().withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.category,
                                style: AppTypography.labelSmall.copyWith(
                                  color: _getCategoryColor(),
                                ),
                              ),
                            ),

                            // Due date
                            if (task.dueDate != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: _getDueDateColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDueDate(task.dueDate!),
                                style: AppTypography.labelSmall.copyWith(
                                  color: _getDueDateColor(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Edit indicator for pending tasks
                  if (!isCompleted)
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  const SizedBox(width: 8),

                  // Priority indicator
                  _buildPriorityIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isCompleted) {
    return GestureDetector(
      onTap: isCompleted ? null : onComplete,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppColors.success : Colors.transparent,
          border: Border.all(
            color: isCompleted ? AppColors.success : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: _getPriorityColor(),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.error;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.primary;
      case TaskPriority.low:
        return AppColors.textSecondary;
    }
  }

  Color _getCategoryColor() {
    switch (task.category.toLowerCase()) {
      case 'study':
        return AppColors.secondary;
      case 'health':
        return AppColors.success;
      case 'work':
        return AppColors.warning;
      default:
        return AppColors.primaryLight;
    }
  }

  Color _getDueDateColor() {
    if (task.dueDate == null) return AppColors.textSecondary;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    if (dueDay.isBefore(today)) {
      return AppColors.error; // Overdue
    } else if (dueDay.isAtSameMomentAs(today)) {
      return AppColors.warning; // Due today
    } else {
      return AppColors.textSecondary; // Future
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dueDay.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (dueDay.isBefore(today)) {
      return 'Overdue';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Task?',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
