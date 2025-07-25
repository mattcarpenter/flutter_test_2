import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:recipe_app/database/schema.dart';

/// Enum to indicate which SQL extraction style to use.
/// In this simple example both types produce the same SQL.
enum ExtractType { columnOnly, columnInOperation }

/// Call this during initialization to configure FTS.
Future<void> configureFts(PowerSyncDatabase db) async {
  final migrations = SqliteMigrations();
  migrations.add(createFtsMigrationForRecipes());
  migrations.add(createMigrationForRecipeIngredientTerms());
  migrations.add(createMigrationForPantryItemTerms());
  migrations.add(createMigrationForIngredientTermOverrides());
  migrations.add(createMigrationForTermsTriggers());
  migrations.add(createMigrationForIngredientTermOverrideTriggers());
  await migrations.migrate(db);
}

/// Wraps a raw json_extract call in a call to our UDF "preprocess".
String _createExtract(String jsonColumnName, String columnName) =>
    "json_extract($jsonColumnName, '\$.$columnName')";

/// Custom extraction for our recipe table.
/// For 'steps' and 'ingredients', flatten the JSON array by concatenating
/// specific fields, each wrapped in a call to preprocess().
String generateRecipeJsonExtract(String jsonColumnName, String columnName) {
  if (columnName == 'steps') {
    return "(SELECT group_concat(trim(coalesce(json_extract(value, '\$.text'), '') || ' ' || coalesce(json_extract(value, '\$.note'), '')), ' ') FROM json_each(json_extract($jsonColumnName, '\$.steps')))";
  } else if (columnName == 'ingredients') {
    return "(SELECT group_concat(trim(coalesce(json_extract(value, '\$.name'), '') || ' ' || coalesce(json_extract(value, '\$.note'), '')), ' ') FROM json_each(json_extract($jsonColumnName, '\$.ingredients')))";
  } else {
    return _createExtract(jsonColumnName, columnName);
  }
}

/// Given a list of columns, generate a comma-separated list of extraction expressions.
String generateRecipeJsonExtracts(
    ExtractType type, String jsonColumnName, List<String> columns) {
  return columns
      .map((column) => generateRecipeJsonExtract(jsonColumnName, column))
      .join(', ');
}

SqliteMigration createMigrationForRecipeIngredientTerms() {
  return SqliteMigration(4, (tx) async {
    await tx.execute('''
      CREATE TABLE IF NOT EXISTS recipe_ingredient_terms (
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        term TEXT NOT NULL,
        sort INTEGER NOT NULL,
        created_at INTEGER,
        linked_recipe_id TEXT,
        PRIMARY KEY (recipe_id, ingredient_id, term, sort)
      );
    ''');

    await tx.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_terms_term ON recipe_ingredient_terms(term);');
    await tx.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_terms_recipe ON recipe_ingredient_terms(recipe_id);');
    await tx.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_terms_linked_recipe ON recipe_ingredient_terms(linked_recipe_id);');
    await tx.execute('CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_terms_recipe_linked ON recipe_ingredient_terms(recipe_id, linked_recipe_id);');
  });
}

SqliteMigration createMigrationForPantryItemTerms() {
  return SqliteMigration(5, (tx) async {
    await tx.execute('''
      CREATE TABLE IF NOT EXISTS pantry_item_terms (
        pantry_item_id TEXT NOT NULL,
        term TEXT NOT NULL,
        sort INTEGER NOT NULL,
        source TEXT DEFAULT 'user',
        created_at INTEGER,
        PRIMARY KEY (pantry_item_id, term, sort)
      );
    ''');

    await tx.execute('CREATE INDEX IF NOT EXISTS idx_pantry_item_terms_term ON pantry_item_terms(term);');
  });
}

SqliteMigration createMigrationForIngredientTermOverrides() {
  return SqliteMigration(6, (tx) async {
    await tx.execute('''
      CREATE TABLE ingredient_term_overrides_flattened (
        id TEXT PRIMARY KEY,
        input_term TEXT NOT NULL,
        mapped_term TEXT NOT NULL,
        user_id TEXT,
        household_id TEXT,
        created_at INTEGER,
        deleted_at INTEGER
      );
    ''');
  });
}

