// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20250130101153.migration.dart';
part '20250202053631.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20250130101153(),
  const Migration20250202053631()
};

/// A consumable database structure including the latest generated migration.
final schema =
    Schema(20250202053631, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('RecipeFolder', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('parent_id', Column.varchar),
    SchemaColumn('user_id', Column.varchar),
    SchemaColumn('deleted_at', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true),
    SchemaIndex(columns: ['user_id'], unique: false),
    SchemaIndex(columns: ['deleted_at'], unique: false)
  })
});
