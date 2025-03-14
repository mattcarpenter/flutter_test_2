import 'package:powersync/powersync.dart';

// Define the table name as a constant.
const recipeFoldersTable = 'recipe_folders';
const recipesTable = 'recipes';
const householdsTable = 'households';
const householdMembersTable = 'household_members';
const recipeSharesTable = 'recipe_shares';
const recipeFolderSharesTable = 'recipe_folder_shares';
const recipeFolderAssignmentsTable = 'recipe_folder_assignments';

// Create a schema that includes your RecipeFolder table.
Schema schema = const Schema(([
  Table(recipeFoldersTable, [
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
  Table(recipesTable, [
    Column.text('title'),
    Column.text('description'),
    Column.integer('rating'),
    Column.text('language'),
    Column.integer('servings'),
    Column.integer('prep_time'),
    Column.integer('cook_time'),
    Column.integer('total_time'),
    Column.text('source'),
    Column.text('nutrition'),
    Column.text('general_notes'),
    Column.text('user_id'),
    // Remove folder_id from recipes (or ignore it) – we'll use the mapping table.
    // Column.text('folder_id'),
    Column.text('household_id'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.text('ingredients'),
    Column.text('steps'),
    Column.text('folder_ids'),
    Column.text('images'),
  ]/*, indexes: [...] */),
  Table(householdsTable, [
    // Household name.
    Column.text('name'),
    // The owner/creator user id.
    Column.text('user_id'),
    // You can add additional columns (e.g. created_at) if desired.
  ]),
  Table(householdMembersTable, [
    // The household id.
    Column.text('household_id'),
    // The user id.
    Column.text('user_id'),
    // Active flag: 1 (active) or 0 (inactive)
    Column.integer('is_active'),
  ]),
  Table(recipeSharesTable, [
    Column.text('recipe_id'),
    Column.text('household_id'),
    Column.text('user_id'),
    Column.integer('can_edit'),
  ]),
  Table(recipeFolderSharesTable, [
    Column.text('folder_id'),
    Column.text('sharer_id'),
    Column.text('target_user_id'),
    Column.text('target_household_id'),
    Column.integer('can_edit'),
    Column.integer('created_at'),
  ]),
]));
