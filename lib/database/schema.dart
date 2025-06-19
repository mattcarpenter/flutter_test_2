import 'package:powersync/powersync.dart';

// Define the table name as a constant.
const recipeFoldersTable = 'recipe_folders';
const recipesTable = 'recipes';
const householdsTable = 'households';
const householdMembersTable = 'household_members';
const recipeSharesTable = 'recipe_shares';
const recipeFolderSharesTable = 'recipe_folder_shares';
const recipeFolderAssignmentsTable = 'recipe_folder_assignments';
const uploadQueuesTable = 'upload_queues';
const ingredientTermQueuesTable = 'ingredient_term_queues';
const pantryItemTermQueuesTable = 'pantry_item_term_queues';
const shoppingListItemTermQueuesTable = 'shopping_list_item_term_queues';
const cooksTable = 'cooks';
const pantryItemsTable = 'pantry_items';
const ingredientTermOverridesTable = 'ingredient_term_overrides';
const shoppingListsTable = 'shopping_lists';
const convertersTable = 'converters';
const shoppingListItemsTable = 'shopping_list_items';
const mealPlansTable = 'meal_plans';

Schema schema = const Schema(([
  Table.localOnly(uploadQueuesTable, [
    Column.text('file_name'),
    Column.text('status'),
    Column.integer('retry_count'),
    Column.integer('last_try_timestamp'),
    Column.text('recipe_id'),
  ]),
  Table.localOnly(ingredientTermQueuesTable, [
    Column.text('recipe_id'),
    Column.text('ingredient_id'),
    Column.integer('request_timestamp'),
    Column.text('status'),
    Column.integer('retry_count'),
    Column.integer('last_try_timestamp'),
    Column.text('ingredient_data'),
    Column.text('response_data'),
  ]),
  Table.localOnly(pantryItemTermQueuesTable, [
    Column.text('pantry_item_id'),
    Column.integer('request_timestamp'),
    Column.text('status'),
    Column.integer('retry_count'),
    Column.integer('last_try_timestamp'),
    Column.text('pantry_item_data'),
    Column.text('response_data'),
  ]),
  Table.localOnly(shoppingListItemTermQueuesTable, [
    Column.text('shopping_list_item_id'),
    Column.text('name'),
    Column.text('user_id'),
    Column.real('amount'),
    Column.text('unit'),
    Column.text('status'),
    Column.integer('retry_count'),
    Column.text('error'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
  ]),
  Table(recipeFoldersTable, [
    Column.text('name'),
    Column.text('user_id'),
    Column.text('parent_id'),
    Column.text('household_id'),
    Column.integer('deleted_at'),
  ]),
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
    Column.text('household_id'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.integer('deleted_at'),
    Column.text('ingredients'),
    Column.text('steps'),
    Column.text('folder_ids'),
    Column.text('images'),
  ]),
  Table(householdsTable, [
    Column.text('name'),
    Column.text('user_id'),
  ]),
  Table(householdMembersTable, [
    Column.text('household_id'),
    Column.text('user_id'),
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
  Table(cooksTable, [
    Column.text('recipe_id'),
    Column.text('user_id'),
    Column.text('household_id'),
    Column.text('recipe_name'),
    Column.integer('current_step_index'),
    Column.text('status'),
    Column.integer('started_at'),
    Column.integer('finished_at'),
    Column.integer('updated_at'),
    Column.integer('rating'),
    Column.text('notes'),
  ]),
  Table(pantryItemsTable, [
    Column.text('name'),
    Column.integer('stock_status'), // Changed from in_stock to stock_status
    Column.integer('is_staple'),
    Column.integer('is_canonicalised'),
    Column.text('user_id'),
    Column.text('household_id'),
    Column.text('unit'),
    Column.real('quantity'),
    Column.text('base_unit'),
    Column.real('base_quantity'),
    Column.real('price'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.integer('deleted_at'),
    Column.text('terms'),
    Column.text('category'),
  ]),
  Table(ingredientTermOverridesTable, [
    Column.text('mapped_term'),
    Column.text('input_term'),
    Column.text('user_id'),
    Column.text('household_id'),
    Column.integer('deleted_at'),
    Column.integer('created_at'),
  ]),
  Table(shoppingListsTable, [
    Column.text('name'),
    Column.text('user_id'),
    Column.text('household_id'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.integer('deleted_at'),
  ]),
  Table(shoppingListItemsTable, [
    Column.text('shopping_list_id'),
    Column.text('name'),
    Column.text('terms'),
    Column.text('category'),
    Column.text('source_recipe_id'),
    Column.real('amount'),
    Column.text('unit'),
    Column.integer('bought'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.integer('deleted_at'),
    Column.text('user_id'),
    Column.text('household_id'),
  ]),
  Table(convertersTable, [
    Column.text('term'),
    Column.text('from_unit'),
    Column.text('to_base_unit'),
    Column.real('conversion_factor'),
    Column.integer('is_approximate'),
    Column.text('notes'),
    Column.text('user_id'),
    Column.text('household_id'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.integer('deleted_at'),
  ]),
  Table(mealPlansTable, [
    Column.text('date'),
    Column.text('user_id'),
    Column.text('household_id'),
    Column.text('items'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
    Column.integer('deleted_at'),
  ]),
]));
