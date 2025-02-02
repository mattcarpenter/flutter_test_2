// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20250202053631_up = [
  InsertColumn('user_id', Column.varchar, onTable: 'RecipeFolder'),
  InsertColumn('deleted_at', Column.datetime, onTable: 'RecipeFolder'),
  CreateIndex(columns: ['user_id'], onTable: 'RecipeFolder', unique: false),
  CreateIndex(columns: ['deleted_at'], onTable: 'RecipeFolder', unique: false)
];

const List<MigrationCommand> _migration_20250202053631_down = [
  DropColumn('user_id', onTable: 'RecipeFolder'),
  DropColumn('deleted_at', onTable: 'RecipeFolder'),
  DropIndex('index_RecipeFolder_on_user_id'),
  DropIndex('index_RecipeFolder_on_deleted_at')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20250202053631',
  up: _migration_20250202053631_up,
  down: _migration_20250202053631_down,
)
class Migration20250202053631 extends Migration {
  const Migration20250202053631()
    : super(
        version: 20250202053631,
        up: _migration_20250202053631_up,
        down: _migration_20250202053631_down,
      );
}
