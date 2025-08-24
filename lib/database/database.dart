import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' hide Table;
import 'package:recipe_app/database/models/recipe_folders.dart';
import 'package:recipe_app/database/models/recipe_tags.dart';
import 'package:recipe_app/database/models/recipes.dart';
import 'package:uuid/uuid.dart';

import 'models/converters.dart';
import 'models/cooks.dart';
import 'models/household_members.dart';
import 'models/households.dart';
import 'models/household_invites.dart';
import 'models/pantry_items.dart';
import 'models/ingredient_term_overrides.dart';
import 'models/recipe_shares.dart';
import 'models/shopping_list_items.dart';
import 'models/shopping_lists.dart';
import 'models/upload_queues.dart';
import 'models/ingredient_term_queues.dart';
import 'models/pantry_item_term_queues.dart';
import 'models/shopping_list_item_term_queues.dart';
import 'models/meal_plans.dart';
import 'models/meal_plan_items.dart';
import 'models/user_subscriptions.dart';

import 'models/ingredients.dart';
import 'models/steps.dart';
import 'models/recipe_images.dart';
import 'models/pantry_item_terms.dart';

import 'converters.dart';

part 'database.g.dart';

@DriftDatabase(tables: [RecipeFolders, RecipeTags, Recipes, RecipeShares, HouseholdMembers, Households, HouseholdInvites, UploadQueues, IngredientTermQueues, PantryItemTermQueues, ShoppingListItemTermQueues, Cooks, PantryItems, IngredientTermOverrides, ShoppingListItems, ShoppingLists, Converters, MealPlans, UserSubscriptions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(PowerSyncDatabase db) : super(SqliteAsyncDriftConnection(db));

  @override
  int get schemaVersion => 1;
}
