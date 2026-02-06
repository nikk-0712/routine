import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/tables/tasks_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../tasks/data/tasks_repository.dart';

/// Home dashboard screen - main entry point of the app
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              _buildHeader(),
              const SizedBox(height: 24),

              // Quick stats row
              tasksAsync.when(
                data: (tasks) => _buildStatsRow(tasks),
                loading: () => _buildStatsRowLoading(),
                error: (_, __) => _buildStatsRowError(),
              ),
              const SizedBox(height: 24),

              // Today's Progress
              Text(
                "Today's Focus",
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Today's tasks preview
              tasksAsync.when(
                data: (tasks) => _buildTodaysTasks(tasks),
                loading: () => _buildProgressPlaceholder(),
                error: (_, __) => _buildProgressPlaceholder(),
              ),

              const SizedBox(height: 24),

              // Weekly Overview
              Text(
                'Weekly Overview',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildWeeklyOverview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dashboard',
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(List<dynamic> tasks) {
    final pendingCount = tasks.where((t) => t.status != TaskStatus.completed).length;
    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
    final totalCount = tasks.length;

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.check_circle_outline,
          value: totalCount > 0 ? '$completedCount/$totalCount' : '0',
          label: 'Tasks',
          color: AppColors.primary,
          progress: totalCount > 0 ? completedCount / totalCount : 0,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.pending_actions,
          value: '$pendingCount',
          label: 'Pending',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.local_fire_department_outlined,
          value: '${completedCount * 10}',
          label: 'Points',
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildStatsRowLoading() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.check_circle_outline,
          value: '...',
          label: 'Tasks',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.pending_actions,
          value: '...',
          label: 'Pending',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.local_fire_department_outlined,
          value: '...',
          label: 'Points',
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildStatsRowError() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.error_outline,
          value: '--',
          label: 'Error',
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    double? progress,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (progress != null)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: AppColors.surface,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTypography.metricSmall.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysTasks(List<dynamic> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get tasks due today or pending without due date
    final todaysTasks = allTasks.where((task) {
      if (task.status == TaskStatus.completed) return false;
      if (task.dueDate == null) return true; // Show tasks without due date
      final dueDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return dueDay.isAtSameMomentAs(today) || dueDay.isBefore(today);
    }).take(3).toList();

    if (todaysTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.celebration_outlined,
                size: 48,
                color: AppColors.success.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                'All caught up!',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No pending tasks for today',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ...todaysTasks.map((task) => _buildMiniTaskItem(task)),
          if (allTasks.where((t) => t.status != TaskStatus.completed).length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'View all in Tasks →',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniTaskItem(dynamic task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPriorityColor(task.priority),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getCategoryColor(task.category).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              task.category,
              style: AppTypography.labelSmall.copyWith(
                color: _getCategoryColor(task.category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    // Placeholder for weekly chart - will be enhanced with FL Chart later
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1; // Monday = 0

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == currentDayIndex;
              final isPast = index < currentDayIndex;
              
              return Column(
                children: [
                  Text(
                    days[index],
                    style: AppTypography.labelSmall.copyWith(
                      color: isToday ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? AppColors.primary
                          : isPast
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.surface,
                      border: Border.all(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isPast
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.success,
                            )
                          : isToday
                              ? const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentDayIndex day streak',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
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
}
