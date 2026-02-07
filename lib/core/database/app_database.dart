import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tasks_table.dart';
import 'tables/water_intakes_table.dart';
import 'tables/exercises_table.dart';
import 'tables/sleep_logs_table.dart';

part 'app_database.g.dart';

/// Main application database
@DriftDatabase(tables: [Tasks, WaterIntakes, Exercises, SleepLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(waterIntakes);
        }
        if (from < 3) {
          await m.createTable(exercises);
        }
        if (from < 4) {
          await m.createTable(sleepLogs);
        }
      },
    );
  }

  // ===== Task Operations =====

  /// Get all active tasks (not deleted)
  Future<List<Task>> getAllTasks() {
    return (select(tasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(tasks)
          ..where((t) => 
              t.isDeleted.equals(false) &
              t.dueDate.isBiggerOrEqualValue(startOfDay) &
              t.dueDate.isSmallerThanValue(endOfDay)))
        .get();
  }

  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(String category) {
    return (select(tasks)
          ..where((t) => t.isDeleted.equals(false) & t.category.equals(category)))
        .get();
  }

  /// Get pending tasks
  Future<List<Task>> getPendingTasks() {
    return (select(tasks)
          ..where((t) => 
              t.isDeleted.equals(false) & 
              t.status.equalsValue(TaskStatus.pending)))
        .get();
  }

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks() {
    return (select(tasks)
          ..where((t) => 
              t.isDeleted.equals(false) & 
              t.status.equalsValue(TaskStatus.completed)))
        .get();
  }

  /// Get subtasks of a parent task
  Future<List<Task>> getSubtasks(String parentId) {
    return (select(tasks)
          ..where((t) => t.isDeleted.equals(false) & t.parentTaskId.equals(parentId)))
        .get();
  }

  /// Insert a new task
  Future<int> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  /// Update a task
  Future<bool> updateTask(Task task) {
    return update(tasks).replace(task);
  }

  /// Mark task as completed
  Future<int> completeTask(String taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        status: const Value(TaskStatus.completed),
        completedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete a task
  Future<int> deleteTask(String taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Watch all tasks (reactive stream)
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watch tasks for today
  Stream<List<Task>> watchTodaysTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(tasks)
          ..where((t) => 
              t.isDeleted.equals(false) &
              t.dueDate.isBiggerOrEqualValue(startOfDay) &
              t.dueDate.isSmallerThanValue(endOfDay)))
        .watch();
  }

  /// Get task count by status
  Future<int> getTaskCountByStatus(TaskStatus status) async {
    final count = countAll();
    final query = selectOnly(tasks)
      ..addColumns([count])
      ..where(tasks.isDeleted.equals(false) & tasks.status.equalsValue(status));
    
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ===== Water Intake Operations =====

  /// Log water intake
  Future<int> logWaterIntake(int amountMl, {String? note}) {
    return into(waterIntakes).insert(WaterIntakesCompanion.insert(
      amountMl: amountMl,
      note: Value(note),
    ));
  }

  /// Get today's water intake logs
  Future<List<WaterIntake>> getTodaysWaterIntakes() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(waterIntakes)
          ..where((w) =>
              w.loggedAt.isBiggerOrEqualValue(startOfDay) &
              w.loggedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(w) => OrderingTerm.desc(w.loggedAt)]))
        .get();
  }

  /// Get total ml consumed today
  Future<int> getTodaysTotalWaterMl() async {
    final intakes = await getTodaysWaterIntakes();
    return intakes.fold<int>(0, (sum, intake) => sum + intake.amountMl);
  }

  /// Watch today's total water intake
  Stream<int> watchTodaysTotalWaterMl() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(waterIntakes)
          ..where((w) =>
              w.loggedAt.isBiggerOrEqualValue(startOfDay) &
              w.loggedAt.isSmallerThanValue(endOfDay)))
        .watch()
        .map((intakes) => intakes.fold<int>(0, (sum, i) => sum + i.amountMl));
  }

  /// Delete a water intake log
  Future<int> deleteWaterIntake(int id) {
    return (delete(waterIntakes)..where((w) => w.id.equals(id))).go();
  }

  // ===== Exercise Operations =====

  /// Insert a new exercise log
  Future<int> insertExercise(ExercisesCompanion exercise) {
    return into(exercises).insert(exercise);
  }

  /// Get all exercises
  Future<List<Exercise>> getAllExercises() {
    return (select(exercises)
          ..orderBy([(e) => OrderingTerm.desc(e.performedAt)]))
        .get();
  }

  /// Get today's exercises
  Future<List<Exercise>> getTodaysExercises() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(exercises)
          ..where((e) =>
              e.performedAt.isBiggerOrEqualValue(startOfDay) &
              e.performedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(e) => OrderingTerm.desc(e.performedAt)]))
        .get();
  }

  /// Watch today's exercises
  Stream<List<Exercise>> watchTodaysExercises() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(exercises)
          ..where((e) =>
              e.performedAt.isBiggerOrEqualValue(startOfDay) &
              e.performedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(e) => OrderingTerm.desc(e.performedAt)]))
        .watch();
  }

  /// Get total exercise minutes today
  Future<int> getTodaysTotalExerciseMinutes() async {
    final todaysExercises = await getTodaysExercises();
    return todaysExercises.fold<int>(0, (sum, e) => sum + e.durationMinutes);
  }

  /// Watch today's total exercise minutes
  Stream<int> watchTodaysTotalExerciseMinutes() {
    return watchTodaysExercises()
        .map((exercises) => exercises.fold<int>(0, (sum, e) => sum + e.durationMinutes));
  }

  /// Delete an exercise
  Future<int> deleteExercise(String id) {
    return (delete(exercises)..where((e) => e.id.equals(id))).go();
  }

  // ===== Sleep Operations =====

  /// Insert a new sleep log
  Future<int> insertSleepLog(SleepLogsCompanion log) {
    return into(sleepLogs).insert(log);
  }

  /// Get all sleep logs
  Future<List<SleepLog>> getAllSleepLogs() {
    return (select(sleepLogs)
          ..orderBy([(s) => OrderingTerm.desc(s.sleepDate)]))
        .get();
  }

  /// Get last night's sleep log (most recent)
  Future<SleepLog?> getLastNightsSleep() async {
    final logs = await (select(sleepLogs)
          ..orderBy([(s) => OrderingTerm.desc(s.sleepDate)])
          ..limit(1))
        .get();
    return logs.isEmpty ? null : logs.first;
  }

  /// Watch last night's sleep
  Stream<SleepLog?> watchLastNightsSleep() {
    return (select(sleepLogs)
          ..orderBy([(s) => OrderingTerm.desc(s.sleepDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Get sleep log for a specific date
  Future<SleepLog?> getSleepForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logs = await (select(sleepLogs)
          ..where((s) =>
              s.sleepDate.isBiggerOrEqualValue(startOfDay) &
              s.sleepDate.isSmallerThanValue(endOfDay)))
        .get();
    return logs.isEmpty ? null : logs.first;
  }

  /// Delete a sleep log
  Future<int> deleteSleepLog(String id) {
    return (delete(sleepLogs)..where((s) => s.id.equals(id))).go();
  }
}

/// Opens the database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'routine_assistant.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
