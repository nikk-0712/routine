import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tasks_table.dart';

part 'app_database.g.dart';

/// Main application database
@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
}

/// Opens the database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'routine_assistant.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
