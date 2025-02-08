// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20250202053631.migration.dart';
part '20250130101153.migration.dart';
part '20250208050933.migration.dart';
part '20250208053953.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20250202053631(),
  const Migration20250130101153(),
  const Migration20250208050933(),
  const Migration20250208053953()
};

/// A consumable database structure including the latest generated migration.
final schema =
    Schema(20250208053953, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('User', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('email', Column.varchar),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('household_Household_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Household',
        onDeleteCascade: false,
        onDeleteSetDefault: false)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
  SchemaTable('Household', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('id', Column.varchar, unique: true)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
  SchemaTable('SharedPermission', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('entity_type', Column.varchar),
    SchemaColumn('entity_id', Column.varchar),
    SchemaColumn('owner_id', Column.varchar),
    SchemaColumn('target_user_id', Column.varchar),
    SchemaColumn('access_level', Column.varchar)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true),
    SchemaIndex(columns: ['owner_id'], unique: false),
    SchemaIndex(columns: ['target_user_id'], unique: false)
  }),
  SchemaTable('RecipeFolder', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('parent_id', Column.varchar),
    SchemaColumn('user_id', Column.varchar),
    SchemaColumn('household_id', Column.varchar),
    SchemaColumn('deleted_at', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true),
    SchemaIndex(columns: ['user_id'], unique: false),
    SchemaIndex(columns: ['household_id'], unique: false),
    SchemaIndex(columns: ['deleted_at'], unique: false)
  }),
  SchemaTable('Recipe', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('title', Column.varchar),
    SchemaColumn('content', Column.varchar),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('folder_id', Column.varchar),
    SchemaColumn('user_id', Column.varchar),
    SchemaColumn('household_id', Column.varchar),
    SchemaColumn('deleted_at', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true),
    SchemaIndex(columns: ['folder_id'], unique: false),
    SchemaIndex(columns: ['user_id'], unique: false),
    SchemaIndex(columns: ['household_id'], unique: false),
    SchemaIndex(columns: ['deleted_at'], unique: false)
  })
});
