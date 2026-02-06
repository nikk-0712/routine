import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Daily water goal in ml (default: 8 glasses = 2000ml)
const int defaultDailyWaterGoalMl = 2000;
const int glassSize = 250; // 250ml per glass

/// Hydration repository provider
final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return HydrationRepository(database);
});

/// Stream of today's total water intake (reactive)
final todaysWaterIntakeProvider = StreamProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchTodaysTotalWaterMl();
});

/// Today's water intake as glasses (for display)
final todaysGlassesProvider = Provider<AsyncValue<int>>((ref) {
  final mlAsync = ref.watch(todaysWaterIntakeProvider);
  return mlAsync.whenData((ml) => (ml / glassSize).floor());
});

/// Progress towards daily goal (0.0 to 1.0+)
final hydrationProgressProvider = Provider<AsyncValue<double>>((ref) {
  final mlAsync = ref.watch(todaysWaterIntakeProvider);
  return mlAsync.whenData((ml) => ml / defaultDailyWaterGoalMl);
});

/// Repository for hydration operations
class HydrationRepository {
  final AppDatabase _db;

  HydrationRepository(this._db);

  /// Log a glass of water (250ml)
  Future<void> logGlass({int glasses = 1, String? note}) async {
    await _db.logWaterIntake(glasses * glassSize, note: note);
  }

  /// Log custom amount in ml
  Future<void> logCustomAmount(int ml, {String? note}) async {
    await _db.logWaterIntake(ml, note: note);
  }

  /// Get today's total in ml
  Future<int> getTodaysTotalMl() => _db.getTodaysTotalWaterMl();

  /// Get today's logs
  Future<List<WaterIntake>> getTodaysLogs() => _db.getTodaysWaterIntakes();

  /// Watch today's total
  Stream<int> watchTodaysTotalMl() => _db.watchTodaysTotalWaterMl();

  /// Delete a log entry
  Future<void> deleteLog(int id) => _db.deleteWaterIntake(id);
}
