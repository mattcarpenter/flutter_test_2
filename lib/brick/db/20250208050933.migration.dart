// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20250208050933_up = [
  InsertTable('User'),
  InsertTable('Household'),
  InsertTable('SharedPermission'),
  InsertTable('Recipe'),
  InsertColumn('name', Column.varchar, onTable: 'User'),
  InsertColumn('email', Column.varchar, onTable: 'User'),
  InsertColumn('id', Column.varchar, onTable: 'User', unique: true),
  InsertColumn('name', Column.varchar, onTable: 'Household'),
  InsertColumn('id', Column.varchar, onTable: 'Household', unique: true),
  InsertColumn('id', Column.varchar, onTable: 'SharedPermission', unique: true),
  InsertColumn('entity_type', Column.varchar, onTable: 'SharedPermission'),
  InsertColumn('entity_id', Column.varchar, onTable: 'SharedPermission'),
  InsertColumn('owner_id', Column.varchar, onTable: 'SharedPermission'),
  InsertColumn('target_user_id', Column.varchar, onTable: 'SharedPermission'),
  InsertColumn('access_level', Column.varchar, onTable: 'SharedPermission'),
  InsertColumn('household_id', Column.varchar, onTable: 'RecipeFolder'),
  InsertColumn('title', Column.varchar, onTable: 'Recipe'),
  InsertColumn('content', Column.varchar, onTable: 'Recipe'),
  InsertColumn('id', Column.varchar, onTable: 'Recipe', unique: true),
  InsertColumn('folder_id', Column.varchar, onTable: 'Recipe'),
  InsertColumn('user_id', Column.varchar, onTable: 'Recipe'),
  InsertColumn('household_id', Column.varchar, onTable: 'Recipe'),
  InsertColumn('deleted_at', Column.datetime, onTable: 'Recipe'),
  CreateIndex(columns: ['id'], onTable: 'User', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Household', unique: true),
  CreateIndex(columns: ['id'], onTable: 'SharedPermission', unique: true),
  CreateIndex(columns: ['owner_id'], onTable: 'SharedPermission', unique: false),
  CreateIndex(columns: ['target_user_id'], onTable: 'SharedPermission', unique: false),
  CreateIndex(columns: ['household_id'], onTable: 'RecipeFolder', unique: false),
  CreateIndex(columns: ['id'], onTable: 'Recipe', unique: true),
  CreateIndex(columns: ['folder_id'], onTable: 'Recipe', unique: false),
  CreateIndex(columns: ['user_id'], onTable: 'Recipe', unique: false),
  CreateIndex(columns: ['household_id'], onTable: 'Recipe', unique: false),
  CreateIndex(columns: ['deleted_at'], onTable: 'Recipe', unique: false)
];

const List<MigrationCommand> _migration_20250208050933_down = [
  DropTable('User'),
  DropTable('Household'),
  DropTable('SharedPermission'),
  DropTable('Recipe'),
  DropColumn('name', onTable: 'User'),
  DropColumn('email', onTable: 'User'),
  DropColumn('id', onTable: 'User'),
  DropColumn('name', onTable: 'Household'),
  DropColumn('id', onTable: 'Household'),
  DropColumn('id', onTable: 'SharedPermission'),
  DropColumn('entity_type', onTable: 'SharedPermission'),
  DropColumn('entity_id', onTable: 'SharedPermission'),
  DropColumn('owner_id', onTable: 'SharedPermission'),
  DropColumn('target_user_id', onTable: 'SharedPermission'),
  DropColumn('access_level', onTable: 'SharedPermission'),
  DropColumn('household_id', onTable: 'RecipeFolder'),
  DropColumn('title', onTable: 'Recipe'),
  DropColumn('content', onTable: 'Recipe'),
  DropColumn('id', onTable: 'Recipe'),
  DropColumn('folder_id', onTable: 'Recipe'),
  DropColumn('user_id', onTable: 'Recipe'),
  DropColumn('household_id', onTable: 'Recipe'),
  DropColumn('deleted_at', onTable: 'Recipe'),
  DropIndex('index_User_on_id'),
  DropIndex('index_Household_on_id'),
  DropIndex('index_SharedPermission_on_id'),
  DropIndex('index_SharedPermission_on_owner_id'),
  DropIndex('index_SharedPermission_on_target_user_id'),
  DropIndex('index_RecipeFolder_on_household_id'),
  DropIndex('index_Recipe_on_id'),
  DropIndex('index_Recipe_on_folder_id'),
  DropIndex('index_Recipe_on_user_id'),
  DropIndex('index_Recipe_on_household_id'),
  DropIndex('index_Recipe_on_deleted_at')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20250208050933',
  up: _migration_20250208050933_up,
  down: _migration_20250208050933_down,
)
class Migration20250208050933 extends Migration {
  const Migration20250208050933()
    : super(
        version: 20250208050933,
        up: _migration_20250208050933_up,
        down: _migration_20250208050933_down,
      );
}
