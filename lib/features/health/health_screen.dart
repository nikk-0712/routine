import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Health screen - wellness tracking (water, exercise, nutrition, sleep)
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020004),
      appBar: AppBar(
        title: const Text('Health'),
        backgroundColor: const Color(0xFF34195B),
      ),
      body: const Center(
        child: Text(
          'Health & Wellness',
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
