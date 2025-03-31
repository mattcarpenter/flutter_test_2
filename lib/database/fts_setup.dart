import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:recipe_app/database/schema.dart';

/// Enum to indicate which SQL extraction style to use.
/// In this simple example both types produce the same SQL.
enum ExtractType { columnOnly, columnInOperation }

Future<void> configureFts(PowerSyncDatabase db) async {
  final migrations = SqliteMigrations();
  migrations
    .add(createFtsMigrationForRecipes());
  await migrations.migrate(db);
}

/// Default generator for a column (like in PowerSync’s example).
String _createExtract(String jsonColumnName, String columnName) =>
    "json_extract($jsonColumnName, '\$.$columnName')";

/// Custom extraction for our recipe table.
/// For 'steps' and 'ingredients', we want to flatten the JSON array by concatenating
/// the specific fields we care about.
String generateRecipeJsonExtract(String jsonColumnName, String columnName) {
  if (columnName == 'steps') {
    // For each element in the JSON array stored at $.steps,
    // extract the 'text' and 'note' values and join them with a space.
    return "(SELECT group_concat(trim(coalesce(json_extract(value, '\$.text'), '') || ' ' || coalesce(json_extract(value, '\$.note'), '')), ' ') FROM json_each(json_extract($jsonColumnName, '\$.steps')))";
  } else if (columnName == 'ingredients') {
    // For each element in the JSON array at $.ingredients,
    // extract the 'name' and 'note' values.
    return "(SELECT group_concat(trim(coalesce(json_extract(value, '\$.name'), '') || ' ' || coalesce(json_extract(value, '\$.note'), '')), ' ') FROM json_each(json_extract($jsonColumnName, '\$.ingredients')))";
  } else {
    // Use the default extraction for other fields.
    return _createExtract(jsonColumnName, columnName);
  }
}

/// Given a list of columns, generate a comma-separated list of extraction expressions.
/// We ignore the ExtractType parameter here for simplicity.
String generateRecipeJsonExtracts(
    ExtractType type, String jsonColumnName, List<String> columns) {
  return columns
      .map((column) => generateRecipeJsonExtract(jsonColumnName, column))
      .join(', ');
}

/// Creates an FTS migration for the "recipes" table.
///
/// It will create a virtual table "fts_recipes" indexing:
/// title, description, steps, ingredients, source.
/// Data is extracted from the JSON stored in the "data" column.
SqliteMigration createFtsMigrationForRecipes() {
  String tableName = 'recipes';
  // Look up the internal table name (managed by PowerSync) from your Drift schema.
  String internalName =
      schema.tables.firstWhere((table) => table.name == tableName).internalName;
  // Columns we want to index.
  final List<String> columnsToIndex = [
    'title',
    'description',
    'steps',
    'ingredients',
    'source'
  ];
  // A comma-separated list of extraction expressions.
  String extractionExpressions =
  generateRecipeJsonExtracts(ExtractType.columnOnly, 'data', columnsToIndex);
  String stringColumns = columnsToIndex.join(', ');

  return SqliteMigration(3, (tx) async {
    // Create the FTS virtual table.
    await tx.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS fts_$tableName
      USING fts5(id UNINDEXED, $stringColumns, tokenize='porter unicode61');
    ''');

    // Populate the FTS table with existing records.
    await tx.execute('''
      INSERT INTO fts_$tableName(rowid, id, $stringColumns)
      SELECT rowid, id, $extractionExpressions
      FROM $internalName;
    ''');

    // Create trigger for INSERT operations.
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

    // Create trigger for UPDATE operations.
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_update_trigger_$tableName AFTER UPDATE
      ON $internalName
      BEGIN
        UPDATE fts_$tableName
        SET ${columnsToIndex.map((col) => "$col = ${generateRecipeJsonExtract('NEW.data', col)}").join(', ')}
        WHERE rowid = NEW.rowid;
      END;
    ''');

    // Create trigger for DELETE operations.
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_delete_trigger_$tableName AFTER DELETE
      ON $internalName
      BEGIN
        DELETE FROM fts_$tableName WHERE rowid = OLD.rowid;
      END;
    ''');
  });
}