/// Creates an FTS migration for the "recipes" table.
/// It creates a virtual table "fts_recipes" indexing title, description,
/// steps, ingredients, and source. Data is extracted from the JSON stored in the "data" column.
SqliteMigration createFtsMigrationForRecipes() {
  String tableName = 'recipes';
  String internalName =
      schema.tables.firstWhere((table) => table.name == tableName).internalName;
  final List<String> columnsToIndex = [
    'title',
    'description',
    'steps',
    'ingredients',
    'source'
  ];
  String extractionExpressions =
  generateRecipeJsonExtracts(ExtractType.columnOnly, 'data', columnsToIndex);
  String stringColumns = columnsToIndex.join(', ');

  return SqliteMigration(3, (tx) async {
    await tx.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS fts_$tableName
      USING fts5(id UNINDEXED, $stringColumns, tokenize='porter unicode61');
    ''');

    await tx.execute('''
      INSERT INTO fts_$tableName(rowid, id, $stringColumns)
      SELECT rowid, id, $extractionExpressions
      FROM $internalName;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_insert_trigger_$tableName AFTER INSERT
      ON $internalName
      BEGIN
        INSERT INTO fts_$tableName(rowid, id, $stringColumns)
        VALUES (
          NEW.rowid,
          NEW.id,
          ${generateRecipeJsonExtracts(ExtractType.columnOnly, 'NEW.data', columnsToIndex)}
        );
      END;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_update_trigger_$tableName AFTER UPDATE
      ON $internalName
      BEGIN
        UPDATE fts_$tableName
        SET ${columnsToIndex.map((col) => "$col = ${generateRecipeJsonExtract('NEW.data', col)}").join(', ')}
        WHERE rowid = NEW.rowid;
      END;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_delete_trigger_$tableName AFTER DELETE
      ON $internalName
      BEGIN
        DELETE FROM fts_$tableName WHERE rowid = OLD.rowid;
      END;
    ''');
  });
}

SqliteMigration createMigrationForTermsTriggers() {
  final recipeTableName = 'recipes';
  final pantryTableName = 'pantry_items';

  final recipeInternalName = schema.tables.firstWhere((t) => t.name == recipeTableName).internalName;
  final pantryInternalName = schema.tables.firstWhere((t) => t.name == pantryTableName).internalName;

  return SqliteMigration(7, (tx) async {
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS insert_recipe_ingredient_terms
      AFTER INSERT ON $recipeInternalName
      BEGIN
        DELETE FROM recipe_ingredient_terms WHERE recipe_id = NEW.id;
        INSERT INTO recipe_ingredient_terms (recipe_id, ingredient_id, term, sort, linked_recipe_id)
        SELECT
          NEW.id,
          json_extract(ingredient.value, '\$.id'),
          json_extract(term.value, '\$.value'),
          json_extract(term.value, '\$.sort'),
          json_extract(ingredient.value, '\$.recipeId')
        FROM json_each(json_extract(NEW.data, '\$.ingredients')) AS ingredient,
             json_each(json_extract(ingredient.value, '\$.terms')) AS term;
      END;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS update_recipe_ingredient_terms
      AFTER UPDATE ON $recipeInternalName
      BEGIN
        DELETE FROM recipe_ingredient_terms WHERE recipe_id = NEW.id;
        INSERT INTO recipe_ingredient_terms (recipe_id, ingredient_id, term, sort, linked_recipe_id)
        SELECT
          NEW.id,
          json_extract(ingredient.value, '\$.id'),
          json_extract(term.value, '\$.value'),
          json_extract(term.value, '\$.sort'),
          json_extract(ingredient.value, '\$.recipeId')
        FROM json_each(json_extract(NEW.data, '\$.ingredients')) AS ingredient,
             json_each(json_extract(ingredient.value, '\$.terms')) AS term;
      END;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS insert_pantry_item_terms
      AFTER INSERT ON $pantryInternalName
      BEGIN
        DELETE FROM pantry_item_terms WHERE pantry_item_id = NEW.id;
        INSERT INTO pantry_item_terms (pantry_item_id, term, sort)
        SELECT
          NEW.id,
          json_extract(term.value, '\$.value'),
          json_extract(term.value, '\$.sort')
        FROM json_each(json_extract(NEW.data, '\$.terms')) AS term;
      END;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS update_pantry_item_terms
      AFTER UPDATE ON $pantryInternalName
      BEGIN
        DELETE FROM pantry_item_terms WHERE pantry_item_id = NEW.id;
        INSERT INTO pantry_item_terms (pantry_item_id, term, sort)
        SELECT
          NEW.id,
          json_extract(term.value, '\$.value'),
          json_extract(term.value, '\$.sort')
        FROM json_each(json_extract(NEW.data, '\$.terms')) AS term;
      END;
    ''');
  });
}

SqliteMigration createMigrationForIngredientTermOverrideTriggers() {
  const overridesTableName = 'ingredient_term_overrides';
  final overridesInternalName = schema.tables.firstWhere((t) => t.name == overridesTableName).internalName;

  return SqliteMigration(8, (tx) async {
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS insert_ingredient_term_overrides
      AFTER INSERT ON $overridesInternalName
      BEGIN
        DELETE FROM ingredient_term_overrides_flattened
        WHERE id = NEW.id;

        INSERT INTO ingredient_term_overrides_flattened (id, input_term, mapped_term, user_id, household_id, created_at)
        VALUES (
          NEW.id,
          json_extract(NEW.data, '\$.input_term'),
          json_extract(NEW.data, '\$.mapped_term'),
          json_extract(NEW.data, '\$.user_id'),
          json_extract(NEW.data, '\$.household_id'),
          strftime('%s','now') * 1000
        );
      END;
    ''');

    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS update_ingredient_term_overrides
      AFTER UPDATE ON $overridesInternalName
      BEGIN
        -- Always delete the existing entry
        DELETE FROM ingredient_term_overrides_flattened
        WHERE id = NEW.id;

        -- Only insert if not deleted (deleted_at is null)
        INSERT INTO ingredient_term_overrides_flattened (id, input_term, mapped_term, user_id, household_id, created_at)
        SELECT
          NEW.id,
          json_extract(NEW.data, '\$.input_term'),
          json_extract(NEW.data, '\$.mapped_term'),
          json_extract(NEW.data, '\$.user_id'),
          json_extract(NEW.data, '\$.household_id'),
          strftime('%s','now') * 1000
        WHERE json_extract(NEW.data, '\$.deleted_at') IS NULL;
      END;
    ''');
  });
}






