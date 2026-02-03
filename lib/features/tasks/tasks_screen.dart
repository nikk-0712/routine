import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tasks screen - task management and scheduling
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020004),
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: const Color(0xFF34195B),
      ),
      body: const Center(
        child: Text(
          'Task Management',
          style: TextStyle(
            color: Color(0xFF9F3BDB),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
