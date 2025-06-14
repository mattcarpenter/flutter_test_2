import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

@DataClassName('MealPlanEntry')
class MealPlans extends Table {
  // Primary key with a client-side default UUID.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  // Date for this meal plan (stored as YYYY-MM-DD string for simplicity)
  TextColumn get date => text()();
  
  // User and household association
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  
  // JSON array of meal plan items (recipes and notes) with ordering
  TextColumn get data => text().map(const MealPlanItemListConverter()).nullable()();
  
  // Timestamps
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}