// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20250221231816.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20250221231816(),};

/// A consumable database structure including the latest generated migration.
final schema = Schema(20250221231816, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('RecipeStep', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('recipe_Recipe_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Recipe',
        onDeleteCascade: false,
        onDeleteSetDefault: false),
    SchemaColumn('position', Column.integer),
    SchemaColumn('entry_type', Column.varchar),
    SchemaColumn('text', Column.varchar),
    SchemaColumn('timer_duration', Column.integer),
    SchemaColumn('id', Column.varchar, unique: true)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
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
  SchemaTable('RecipeIngredient', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('recipe_id', Column.varchar),
    SchemaColumn('position', Column.integer),
    SchemaColumn('entry_type', Column.varchar),
    SchemaColumn('text', Column.varchar),
    SchemaColumn('note', Column.varchar),
    SchemaColumn('unit1', Column.varchar),
    SchemaColumn('quantity1', Column.Double),
    SchemaColumn('unit2', Column.varchar),
    SchemaColumn('quantity2', Column.Double),
    SchemaColumn('total_unit', Column.varchar),
    SchemaColumn('total_quantity', Column.Double),
    SchemaColumn('id', Column.varchar, unique: true)
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
  SchemaTable('RecipeStepImageMapping', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('step_RecipeStep_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'RecipeStep',
        onDeleteCascade: false,
        onDeleteSetDefault: false),
    SchemaColumn('image_RecipeImage_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'RecipeImage',
        onDeleteCascade: false,
        onDeleteSetDefault: false),
    SchemaColumn('id', Column.varchar, unique: true)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
  SchemaTable('RecipeImage', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('recipe_Recipe_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Recipe',
        onDeleteCascade: false,
        onDeleteSetDefault: false),
    SchemaColumn('image_url', Column.varchar),
    SchemaColumn('is_cover', Column.boolean),
    SchemaColumn('id', Column.varchar, unique: true)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
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
    SchemaColumn('description', Column.varchar),
    SchemaColumn('rating', Column.integer),
    SchemaColumn('language', Column.varchar),
    SchemaColumn('servings', Column.integer),
    SchemaColumn('prep_time', Column.integer),
    SchemaColumn('cook_time', Column.integer),
    SchemaColumn('total_time', Column.integer),
    SchemaColumn('source', Column.varchar),
    SchemaColumn('nutrition', Column.varchar),
    SchemaColumn('general_notes', Column.varchar),
    SchemaColumn('user_id', Column.varchar),
    SchemaColumn('folder_RecipeFolder_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'RecipeFolder',
        onDeleteCascade: false,
        onDeleteSetDefault: false),
    SchemaColumn('household_Household_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Household',
        onDeleteCascade: false,
        onDeleteSetDefault: false),
    SchemaColumn('created_at', Column.datetime),
    SchemaColumn('updated_at', Column.datetime),
    SchemaColumn('id', Column.varchar, unique: true)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['user_id'], unique: false),
    SchemaIndex(columns: ['id'], unique: true)
  })
});
