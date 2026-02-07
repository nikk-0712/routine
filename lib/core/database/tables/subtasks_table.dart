import 'package:drift/drift.dart';

/// Table for storing subtasks (nested items within a parent task)
class Subtasks extends Table {
  // Unique identifier
  TextColumn get id => text()();
  
  // Parent task ID (foreign key to Tasks)
  TextColumn get parentTaskId => text()();
  
  // Subtask title
  TextColumn get title => text().withLength(min: 1, max: 200)();
  
  // Whether the subtask is completed
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  
  // Order/position in the list
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
