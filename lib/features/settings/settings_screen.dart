import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen - app preferences and digital well-being controls
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020004),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF34195B),
      ),
      body: const Center(
        child: Text(
          'Settings & Controls',
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
