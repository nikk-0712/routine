import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';

/// Repository for managing task tags
class TagsRepository {
  final AppDatabase _db;

  TagsRepository(this._db);

  /// Get all tags
  Future<List<Tag>> getAllTags() => _db.getAllTags();

  /// Watch all tags
  Stream<List<Tag>> watchAllTags() => _db.watchAllTags();

  /// Create a new tag
  Future<String> createTag(String name, int colorValue) async {
    final id = const Uuid().v4();
    await _db.createTag(
      TagsCompanion(
        id: Value(id),
        name: Value(name),
        color: Value(colorValue),
        createdAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  /// Delete a tag
  Future<void> deleteTag(String id) async {
    await _db.deleteTag(id);
  }

  /// Add tag to task
  Future<void> addTagToTask(String taskId, String tagId) async {
    // Check if already exists to prevent duplicates (though PK handles this)
    try {
      await _db.addTagToTask(taskId, tagId);
    } catch (_) {
      // Ignore unique constraint violations
    }
  }

  /// Remove tag from task
  Future<void> removeTagFromTask(String taskId, String tagId) async {
    await _db.removeTagFromTask(taskId, tagId);
  }

  /// Get tags for a task
  Future<List<Tag>> getTagsForTask(String taskId) => _db.getTagsForTask(taskId);

  /// Watch tags for a task
  Stream<List<Tag>> watchTagsForTask(String taskId) => _db.watchTagsForTask(taskId);
}

/// Tags repository provider
final tagsRepositoryProvider = Provider<TagsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TagsRepository(db);
});

/// Tags for specific task provider
final taskTagsProvider = StreamProvider.family<List<Tag>, String>((ref, taskId) {
  final repository = ref.watch(tagsRepositoryProvider);
  return repository.watchTagsForTask(taskId);
});

/// All tags provider
final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  final repository = ref.watch(tagsRepositoryProvider);
  return repository.watchAllTags();
});
