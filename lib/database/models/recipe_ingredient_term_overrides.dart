import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeIngredientTermOverrideEntry')
class RecipeIngredientTermOverrides extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get recipeId      => text()();                  // FK → Recipes.id
  TextColumn get term          => text()();                  // Term to override
  TextColumn get pantryItemId  => text()();                  // FK → PantryItems.id
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  @override Set<Column> get primaryKey => {recipeId, term};
  IntColumn get deletedAt => integer().nullable()(); // Soft delete
  IntColumn get createdAt => integer().nullable()();
}
