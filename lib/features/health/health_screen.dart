import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'data/hydration_repository.dart';

/// Health screen - wellness tracking (water, exercise, nutrition, sleep)
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterMlAsync = ref.watch(todaysWaterIntakeProvider);
    final progressAsync = ref.watch(hydrationProgressProvider);

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
                'Quick Add',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickAddButtons(ref),
              const SizedBox(height: 24),

              // Other health metrics placeholder
              _buildComingSoonCard('Exercise Tracking', Icons.fitness_center),
              const SizedBox(height: 12),
              _buildComingSoonCard('Sleep Tracking', Icons.bedtime),
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
