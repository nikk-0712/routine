import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Insights screen - AI-powered analytics and pattern recognition
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020004),
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: const Color(0xFF34195B),
      ),
      body: const Center(
        child: Text(
          'AI Insights',
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
