import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('IngredientTermQueueEntry')
class IngredientTermQueues extends Table {
  // Unique identifier
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4()).unique()();

  @override
  Set<Column> get primaryKey => {id};

  // The recipe ID this queue entry is for
  TextColumn get recipeId => text()();

  // The ingredient ID within the recipe
  TextColumn get ingredientId => text()();

  // Request timestamp used for conflict resolution
  IntColumn get requestTimestamp => integer()();

  // Status: pending, processing, completed, or failed
  TextColumn get status => text().withDefault(Constant('pending'))();

  // Retry count for failed requests
  IntColumn get retryCount => integer().withDefault(Constant(0))();

  // Last time an API request was attempted (stored as epoch milliseconds)
  IntColumn get lastTryTimestamp => integer().nullable()();

  // The serialized ingredient data at the time of queueing (for API request)
  TextColumn get ingredientData => text()();

  // The serialized response data from the API (when completed)
  TextColumn get responseData => text().nullable()();
}