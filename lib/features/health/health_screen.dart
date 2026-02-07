import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'data/exercise_repository.dart';
import 'data/hydration_repository.dart';
import 'data/sleep_repository.dart';

/// Health screen - wellness tracking (water, exercise, nutrition, sleep)
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterMlAsync = ref.watch(todaysWaterIntakeProvider);
    final progressAsync = ref.watch(hydrationProgressProvider);
    final exerciseMinutesAsync = ref.watch(todaysExerciseMinutesProvider);
    final todaysExercisesAsync = ref.watch(todaysExercisesProvider);
    final lastSleepAsync = ref.watch(lastNightsSleepProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Health & Wellness',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Hydration Card
              _buildHydrationCard(context, ref, waterMlAsync, progressAsync),
              const SizedBox(height: 24),

              // Quick Add Section
              Text(
                'Quick Add Water',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickAddButtons(ref),
              const SizedBox(height: 24),

              // Exercise Card
              _buildExerciseCard(context, ref, exerciseMinutesAsync, todaysExercisesAsync),
              const SizedBox(height: 24),

              // Sleep Card
              _buildSleepCard(context, ref, lastSleepAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHydrationCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> waterMlAsync,
    AsyncValue<double> progressAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.water_drop, color: AppColors.secondary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Hydration',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Ring
          progressAsync.when(
            data: (progress) => _buildProgressRing(waterMlAsync, progress),
            loading: () => _buildProgressRing(waterMlAsync, 0),
            error: (_, __) => _buildProgressRing(waterMlAsync, 0),
          ),
          const SizedBox(height: 24),

          // Goal info
          Text(
            'Daily Goal: ${defaultDailyWaterGoalMl ~/ 1000}L (${defaultDailyWaterGoalMl ~/ glassSize} glasses)',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(AsyncValue<int> waterMlAsync, double progress) {
    final glasses = waterMlAsync.whenOrNull(data: (ml) => (ml / glassSize).floor()) ?? 0;
    final ml = waterMlAsync.whenOrNull(data: (ml) => ml) ?? 0;
    final goalGlasses = defaultDailyWaterGoalMl ~/ glassSize;
    
    // Clamp progress for display (but show actual value)
    final displayProgress = progress.clamp(0.0, 1.0);
    final isComplete = progress >= 1.0;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              backgroundColor: AppColors.surface,
              color: AppColors.surface,
            ),
          ),
          // Progress ring
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: displayProgress,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              color: isComplete ? AppColors.success : AppColors.secondary,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.water_drop,
                color: isComplete ? AppColors.success : AppColors.secondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                '$glasses',
                style: AppTypography.metricLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'of $goalGlasses glasses',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ml}ml',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickAddButton(
            label: '+1 Glass',
            icon: Icons.local_drink,
            color: AppColors.secondary,
            onTap: () => _logWater(ref, 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAddButton(
            label: '+2 Glasses',
            icon: Icons.local_drink_outlined,
            color: AppColors.primaryLight,
            onTap: () => _logWater(ref, 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAddButton(
            label: 'Bottle',
            icon: Icons.water,
            color: AppColors.primary,
            onTap: () => _logWater(ref, 2), // 500ml = 2 glasses
          ),
        ),
      ],
    );
  }

  Future<void> _logWater(WidgetRef ref, int glasses) async {
    final repository = ref.read(hydrationRepositoryProvider);
    await repository.logGlass(glasses: glasses);
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> minutesAsync,
    AsyncValue<List<Exercise>> exercisesAsync,
  ) {
    final minutes = minutesAsync.whenOrNull(data: (m) => m) ?? 0;
    final progress = (minutes / defaultExerciseGoalMinutes).clamp(0.0, 1.0);
    final isComplete = minutes >= defaultExerciseGoalMinutes;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.fitness_center, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exercise',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showLogExerciseSheet(context, ref),
                icon: Icon(Icons.add, color: AppColors.accent, size: 18),
                label: Text(
                  'Log',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress row
          Row(
            children: [
              // Mini progress ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surface,
                      color: isComplete ? AppColors.success : AppColors.accent,
                      strokeCap: StrokeCap.round,
                    ),
                    Icon(
                      isComplete ? Icons.check : Icons.directions_run,
                      color: isComplete ? AppColors.success : AppColors.accent,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$minutes',
                          style: AppTypography.metricSmall.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                        Text(
                          ' / $defaultExerciseGoalMinutes min',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete ? '🎉 Daily goal reached!' : 'Keep moving!',
                      style: AppTypography.labelSmall.copyWith(
                        color: isComplete ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Today's exercises
          exercisesAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Divider(color: AppColors.divider.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'Today\'s Activity',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exercises.take(3).map((e) => _buildExerciseItem(e)),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getExerciseIcon(exercise.exerciseType),
              color: AppColors.accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.exerciseType,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${exercise.durationMinutes} min',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (exercise.caloriesBurned != null) ...[
            const SizedBox(width: 8),
            Text(
              '${exercise.caloriesBurned} cal',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getExerciseIcon(String type) {
    switch (type.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.favorite;
      case 'hiit':
        return Icons.flash_on;
      default:
        return Icons.sports;
    }
  }

  void _showLogExerciseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogExerciseSheet(ref: ref),
    );
  }

  Widget _buildSleepCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SleepLog?> lastSleepAsync,
  ) {
    final lastSleep = lastSleepAsync.whenOrNull(data: (s) => s);
    final hasSleep = lastSleep != null;
    final durationMinutes = lastSleep?.durationMinutes ?? 0;
    final goalMinutes = defaultSleepGoalHours * 60;
    final progress = (durationMinutes / goalMinutes).clamp(0.0, 1.0);
    final isComplete = durationMinutes >= goalMinutes;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.bedtime, color: AppColors.primaryLight, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sleep',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showLogSleepSheet(context, ref),
                icon: Icon(Icons.add, color: AppColors.primaryLight, size: 18),
                label: Text(
                  'Log',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress row
          Row(
            children: [
              // Mini progress ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surface,
                      color: isComplete ? AppColors.success : AppColors.primaryLight,
                      strokeCap: StrokeCap.round,
                    ),
                    Icon(
                      isComplete ? Icons.check : Icons.nights_stay,
                      color: isComplete ? AppColors.success : AppColors.primaryLight,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Stats
              Expanded(
                child: hasSleep
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                formatSleepDuration(durationMinutes),
                                style: AppTypography.metricSmall.copyWith(
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              Text(
                                ' / ${defaultSleepGoalHours}h goal',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                final filled = index < (lastSleep?.quality ?? 3);
                                return Icon(
                                  filled ? Icons.star : Icons.star_border,
                                  color: filled ? AppColors.warning : AppColors.textSecondary,
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                getQualityLabel(lastSleep?.quality ?? 3),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No sleep logged',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap Log to add last night\'s sleep',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogSleepSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogSleepSheet(ref: ref),
    );
  }

  Widget _buildComingSoonCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Coming soon',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Quick add button widget
class _QuickAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Log exercise bottom sheet
class _LogExerciseSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _LogExerciseSheet({required this.ref});

  @override
  ConsumerState<_LogExerciseSheet> createState() => _LogExerciseSheetState();
}

class _LogExerciseSheetState extends ConsumerState<_LogExerciseSheet> {
  String _selectedType = exerciseTypes.first;
  int _duration = 30;
  String _intensity = 'medium';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Log Exercise',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Exercise type
            Text(
              'Type',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exerciseTypes.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedType = type);
                  },
                  backgroundColor: AppColors.surfaceVariant,
                  selectedColor: AppColors.accent,
                  labelStyle: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Duration slider
            Text(
              'Duration: $_duration minutes',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.surfaceVariant,
              onChanged: (value) => setState(() => _duration = value.toInt()),
            ),
            const SizedBox(height: 16),

            // Intensity
            Text(
              'Intensity',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: intensityLevels.map((level) {
                final isSelected = _intensity == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _intensity = level),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _getIntensityColor(level) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          level[0].toUpperCase() + level.substring(1),
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Log button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _logExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Log Exercise',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  Future<void> _logExercise() async {
    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      await repository.logExercise(
        exerciseType: _selectedType,
        durationMinutes: _duration,
        intensity: _intensity,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log exercise: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Log sleep bottom sheet
class _LogSleepSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _LogSleepSheet({required this.ref});

  @override
  ConsumerState<_LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends ConsumerState<_LogSleepSheet> {
  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;
  int _quality = 3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default: bedtime 11 PM, wake 7 AM
    _bedtime = const TimeOfDay(hour: 23, minute: 0);
    _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Log Sleep',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Bedtime
            Text(
              'Bedtime (last night)',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimePicker(
              time: _bedtime,
              icon: Icons.bedtime,
              onTap: () => _pickTime(isBedtime: true),
            ),
            const SizedBox(height: 20),

            // Wake time
            Text(
              'Wake time (this morning)',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimePicker(
              time: _wakeTime,
              icon: Icons.wb_sunny,
              onTap: () => _pickTime(isBedtime: false),
            ),
            const SizedBox(height: 20),

            // Duration preview
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, color: AppColors.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sleep duration: ${_calculateDuration()}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quality
            Text(
              'Sleep Quality',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = rating <= _quality;
                return GestureDetector(
                  onTap: () => setState(() => _quality = rating),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? AppColors.warning : AppColors.textSecondary,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                getQualityLabel(_quality),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Log button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _logSleep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Log Sleep',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: 16),
            Text(
              time.format(context),
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _calculateDuration() {
    // Convert to minutes from midnight
    final bedMinutes = _bedtime.hour * 60 + _bedtime.minute;
    final wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    
    // Calculate duration (handle overnight sleep)
    int durationMinutes;
    if (wakeMinutes > bedMinutes) {
      // Same day (unusual, like a nap)
      durationMinutes = wakeMinutes - bedMinutes;
    } else {
      // Overnight sleep (normal case)
      durationMinutes = (24 * 60 - bedMinutes) + wakeMinutes;
    }
    
    return formatSleepDuration(durationMinutes);
  }

  Future<void> _pickTime({required bool isBedtime}) async {
    final initialTime = isBedtime ? _bedtime : _wakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryLight,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  Future<void> _logSleep() async {
    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(sleepRepositoryProvider);
      
      // Create DateTime objects for bedtime (yesterday) and wake time (today)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final bedtime = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        _bedtime.hour,
        _bedtime.minute,
      );
      
      final wakeTime = DateTime(
        today.year,
        today.month,
        today.day,
        _wakeTime.hour,
        _wakeTime.minute,
      );
      
      await repository.logSleep(
        bedtime: bedtime,
        wakeTime: wakeTime,
        quality: _quality,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log sleep: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
