import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks_table.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/subtasks_repository.dart';
import '../data/tags_repository.dart';
import '../data/tasks_repository.dart';
import 'tag_chip.dart';

/// Task detail sheet with subtasks management
class TaskDetailSheet extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  final _newSubtaskController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _newSubtaskController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(subtasksForTaskProvider(widget.task.id));
    final tagsAsync = ref.watch(taskTagsProvider(widget.task.id));
    final isCompleted = widget.task.status == TaskStatus.completed;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Task title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Completed',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Description
                if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Tags section
                Row(
                  children: [
                    Icon(Icons.label_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tags',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                tagsAsync.when(
                  data: (tags) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...tags.map((tag) => TagChip(
                              tag: tag,
                              onDelete: () => _removeTag(tag.id),
                            )),
                        if (!isCompleted)
                          ActionChip(
                            label: const Icon(Icons.add, size: 16),
                            onPressed: () => _showAddTagSheet(context),
                            backgroundColor: AppColors.surfaceVariant,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Subtasks section
                Row(
                  children: [
                    Icon(Icons.checklist, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Subtasks',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    subtasksAsync.when(
                      data: (subtasks) {
                        if (subtasks.isEmpty) return const SizedBox.shrink();
                        final completed = subtasks.where((s) => s.isCompleted).length;
                        return Text(
                          '$completed/${subtasks.length}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Add subtask field
                if (!isCompleted)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                        Expanded(
                          child: TextField(
                            controller: _newSubtaskController,
                            focusNode: _focusNode,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add a subtask...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        IconButton(
                          onPressed: _addSubtask,
                          icon: Icon(Icons.check, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Subtasks list
                subtasksAsync.when(
                  data: (subtasks) {
                    if (subtasks.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'No subtasks yet',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: subtasks.map((subtask) => _buildSubtaskItem(subtask)).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),

                // Complete task button
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _completeTask,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubtaskItem(Subtask subtask) {
    return Dismissible(
      key: ValueKey(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => _deleteSubtask(subtask.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _toggleSubtask(subtask),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: subtask.isCompleted ? AppColors.success : Colors.transparent,
                      border: Border.all(
                        color: subtask.isCompleted ? AppColors.success : AppColors.textSecondary,
                        width: 2,
                      ),
                    ),
                    child: subtask.isCompleted
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      subtask.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: subtask.isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addSubtask() async {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;

    final repository = ref.read(subtasksRepositoryProvider);
    final subtasks = await repository.getSubtasks(widget.task.id);
    
    await repository.addSubtask(
      parentTaskId: widget.task.id,
      title: title,
      sortOrder: subtasks.length,
    );

    _newSubtaskController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final repository = ref.read(subtasksRepositoryProvider);
    await repository.toggleSubtask(subtask.id, !subtask.isCompleted);
  }

  Future<void> _deleteSubtask(String id) async {
    final repository = ref.read(subtasksRepositoryProvider);
    await repository.deleteSubtask(id);
  }

  Future<void> _completeTask() async {
    final repository = ref.read(tasksRepositoryProvider);
    await repository.completeTask(widget.task.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _removeTag(String tagId) async {
    final repository = ref.read(tagsRepositoryProvider);
    await repository.removeTagFromTask(widget.task.id, tagId);
  }

  void _showAddTagSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddTagSheet(
        taskId: widget.task.id,
      ),
    );
  }
}

class _AddTagSheet extends ConsumerStatefulWidget {
  final String taskId;

  const _AddTagSheet({required this.taskId});

  @override
  ConsumerState<_AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends ConsumerState<_AddTagSheet> {
  final _tagController = TextEditingController();
  final List<Color> _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    AppColors.info,
    Colors.purple,
    Colors.teal,
    Colors.orange,
  ];
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors[0];
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTagsAsync = ref.watch(allTagsProvider);
    final taskTagsAsync = ref.watch(taskTagsProvider(widget.taskId));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Tags',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Existing tags
            allTagsAsync.when(
              data: (allTags) {
                return taskTagsAsync.when(
                  data: (taskTags) {
                    final taskTagIds = taskTags.map((t) => t.id).toSet();
                    
                    if (allTags.isEmpty) {
                      return Text(
                        'No tags created yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allTags.map((tag) {
                        final isSelected = taskTagIds.contains(tag.id);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (selected) => _toggleTag(tag.id, selected),
                          backgroundColor: AppColors.surfaceVariant,
                          selectedColor: Color(tag.color).withValues(alpha: 0.3),
                          checkmarkColor: Color(tag.color),
                          labelStyle: AppTypography.labelMedium.copyWith(
                            color: isSelected ? Color(tag.color) : AppColors.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? Color(tag.color) : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 24),

            // Create new tag
            Text(
              'Create New Tag',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tag name...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<Color>(
                    icon: const Icon(Icons.palette, color: Colors.white),
                    onSelected: (color) => setState(() => _selectedColor = color),
                    itemBuilder: (context) => _colors.map((color) {
                      return PopupMenuItem(
                         value: color,
                         child: Row(
                           children: [
                             Container(
                               width: 24,
                               height: 24,
                               decoration: BoxDecoration(
                                 color: color,
                                 shape: BoxShape.circle,
                               ),
                             ),
                             const SizedBox(width: 12),
                             Text(
                               'Color',
                               style: TextStyle(color: color),
                             ),
                           ],
                         ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _createTag,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTag(String tagId, bool selected) async {
    final repository = ref.read(tagsRepositoryProvider);
    if (selected) {
      await repository.addTagToTask(widget.taskId, tagId);
    } else {
      await repository.removeTagFromTask(widget.taskId, tagId);
    }
  }

  Future<void> _createTag() async {
    final name = _tagController.text.trim();
    if (name.isEmpty) return;
    
    final repository = ref.read(tagsRepositoryProvider);
    // ignore: deprecated_member_use
    await repository.createTag(name, _selectedColor.value);
    
    _tagController.clear();
  }
}
