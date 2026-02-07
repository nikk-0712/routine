import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Default sleep goal in hours
const defaultSleepGoalHours = 8;

/// Sleep repository for managing sleep logs
class SleepRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SleepRepository(this._db);

  /// Log sleep
  Future<void> logSleep({
    required DateTime bedtime,
    required DateTime wakeTime,
    int quality = 3,
    String? notes,
  }) async {
    // Calculate duration in minutes
    final durationMinutes = wakeTime.difference(bedtime).inMinutes;
    
    // Sleep date is the night of (bedtime date)
    final sleepDate = DateTime(bedtime.year, bedtime.month, bedtime.day);

    await _db.insertSleepLog(SleepLogsCompanion.insert(
      id: _uuid.v4(),
      bedtime: bedtime,
      wakeTime: wakeTime,
      durationMinutes: durationMinutes,
      quality: Value(quality),
      notes: Value(notes),
      sleepDate: sleepDate,
    ));
  }

  /// Get last night's sleep
  Future<SleepLog?> getLastNightsSleep() => _db.getLastNightsSleep();

  /// Watch last night's sleep
  Stream<SleepLog?> watchLastNightsSleep() => _db.watchLastNightsSleep();

  /// Get sleep for a specific date
  Future<SleepLog?> getSleepForDate(DateTime date) => _db.getSleepForDate(date);

  /// Delete a sleep log
  Future<void> deleteSleepLog(String id) => _db.deleteSleepLog(id);
}

/// Sleep repository provider
final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SleepRepository(db);
});

/// Last night's sleep provider
final lastNightsSleepProvider = StreamProvider<SleepLog?>((ref) {
  final repository = ref.watch(sleepRepositoryProvider);
  return repository.watchLastNightsSleep();
});

/// Sleep progress provider (percentage of daily goal)
final sleepProgressProvider = Provider<double>((ref) {
  final sleepAsync = ref.watch(lastNightsSleepProvider);
  final sleep = sleepAsync.whenOrNull(data: (s) => s);
  if (sleep == null) return 0.0;
  
  final goalMinutes = defaultSleepGoalHours * 60;
  return (sleep.durationMinutes / goalMinutes).clamp(0.0, 1.0);
});

/// Format duration in hours and minutes
String formatSleepDuration(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (mins == 0) {
    return '${hours}h';
  }
  return '${hours}h ${mins}m';
}

/// Get quality label from rating
String getQualityLabel(int quality) {
  switch (quality) {
    case 1:
      return 'Poor';
    case 2:
      return 'Fair';
    case 3:
      return 'Good';
    case 4:
      return 'Great';
    case 5:
      return 'Excellent';
    default:
      return 'Good';
  }
}
