import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tasks_table.dart';
import 'tables/water_intakes_table.dart';
import 'tables/exercises_table.dart';
import 'tables/sleep_logs_table.dart';
import 'tables/subtasks_table.dart';
import 'tables/tags_table.dart';

part 'app_database.g.dart';

/// Main application database
@DriftDatabase(tables: [Tasks, WaterIntakes, Exercises, SleepLogs, Subtasks, Tags, TaskTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

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
        if (from < 5) {
          await m.createTable(subtasks);
        }
        if (from < 6) {
          await m.createTable(tags);
          await m.createTable(taskTags);
        }
        if (from < 7) {
          // Add sync columns to existing tables
          await m.addColumn(tasks, tasks.syncedAt);
          
          await m.addColumn(subtasks, subtasks.updatedAt);
          await m.addColumn(subtasks, subtasks.syncedAt);
          await m.addColumn(subtasks, subtasks.isDeleted);
          
          await m.addColumn(tags, tags.updatedAt);
          await m.addColumn(tags, tags.syncedAt);
          await m.addColumn(tags, tags.isDeleted);
          
          // Re-create TaskTags if needed or add columns (adding columns is safer)
          await m.addColumn(taskTags, taskTags.createdAt);
          await m.addColumn(taskTags, taskTags.updatedAt);
          await m.addColumn(taskTags, taskTags.syncedAt);
          await m.addColumn(taskTags, taskTags.isDeleted);
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

  // ===== Subtask Operations =====

  /// Insert a new subtask
  Future<int> insertSubtask(SubtasksCompanion subtask) {
    return into(subtasks).insert(subtask);
  }

  /// Get subtasks for a parent task
  Future<List<Subtask>> getSubtasksForTask(String parentTaskId) {
    return (select(subtasks)
          ..where((s) => s.parentTaskId.equals(parentTaskId))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .get();
  }

  /// Watch subtasks for a parent task
  Stream<List<Subtask>> watchSubtasksForTask(String parentTaskId) {
    return (select(subtasks)
          ..where((s) => s.parentTaskId.equals(parentTaskId))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .watch();
  }

  /// Update subtask completion status
  Future<int> updateSubtaskCompletion(String id, bool isCompleted) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ),
    );
  }

  /// Update subtask title
  Future<int> updateSubtaskTitle(String id, String title) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(title: Value(title)),
    );
  }

  /// Delete a subtask
  Future<int> deleteSubtask(String id) {
    return (delete(subtasks)..where((s) => s.id.equals(id))).go();
  }

  /// Delete all subtasks for a parent task
  Future<int> deleteSubtasksForTask(String parentTaskId) {
    return (delete(subtasks)..where((s) => s.parentTaskId.equals(parentTaskId))).go();
  }

  /// Get subtask count for a task (total and completed)
  Future<({int total, int completed})> getSubtaskCounts(String parentTaskId) async {
    final subs = await getSubtasksForTask(parentTaskId);
    final completed = subs.where((s) => s.isCompleted).length;
    return (total: subs.length, completed: completed);
  }

  // ===== Tag Operations =====

  /// Create a new tag
  Future<int> createTag(TagsCompanion tag) {
    return into(tags).insert(tag);
  }

  /// Get all tags
  Future<List<Tag>> getAllTags() {
    return select(tags).get();
  }
  
  /// Watch all tags
  Stream<List<Tag>> watchAllTags() {
    return select(tags).watch();
  }

  /// Delete a tag
  Future<int> deleteTag(String id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }

  /// Assign a tag to a task
  Future<int> addTagToTask(String taskId, String tagId) {
    return into(taskTags).insert(
      TaskTagsCompanion(
        taskId: Value(taskId),
        tagId: Value(tagId),
      ),
    );
  }

  /// Remove a tag from a task
  Future<int> removeTagFromTask(String taskId, String tagId) {
    return (delete(taskTags)
          ..where((t) => t.taskId.equals(taskId) & t.tagId.equals(tagId)))
        .go();
  }

  /// Get tags for a task
  Future<List<Tag>> getTagsForTask(String taskId) {
    final query = select(tags).join([
      innerJoin(taskTags, taskTags.tagId.equalsExp(tags.id)),
    ])
      ..where(taskTags.taskId.equals(taskId));

    return query.map((row) => row.readTable(tags)).get();
  }

  /// Watch tags for a task
  Stream<List<Tag>> watchTagsForTask(String taskId) {
    final query = select(tags).join([
      innerJoin(taskTags, taskTags.tagId.equalsExp(tags.id)),
    ])
      ..where(taskTags.taskId.equals(taskId));

    return query.map((row) => row.readTable(tags)).watch();
  }

  // ===== Sync Operations =====

  /// Get unsynced tasks (syncedAt is null or < updatedAt)
  Future<List<Task>> getUnsyncedTasks() {
    return (select(tasks)
          ..where((t) => t.syncedAt.isNull() | t.syncedAt.isSmallerThan(t.updatedAt)))
        .get();
  }

  /// Mark task as synced
  Future<void> markTaskSynced(String id) async {
    await (update(tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(syncedAt: Value(DateTime.now())));
  }

  /// Get task by ID
  Future<Task?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Upsert task from remote
  Future<void> upsertTaskFromRemote({
    required String id,
    required String title,
    String? description,
    required String category,
    required int priority,
    required int status,
    DateTime? dueDate,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? estimatedMinutes,
    required int recurrenceType,
    required int recurrenceInterval,
    String? parentTaskId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    required bool isDeleted,
  }) async {
    await into(tasks).insertOnConflictUpdate(TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      priority: Value(TaskPriority.values[priority]),
      status: Value(TaskStatus.values[status]),
      dueDate: Value(dueDate),
      scheduledStart: Value(scheduledStart),
      scheduledEnd: Value(scheduledEnd),
      estimatedMinutes: Value(estimatedMinutes),
      recurrenceType: Value(RecurrenceType.values[recurrenceType]),
      recurrenceInterval: Value(recurrenceInterval),
      parentTaskId: Value(parentTaskId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: Value(DateTime.now()),
      completedAt: Value(completedAt),
      isDeleted: Value(isDeleted),
    ));
  }

  /// Get unsynced tags
  Future<List<Tag>> getUnsyncedTags() {
    return (select(tags)
          ..where((t) => t.syncedAt.isNull() | t.syncedAt.isSmallerThan(t.updatedAt)))
        .get();
  }

  /// Mark tag as synced
  Future<void> markTagSynced(String id) async {
    await (update(tags)..where((t) => t.id.equals(id)))
        .write(TagsCompanion(syncedAt: Value(DateTime.now())));
  }

  /// Get tag by ID
  Future<Tag?> getTagById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Upsert tag from remote
  Future<void> upsertTagFromRemote({
    required String id,
    required String name,
    required int color,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
  }) async {
    await into(tags).insertOnConflictUpdate(TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: Value(DateTime.now()),
      isDeleted: Value(isDeleted),
    ));
  }

  /// Get unsynced task-tags
  Future<List<TaskTag>> getUnsyncedTaskTags() {
    return (select(taskTags)
          ..where((t) => t.syncedAt.isNull() | t.syncedAt.isSmallerThan(t.updatedAt)))
        .get();
  }

  /// Mark task-tag as synced
  Future<void> markTaskTagSynced(String taskId, String tagId) async {
    await (update(taskTags)
          ..where((t) => t.taskId.equals(taskId) & t.tagId.equals(tagId)))
        .write(TaskTagsCompanion(syncedAt: Value(DateTime.now())));
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
