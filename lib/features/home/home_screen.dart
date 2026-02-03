import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home dashboard screen - main entry point of the app
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020004),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF34195B),
      ),
      body: const Center(
        child: Text(
          'Home Dashboard',
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
