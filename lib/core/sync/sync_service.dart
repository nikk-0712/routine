import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../providers/database_provider.dart';

/// Sync service for pushing local changes to Supabase and pulling remote changes
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  SyncService(this._db) : _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Sync all data (push then pull)
  Future<SyncResult> syncAll() async {
    if (_userId == null) {
      return SyncResult(success: false, error: 'User not authenticated');
    }

    try {
      // Push local changes
      await _pushTasks();
      await _pushTags();
      await _pushTaskTags();

      // Pull remote changes
      await _pullTasks();
      await _pullTags();
      await _pullTaskTags();

      return SyncResult(success: true);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  // ==================== PUSH OPERATIONS ====================

  Future<void> _pushTasks() async {
    // Get unsynced tasks (syncedAt is null or < updatedAt)
    final tasks = await _db.getUnsyncedTasks();
    
    for (final task in tasks) {
      final data = {
        'id': task.id,
        'user_id': _userId,
        'title': task.title,
        'description': task.description,
        'category': task.category,
        'priority': task.priority.index,
        'status': task.status.index,
        'due_date': task.dueDate?.toIso8601String(),
        'scheduled_start': task.scheduledStart?.toIso8601String(),
        'scheduled_end': task.scheduledEnd?.toIso8601String(),
        'estimated_minutes': task.estimatedMinutes,
        'recurrence_type': task.recurrenceType.index,
        'recurrence_interval': task.recurrenceInterval,
        'parent_task_id': task.parentTaskId,
        'created_at': task.createdAt.toIso8601String(),
        'updated_at': task.updatedAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
        'is_deleted': task.isDeleted,
      };

      await _supabase.from('tasks').upsert(data);
      
      // Mark as synced locally
      await _db.markTaskSynced(task.id);
    }
  }

  Future<void> _pushTags() async {
    final tags = await _db.getUnsyncedTags();
    
    for (final tag in tags) {
      final data = {
        'id': tag.id,
        'user_id': _userId,
        'name': tag.name,
        'color': tag.color,
        'created_at': tag.createdAt.toIso8601String(),
        'updated_at': tag.updatedAt.toIso8601String(),
        'is_deleted': tag.isDeleted,
      };

      await _supabase.from('tags').upsert(data);
      await _db.markTagSynced(tag.id);
    }
  }

  Future<void> _pushTaskTags() async {
    final taskTags = await _db.getUnsyncedTaskTags();
    
    for (final tt in taskTags) {
      final data = {
        'task_id': tt.taskId,
        'tag_id': tt.tagId,
        'user_id': _userId,
        'created_at': tt.createdAt.toIso8601String(),
        'updated_at': tt.updatedAt.toIso8601String(),
        'is_deleted': tt.isDeleted,
      };

      await _supabase.from('task_tags').upsert(data);
      await _db.markTaskTagSynced(tt.taskId, tt.tagId);
    }
  }

  // ==================== PULL OPERATIONS ====================

  Future<void> _pullTasks() async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', _userId!);

    for (final row in response) {
      final remoteUpdatedAt = DateTime.parse(row['updated_at']);
      final localTask = await _db.getTaskById(row['id']);

      // If local doesn't exist or remote is newer, update local
      if (localTask == null || remoteUpdatedAt.isAfter(localTask.updatedAt)) {
        await _db.upsertTaskFromRemote(
          id: row['id'],
          title: row['title'],
          description: row['description'],
          category: row['category'] ?? 'Personal',
          priority: row['priority'] ?? 1,
          status: row['status'] ?? 0,
          dueDate: row['due_date'] != null ? DateTime.parse(row['due_date']) : null,
          scheduledStart: row['scheduled_start'] != null ? DateTime.parse(row['scheduled_start']) : null,
          scheduledEnd: row['scheduled_end'] != null ? DateTime.parse(row['scheduled_end']) : null,
          estimatedMinutes: row['estimated_minutes'],
          recurrenceType: row['recurrence_type'] ?? 0,
          recurrenceInterval: row['recurrence_interval'] ?? 1,
          parentTaskId: row['parent_task_id'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: remoteUpdatedAt,
          completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at']) : null,
          isDeleted: row['is_deleted'] ?? false,
        );
      }
    }
  }

  Future<void> _pullTags() async {
    final response = await _supabase
        .from('tags')
        .select()
        .eq('user_id', _userId!);

    for (final row in response) {
      final remoteUpdatedAt = DateTime.parse(row['updated_at']);
      final localTag = await _db.getTagById(row['id']);

      if (localTag == null || remoteUpdatedAt.isAfter(localTag.updatedAt)) {
        await _db.upsertTagFromRemote(
          id: row['id'],
          name: row['name'],
          color: row['color'],
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: remoteUpdatedAt,
          isDeleted: row['is_deleted'] ?? false,
        );
      }
    }
  }

  Future<void> _pullTaskTags() async {
    final response = await _supabase
        .from('task_tags')
        .select()
        .eq('user_id', _userId!);

    for (final row in response) {
      final isDeleted = row['is_deleted'] ?? false;
      
      if (isDeleted) {
        await _db.removeTagFromTask(row['task_id'], row['tag_id']);
      } else {
        await _db.addTagToTask(row['task_id'], row['tag_id']);
      }
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;

  SyncResult({required this.success, this.error});
}

/// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
});
