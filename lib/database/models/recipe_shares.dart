import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeShareEntry')
class RecipeShares extends Table {
  // Surrogate primary key.
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4()).unique()();
  // The recipe being shared.
  TextColumn get recipeId => text()();
  // Optional: if sharing to an entire household.
  TextColumn get householdId => text().nullable()();
  // Optional: if sharing directly with a user.
  TextColumn get userId => text().nullable()();
  // Sharing permission flag: 0 (false) or 1 (true)
  IntColumn get canEdit => integer().withDefault(const Constant(0))();
}
