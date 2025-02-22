import 'package:powersync/powersync.dart';

// Define the table name as a constant.
const recipeFoldersTable = 'recipe_folders';

// Create a schema that includes your RecipeFolder table.
Schema schema = Schema(([
  const Table(recipeFoldersTable, [
    // Define a text column for the ID.
    //Column.text('folder_id'),
    // Define a text column for the folder name.
    Column.text('name'),
    // Define optional text columns for user, parent, and household associations.
    Column.text('user_id'),
    Column.text('parent_id'),
    Column.text('household_id'),
    // Define a column for the deletion timestamp. If Powersync doesn’t have a built-in
    // DateTime column, consider storing the timestamp as ISO8601 text.
    Column.integer('deleted_at'),
  ]/*,
  // You can add indexes if you want to enforce uniqueness or speed up lookups.
  indexes: [
    // This index on 'id' can help with lookups. (Uniqueness should be enforced in your app.)
    Index('id_index', [IndexedColumn('folder_id')])
  ]*/),
]));
