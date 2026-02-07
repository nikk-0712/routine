import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/tables/tasks_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../tasks/data/tasks_repository.dart';
import '../health/data/hydration_repository.dart';

/// Insights screen - analytics and progress tracking
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final waterMlAsync = ref.watch(todaysWaterIntakeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Insights',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your productivity at a glance',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              tasksAsync.when(
                data: (tasks) => _buildSummaryCards(tasks, waterMlAsync),
                loading: () => _buildSummaryCardsLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Task Completion Chart
              Text(
                'Task Completion',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              tasksAsync.when(
                data: (tasks) => _buildTaskChart(tasks),
                loading: () => _buildChartLoading(),
                error: (_, __) => _buildChartError(),
              ),
              const SizedBox(height: 24),

              // Category Distribution
              Text(
                'Tasks by Category',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              tasksAsync.when(
                data: (tasks) => _buildCategoryPieChart(tasks),
                loading: () => _buildChartLoading(),
                error: (_, __) => _buildChartError(),
              ),
              const SizedBox(height: 24),

              // Productivity Tips
              Text(
                'Productivity Tips',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildProductivityTips(tasksAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<dynamic> tasks, AsyncValue<int> waterMlAsync) {
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = tasks.where((t) => t.status != TaskStatus.completed).length;
    final waterMl = waterMlAsync.whenOrNull(data: (ml) => ml) ?? 0;
    final glasses = (waterMl / glassSize).floor();

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle,
            value: '$completed',
            label: 'Completed',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.pending,
            value: '$pending',
            label: 'Pending',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.water_drop,
            value: '$glasses',
            label: 'Glasses',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.metricSmall.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardsLoading() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskChart(List<dynamic> tasks) {
    // Calculate completion stats for last 7 days
    final now = DateTime.now();
    final weekData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final completedOnDay = tasks.where((task) {
        if (task.status != TaskStatus.completed) return false;
        final updated = task.updatedAt;
        return updated.isAfter(dayStart) && updated.isBefore(dayEnd);
      }).length;

      return completedOnDay.toDouble();
    });

    final maxY = weekData.reduce((a, b) => a > b ? a : b);
    final yMax = (maxY > 0 ? maxY + 2 : 5.0).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final dayIndex = (now.weekday - 7 + groupIndex) % 7;
                return BarTooltipItem(
                  '${days[dayIndex]}\n${rod.toY.toInt()} tasks',
                  AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final index = value.toInt();
                  final date = now.subtract(Duration(days: 6 - index));
                  final dayIndex = date.weekday - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[dayIndex],
                      style: AppTypography.labelSmall.copyWith(
                        color: index == 6
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(7, (index) {
            final isToday = index == 6;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weekData[index],
                  color: isToday ? AppColors.primary : AppColors.primaryLight,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(List<dynamic> tasks) {
    // Group tasks by category
    final categories = <String, int>{};
    for (final task in tasks) {
      final cat = task.category as String;
      categories[cat] = (categories[cat] ?? 0) + 1;
    }

    if (categories.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No tasks to analyze',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final colors = {
      'Personal': AppColors.primaryLight,
      'Study': AppColors.secondary,
      'Work': AppColors.warning,
      'Health': AppColors.success,
    };

    final total = categories.values.reduce((a, b) => a + b);
    final sections = categories.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        color: colors[entry.key] ?? AppColors.textSecondary,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        radius: 60,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key} (${entry.value})',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityTips(AsyncValue<List<dynamic>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final pending = tasks.where((t) => t.status != TaskStatus.completed).length;
        final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        final completionRate = tasks.isNotEmpty
            ? (completed / tasks.length * 100).toStringAsFixed(0)
            : '0';

        String tip;
        IconData icon;
        Color color;

        if (pending == 0 && completed > 0) {
          tip = 'Amazing! You\'ve completed all your tasks. Keep up the great work!';
          icon = Icons.celebration;
          color = AppColors.success;
        } else if (pending > 5) {
          tip = 'You have $pending pending tasks. Try breaking them into smaller chunks!';
          icon = Icons.tips_and_updates;
          color = AppColors.warning;
        } else if (int.parse(completionRate) > 70) {
          tip = '$completionRate% completion rate! You\'re on fire! 🔥';
          icon = Icons.local_fire_department;
          color = AppColors.accent;
        } else {
          tip = 'Focus on one task at a time. Small wins lead to big victories!';
          icon = Icons.psychology;
          color = AppColors.primary;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tip,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChartLoading() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildChartError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Error loading data',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}
