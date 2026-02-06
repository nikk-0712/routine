import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks_table.dart';
import '../../../core/providers/database_provider.dart';

const _uuid = Uuid();

/// Tasks repository provider
final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return TasksRepository(database);
});

/// Stream of all tasks (reactive)
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllTasks();
});

/// Stream of today's tasks (reactive)
final todaysTasksProvider = StreamProvider<List<Task>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchTodaysTasks();
});

/// Pending tasks count
final pendingTasksCountProvider = FutureProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getTaskCountByStatus(TaskStatus.pending);
});

/// Completed tasks count
final completedTasksCountProvider = FutureProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getTaskCountByStatus(TaskStatus.completed);
});

/// Repository for task operations
class TasksRepository {
  final AppDatabase _db;

  TasksRepository(this._db);

  /// Create a new task
  Future<String> createTask({
    required String title,
    String? description,
    String category = 'Personal',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? estimatedMinutes,
    RecurrenceType recurrenceType = RecurrenceType.none,
    int recurrenceInterval = 1,
    String? parentTaskId,
  }) async {
    final id = _uuid.v4();
    
    await _db.insertTask(TasksCompanion.insert(
      id: id,
      title: title,
      description: Value(description),
      category: Value(category),
      priority: Value(priority),
      status: const Value(TaskStatus.pending),
      dueDate: Value(dueDate),
      scheduledStart: Value(scheduledStart),
      scheduledEnd: Value(scheduledEnd),
      estimatedMinutes: Value(estimatedMinutes),
      recurrenceType: Value(recurrenceType),
      recurrenceInterval: Value(recurrenceInterval),
      parentTaskId: Value(parentTaskId),
    ));
    
    return id;
  }

  /// Get all tasks
  Future<List<Task>> getAllTasks() => _db.getAllTasks();

  /// Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date) => _db.getTasksForDate(date);

  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(String category) => 
      _db.getTasksByCategory(category);

  /// Get subtasks
  Future<List<Task>> getSubtasks(String parentId) => _db.getSubtasks(parentId);

  /// Update a task
  Future<bool> updateTask(Task task) => _db.updateTask(task);

  /// Complete a task
  Future<void> completeTask(String taskId) => _db.completeTask(taskId);

  /// Delete a task (soft delete)
  Future<void> deleteTask(String taskId) => _db.deleteTask(taskId);

  /// Watch all tasks
  Stream<List<Task>> watchAllTasks() => _db.watchAllTasks();

  /// Watch today's tasks
  Stream<List<Task>> watchTodaysTasks() => _db.watchTodaysTasks();
}
