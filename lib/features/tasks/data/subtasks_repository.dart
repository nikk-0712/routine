import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

/// Subtasks repository for managing nested task items
class SubtasksRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SubtasksRepository(this._db);

  /// Add a new subtask to a parent task
  Future<void> addSubtask({
    required String parentTaskId,
    required String title,
    int sortOrder = 0,
  }) async {
    await _db.insertSubtask(SubtasksCompanion.insert(
      id: _uuid.v4(),
      parentTaskId: parentTaskId,
      title: title,
      sortOrder: Value(sortOrder),
    ));
  }

  /// Get subtasks for a task
  Future<List<Subtask>> getSubtasks(String parentTaskId) => 
      _db.getSubtasksForTask(parentTaskId);

  /// Watch subtasks for a task
  Stream<List<Subtask>> watchSubtasks(String parentTaskId) => 
      _db.watchSubtasksForTask(parentTaskId);

  /// Toggle subtask completion
  Future<void> toggleSubtask(String id, bool isCompleted) => 
      _db.updateSubtaskCompletion(id, isCompleted);

  /// Update subtask title
  Future<void> updateTitle(String id, String title) => 
      _db.updateSubtaskTitle(id, title);

  /// Delete a subtask
  Future<void> deleteSubtask(String id) => _db.deleteSubtask(id);

  /// Delete all subtasks for a parent task
  Future<void> deleteAllForTask(String parentTaskId) => 
      _db.deleteSubtasksForTask(parentTaskId);

  /// Get subtask counts (total, completed)
  Future<({int total, int completed})> getCounts(String parentTaskId) => 
      _db.getSubtaskCounts(parentTaskId);
}

/// Subtasks repository provider
final subtasksRepositoryProvider = Provider<SubtasksRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SubtasksRepository(db);
});

/// Subtasks for a specific task provider (family)
final subtasksForTaskProvider = StreamProvider.family<List<Subtask>, String>((ref, taskId) {
  final repository = ref.watch(subtasksRepositoryProvider);
  return repository.watchSubtasks(taskId);
});
