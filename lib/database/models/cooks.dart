import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

enum CookStatus {
  inProgress,
  finished,
  discarded,
}

@DataClassName('CookEntry')
class Cooks extends Table {
  // Primary key with client-side UUID
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  @override
  Set<Column> get primaryKey => {id};

  // Foreign keys / associations
  TextColumn get recipeId => text()();       // References Recipes
  TextColumn get userId => text().nullable()();         // The user who initiated the cook
  TextColumn get householdId => text().nullable()(); // Optional household-sharing context

  // Progress tracking
  IntColumn get currentStepIndex => integer().withDefault(const Constant(0))();

  // Lifecycle
  TextColumn get status => text().map(const CookStatusConverter()).withDefault(const Constant('in_progress'))();
  // Possible values: 'in_progress', 'finished', 'discarded'

  // Timestamps
  IntColumn get startedAt => integer().nullable()();     // Unix epoch (ms)
  IntColumn get finishedAt => integer().nullable()();    // Null until marked finished
  IntColumn get updatedAt => integer().nullable()();

  IntColumn get rating => integer().nullable()();

  TextColumn get recipeName => text()();

  // Notes or other metadata
  TextColumn get notes => text().nullable()();

// If you ever add timers, hands-free, etc., you can add more metadata fields here
}
