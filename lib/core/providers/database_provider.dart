import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// Provides the singleton database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  // Close database when provider is disposed
  ref.onDispose(() => database.close());
  
  return database;
});
