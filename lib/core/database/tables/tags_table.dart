import 'package:drift/drift.dart';

/// Table for storing task tags/labels
class Tags extends Table {
  // Unique identifier
  TextColumn get id => text()();
  
  // Tag name (e.g., "Work", "Urgent")
  TextColumn get name => text().withLength(min: 1, max: 20)();
  
  // Tag color (stored as int ARGB)
  IntColumn get color => integer()();
  
  // Timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Join table for many-to-many relationship between Tasks and Tags
class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId => text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {taskId, tagId};
}
