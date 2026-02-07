import 'package:drift/drift.dart';

/// Table for storing sleep logs
class SleepLogs extends Table {
  // Unique identifier
  TextColumn get id => text()();
  
  // When user went to bed
  DateTimeColumn get bedtime => dateTime()();
  
  // When user woke up
  DateTimeColumn get wakeTime => dateTime()();
  
  // Duration in minutes (calculated from bed to wake)
  IntColumn get durationMinutes => integer()();
  
  // Sleep quality rating (1-5 stars)
  IntColumn get quality => integer().withDefault(const Constant(3))();
  
  // Optional notes (e.g., "Had dreams", "Woke up twice")
  TextColumn get notes => text().nullable()();
  
  // The date this sleep log is for (the night of)
  DateTimeColumn get sleepDate => dateTime()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
