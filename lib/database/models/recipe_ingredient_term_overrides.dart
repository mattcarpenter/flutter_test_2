import 'package:drift/drift.dart';

@DataClassName('RecipeIngredientTermOverrideEntry')
class RecipeIngredientTermOverrides extends Table {
  TextColumn get recipeId      => text()();                  // FK → Recipes.id
  TextColumn get term          => text()();                  // Term to override
  TextColumn get pantryItemId  => text()();                  // FK → PantryItems.id
  TextColumn get userId => text()();
  TextColumn get householdId => text().nullable()();
  @override Set<Column> get primaryKey => {recipeId, term};
}
