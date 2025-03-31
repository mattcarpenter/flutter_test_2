import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:recipe_app/database/schema.dart';

import 'fts_helpers.dart';

/// Enum to indicate which SQL extraction style to use.
/// In this simple example both types produce the same SQL.
enum ExtractType { columnOnly, columnInOperation }

/// Call this during initialization to configure FTS.
Future<void> configureFts(PowerSyncDatabase db) async {
  final migrations = SqliteMigrations();
  migrations.add(createFtsMigrationForRecipes());
  await migrations.migrate(db);
}

/// Wraps a raw json_extract call in a call to our UDF "preprocess".
String _createExtract(String jsonColumnName, String columnName) =>
    "preprocessFtsText(json_extract($jsonColumnName, '\$.$columnName'))";

/// Custom extraction for our recipe table.
/// For 'steps' and 'ingredients', flatten the JSON array by concatenating
/// specific fields, each wrapped in a call to preprocess().
String generateRecipeJsonExtract(String jsonColumnName, String columnName) {
  if (columnName == 'steps') {
    return "(SELECT group_concat(trim(coalesce(preprocessFtsText(json_extract(value, '\$.text')), '') || ' ' || coalesce(preprocessFtsText(json_extract(value, '\$.note')), '')), ' ') FROM json_each(json_extract($jsonColumnName, '\$.steps')))";
  } else if (columnName == 'ingredients') {
    return "(SELECT group_concat(trim(coalesce(preprocessFtsText(json_extract(value, '\$.name')), '') || ' ' || coalesce(preprocessFtsText(json_extract(value, '\$.note')), '')), ' ') FROM json_each(json_extract($jsonColumnName, '\$.ingredients')))";
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
