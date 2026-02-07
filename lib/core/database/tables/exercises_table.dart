import 'package:drift/drift.dart';

/// Table for storing exercise/workout logs
class Exercises extends Table {
  // Unique identifier
  TextColumn get id => text()();
  
  // Type of exercise (cardio, strength, yoga, walking, running, cycling, etc.)
  TextColumn get exerciseType => text()();
  
  // Duration in minutes
  IntColumn get durationMinutes => integer()();
  
  // Estimated calories burned (optional)
  IntColumn get caloriesBurned => integer().nullable()();
  
  // Intensity level (low, medium, high)
  TextColumn get intensity => text().withDefault(const Constant('medium'))();
  
  // Optional notes
  TextColumn get notes => text().nullable()();
  
  // When the exercise was performed
  DateTimeColumn get performedAt => dateTime()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
