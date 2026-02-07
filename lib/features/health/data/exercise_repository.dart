import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Common exercise types
const exerciseTypes = [
  'Walking',
  'Running',
  'Cycling',
  'Swimming',
  'Yoga',
  'Strength',
  'Cardio',
  'HIIT',
  'Other',
];

/// Intensity levels  
const intensityLevels = ['low', 'medium', 'high'];

/// Default exercise goal in minutes per day
const defaultExerciseGoalMinutes = 30;

/// Exercise repository for managing workout logs
class ExerciseRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  ExerciseRepository(this._db);

  /// Log a new exercise
  Future<void> logExercise({
    required String exerciseType,
    required int durationMinutes,
    int? caloriesBurned,
    String intensity = 'medium',
    String? notes,
    DateTime? performedAt,
  }) async {
    await _db.insertExercise(ExercisesCompanion.insert(
      id: _uuid.v4(),
      exerciseType: exerciseType,
      durationMinutes: durationMinutes,
      caloriesBurned: Value(caloriesBurned),
      intensity: Value(intensity),
      notes: Value(notes),
      performedAt: performedAt ?? DateTime.now(),
    ));
  }

  /// Get today's exercises
  Future<List<Exercise>> getTodaysExercises() => _db.getTodaysExercises();

  /// Watch today's exercises
  Stream<List<Exercise>> watchTodaysExercises() => _db.watchTodaysExercises();

  /// Get total minutes exercised today
  Future<int> getTodaysTotalMinutes() => _db.getTodaysTotalExerciseMinutes();

  /// Watch total minutes exercised today
  Stream<int> watchTodaysTotalMinutes() => _db.watchTodaysTotalExerciseMinutes();

  /// Delete an exercise
  Future<void> deleteExercise(String id) => _db.deleteExercise(id);
}

/// Exercise repository provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExerciseRepository(db);
});

/// Today's exercises provider
final todaysExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchTodaysExercises();
});

/// Today's total exercise minutes provider
final todaysExerciseMinutesProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchTodaysTotalMinutes();
});

/// Exercise progress provider (percentage of daily goal)
final exerciseProgressProvider = Provider<double>((ref) {
  final minutesAsync = ref.watch(todaysExerciseMinutesProvider);
  final minutes = minutesAsync.whenOrNull(data: (m) => m) ?? 0;
  return (minutes / defaultExerciseGoalMinutes).clamp(0.0, 1.0);
});
