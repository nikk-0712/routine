import 'package:drift/drift.dart';

/// Task priority levels
enum TaskPriority { low, medium, high, urgent }

/// Task status
enum TaskStatus { pending, inProgress, completed, cancelled }

/// Task recurrence pattern
enum RecurrenceType { none, daily, weekly, monthly }

/// Tasks table definition
class Tasks extends Table {
  // Primary key - UUID string
  TextColumn get id => text()();
  
  // Task content
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  
  // Category (user-defined: Study, Personal, Health, etc.)
  TextColumn get category => text().withDefault(const Constant('Personal'))();
  
  // Priority
  IntColumn get priority => intEnum<TaskPriority>().withDefault(const Constant(1))();
  
  // Status
  IntColumn get status => intEnum<TaskStatus>().withDefault(const Constant(0))();
  
  // Scheduling
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get scheduledStart => dateTime().nullable()();
  DateTimeColumn get scheduledEnd => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  
  // Recurrence
  IntColumn get recurrenceType => intEnum<RecurrenceType>().withDefault(const Constant(0))();
  IntColumn get recurrenceInterval => integer().withDefault(const Constant(1))();
  
  // Parent task (for subtasks)
  TextColumn get parentTaskId => text().nullable()();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  
  // Soft delete
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
