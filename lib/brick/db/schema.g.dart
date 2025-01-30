// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20250130101153.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20250130101153(),};

/// A consumable database structure including the latest generated migration.
final schema = Schema(20250130101153, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('RecipeFolder', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('parent_id', Column.varchar)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  })
});
