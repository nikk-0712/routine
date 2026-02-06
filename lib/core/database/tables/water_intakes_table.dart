import 'package:drift/drift.dart';

/// Water intake log table
class WaterIntakes extends Table {
  // Primary key - auto-increment
  IntColumn get id => integer().autoIncrement()();
  
  // Amount in ml
  IntColumn get amountMl => integer()();
  
  // Timestamp when logged
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Optional note (e.g., "After workout")
  TextColumn get note => text().nullable()();
}
