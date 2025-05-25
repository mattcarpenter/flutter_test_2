// lib/repositories/recipe_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/converters.dart';
import '../../database/database.dart';
import '../../database/models/ingredients.dart';
import '../../database/models/pantry_items.dart'; // For StockStatus enum
import '../../database/models/recipe_images.dart';
import '../../database/models/steps.dart';
import '../../database/powersync.dart';
import '../../utils/language.dart';
import '../../utils/mecab_wrapper.dart';
import '../models/ingredient_pantry_match.dart';
import '../models/recipe_pantry_match.dart';
import '../models/recipe_with_folders.dart';
import '../managers/ingredient_term_queue_manager.dart';

class RecipeRepository {
  final AppDatabase _db;
  IngredientTermQueueManager? _ingredientTermQueueManager;

  RecipeRepository(this._db);

  set ingredientTermQueueManager(IngredientTermQueueManager manager) {
    _ingredientTermQueueManager = manager;
  }

  // Watch all recipes.
  Stream<List<RecipeEntry>> watchAllRecipes() {
    return _db.select(_db.recipes).watch();
  }

  // Insert a new recipe.
  Future<int> addRecipe(RecipesCompanion recipe) async {
    final result = await _db.into(_db.recipes).insert(recipe);

    // Queue ingredients for canonicalization if they exist
    if (recipe.ingredients.present && recipe.ingredients.value != null) {
      final ingredients = recipe.ingredients.value!;
      if (ingredients.isNotEmpty && _ingredientTermQueueManager != null) {
        // Use the recipe ID directly from the RecipesCompanion object
        // since we know it's explicitly provided (not auto-generated)
        if (recipe.id.present) {
          final recipeId = recipe.id.value;
          await _ingredientTermQueueManager!.queueRecipeIngredients(
            recipeId,
            ingredients,
          );
        } else {
          // Fallback to getting the most recent recipe only if needed (legacy support)
          try {
            final recipeEntry = await (_db.select(_db.recipes)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
                .getSingleOrNull();

            if (recipeEntry != null) {
              await _ingredientTermQueueManager!.queueRecipeIngredients(
                recipeEntry.id,
                ingredients,
              );
            } else {
              debugPrint('Warning: Could not find recipe to queue ingredients');
            }
          } catch (e) {
            debugPrint('Error finding recipe to queue ingredients: $e');
          }
        }
      }
    }

    return result;
  }

  // Update a recipe.
  Future<bool> updateRecipe(RecipeEntry recipe) async {
    final result = await _db.update(_db.recipes).replace(recipe);

    // Queue ingredients for canonicalization if they exist
    if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty &&
        _ingredientTermQueueManager != null) {
      await _ingredientTermQueueManager!.queueRecipeIngredients(
        recipe.id,
        recipe.ingredients!,
      );
    }

    return result;
  }

  Future<RecipeEntry?> getRecipeById(String id) {
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  // lib/repositories/recipe_repository.dart
  Future<bool> updateImageForRecipe({
    required String recipeId,
    required String fileName,
    required String publicUrl,
  }) async {
    // Query the recipe using recipeId.
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();

    // Get the current images list.
    final List<RecipeImage> images = recipe.images ?? [];

    // Update the image that matches fileName.
    final updatedImages = images.map((img) {
      if (img.fileName == fileName) {
        return img.copyWith(publicUrl: publicUrl);
      }
      return img;
    }).toList();

    // Create an updated copy of the recipe.
    final updatedRecipe = recipe.copyWith(images: Value(updatedImages));

    // Update the recipe in the database.
    return updateRecipe(updatedRecipe);
  }

  // Soft delete a recipe using the deletedAt timestamp
  Future<bool> deleteRecipe(String id) async {
    final recipe = await getRecipeById(id);
    if (recipe != null) {
      final updatedRecipe = recipe.copyWith(deletedAt: Value(DateTime.now().millisecondsSinceEpoch));
      return updateRecipe(updatedRecipe);
    }
    return false;
  }

  // Helper: Add a folder assignment to a recipe by updating its folder_ids array.
  Future<void> addFolderToRecipe({
    required String recipeId,
    required String folderId,
  }) async {
    // Fetch the recipe record.
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    // Assuming folderIds is converted to List<String> using a custom type converter.
    final currentFolderIds = recipe.folderIds ?? <String>[];
    if (!currentFolderIds.contains(folderId)) {
      final updatedFolderIds = List<String>.from(currentFolderIds)..add(folderId);
      // Create an updated copy of the recipe.
      final updatedRecipe = recipe.copyWith(folderIds: Value(updatedFolderIds));
      await updateRecipe(updatedRecipe);
    }
  }

  // Helper: Remove a folder assignment from a recipe.
  Future<void> removeFolderFromRecipe({
    required String recipeId,
    required String folderId,
  }) async {
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    final currentFolderIds = recipe.folderIds ?? <String>[];
    if (currentFolderIds.contains(folderId)) {
      final updatedFolderIds = List<String>.from(currentFolderIds)..remove(folderId);
      final updatedRecipe = recipe.copyWith(folderIds: Value(updatedFolderIds));
      await updateRecipe(updatedRecipe);
    }
  }

  // Batch update: Replace the entire ingredients package for a recipe.
  Future<bool> updateIngredients(String recipeId, List<Ingredient> ingredients) async {
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    final updatedRecipe = recipe.copyWith(
      ingredients: Value(ingredients),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    // Here we won't call queueRecipeIngredients explicitly since it's handled in updateRecipe
    return updateRecipe(updatedRecipe);
  }

  // Batch update: Replace the entire steps package for a recipe.
  Future<bool> updateSteps(String recipeId, List<Step> steps) async {
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    final updatedRecipe = recipe.copyWith(steps: Value(steps));
    return updateRecipe(updatedRecipe);
  }

  // Watch recipes along with their folder details.
  // Update this method if you have a different strategy now to retrieve folder details.
  // For instance, you may need to join recipes with recipe_folders by checking if folderIds contains the folder's id.
  Stream<List<RecipeWithFolders>> watchRecipesWithFolders() {
    final query = _db.customSelect(
      '''
    SELECT 
      r.id AS recipe_id, 
      r.title AS recipe_title,
      r.description AS recipe_description,
      r.rating AS recipe_rating,
      r.language AS recipe_language,
      r.servings AS recipe_servings,
      r.prep_time AS recipe_prep_time,
      r.cook_time AS recipe_cook_time,
      r.total_time AS recipe_total_time,
      r.source AS recipe_source,
      r.nutrition AS recipe_nutrition,
      r.general_notes AS recipe_general_notes,
      r.user_id AS recipe_user_id,
      r.household_id AS recipe_household_id,
      r.created_at AS recipe_created_at,
      r.updated_at AS recipe_updated_at,
      r.ingredients AS recipe_ingredients,
      r.steps AS recipe_steps,
      r.folder_ids AS recipe_folder_ids,
      r.images AS recipe_images,
      r.deleted_at AS recipe_deleted_at,
      
      f.id AS folder_id, 
      f.name AS folder_name,
      f.deleted_at AS folder_deleted_at
    FROM recipes r
    LEFT JOIN recipe_folders f 
      ON f.id IN (SELECT value FROM json_each(r.folder_ids))
    WHERE r.deleted_at IS NULL
    ORDER BY r.created_at, r.id DESC
    ''',
      readsFrom: {
        _db.recipes,
        _db.recipeFolders,
      },
    ).watch();

    return query.map((rows) {
      // Group rows by recipe id.
      final Map<String, RecipeWithFolders> recipeMap = {};
      for (final row in rows) {
        final recipeId = row.read<String>('recipe_id');
        if (!recipeMap.containsKey(recipeId)) {
          // Build the RecipeEntry.
          final recipe = RecipeEntry(
            id: recipeId,
            title: row.read<String>('recipe_title'),
            description: row.read<String?>('recipe_description') ?? '',
            rating: row.read<int?>('recipe_rating'),
            language: row.read<String>('recipe_language'),
            servings: row.read<int?>('recipe_servings'),
            prepTime: row.read<int?>('recipe_prep_time'),
            cookTime: row.read<int?>('recipe_cook_time'),
            totalTime: row.read<int?>('recipe_total_time'),
            source: row.read<String?>('recipe_source'),
            nutrition: row.read<String?>('recipe_nutrition'),
            generalNotes: row.read<String?>('recipe_general_notes'),
            userId: row.read<String?>('recipe_user_id'),
            householdId: row.read<String?>('recipe_household_id'),
            createdAt: row.read<int?>('recipe_created_at'),
            updatedAt: row.read<int?>('recipe_updated_at'),
            deletedAt: row.read<int?>('recipe_deleted_at'),

            // Convert JSON String to List<Ingredient>
            ingredients: row.read<String?>('recipe_ingredients') != null
                ? const IngredientListConverter().fromSql(row.read<String>('recipe_ingredients'))
                : [],

            // Convert JSON String to List<Step>
            steps: row.read<String?>('recipe_steps') != null
                ? const StepListConverter().fromSql(row.read<String>('recipe_steps'))
                : [],

            images: row.read<String?>('recipe_images') != null
                ? const RecipeImageListConverter().fromSql(row.read<String>('recipe_images'))
                : [],

            folderIds: List<String>.from(jsonDecode(row.read<String>('recipe_folder_ids'))),
          );
          recipeMap[recipeId] = RecipeWithFolders(recipe: recipe, folders: []);
        }
        // If a folder is joined, add it to the composite.
        final folderId = row.read<String?>('folder_id');
        if (folderId != null) {
          final folder = RecipeFolderEntry(
            id: folderId,
            name: row.read<String>('folder_name'),
            deletedAt: row.read<int?>('folder_deleted_at'),
          );
          recipeMap[recipeId]!.folders.add(folder);
        }
      }
      return recipeMap.values.toList();
    });
  }

  // Add this to your RecipeRepository class
  Stream<List<RecipeWithFolders>> watchRecipesByFolderId(String folderId) {
    final query = _db.customSelect(
      '''
    SELECT 
      r.id AS recipe_id, 
      r.title AS recipe_title,
      r.description AS recipe_description,
      r.rating AS recipe_rating,
      r.language AS recipe_language,
      r.servings AS recipe_servings,
      r.prep_time AS recipe_prep_time,
      r.cook_time AS recipe_cook_time,
      r.total_time AS recipe_total_time,
      r.source AS recipe_source,
      r.nutrition AS recipe_nutrition,
      r.general_notes AS recipe_general_notes,
      r.user_id AS recipe_user_id,
      r.household_id AS recipe_household_id,
      r.created_at AS recipe_created_at,
      r.updated_at AS recipe_updated_at,
      r.ingredients AS recipe_ingredients,
      r.steps AS recipe_steps,
      r.folder_ids AS recipe_folder_ids,
      r.images AS recipe_images,
      r.deleted_at AS recipe_deleted_at,
      
      f.id AS folder_id, 
      f.name AS folder_name,
      f.deleted_at AS folder_deleted_at
    FROM recipes r
    LEFT JOIN recipe_folders f 
      ON f.id IN (SELECT value FROM json_each(r.folder_ids))
    WHERE (json_array_contains(r.folder_ids, ?)
    OR (? IS NULL AND r.folder_ids IS NULL))
    AND r.deleted_at IS NULL
    ORDER BY r.created_at, r.id DESC
    ''',
      variables: [
        Variable(folderId),
        Variable(folderId)
      ],
      readsFrom: {
        _db.recipes,
        _db.recipeFolders,
      },
    ).watch();

    return query.map((rows) {
      // Group rows by recipe id
      final Map<String, RecipeWithFolders> recipeMap = {};
      for (final row in rows) {
        final recipeId = row.read<String>('recipe_id');
        if (!recipeMap.containsKey(recipeId)) {
          // Build the RecipeEntry
          final recipe = RecipeEntry(
            id: recipeId,
            title: row.read<String>('recipe_title'),
            description: row.read<String?>('recipe_description') ?? '',
            rating: row.read<int?>('recipe_rating'),
            language: row.read<String>('recipe_language'),
            servings: row.read<int?>('recipe_servings'),
            prepTime: row.read<int?>('recipe_prep_time'),
            cookTime: row.read<int?>('recipe_cook_time'),
            totalTime: row.read<int?>('recipe_total_time'),
            source: row.read<String?>('recipe_source'),
            nutrition: row.read<String?>('recipe_nutrition'),
            generalNotes: row.read<String?>('recipe_general_notes'),
            userId: row.read<String?>('recipe_user_id'),
            householdId: row.read<String?>('recipe_household_id'),
            createdAt: row.read<int?>('recipe_created_at'),
            updatedAt: row.read<int?>('recipe_updated_at'),
            deletedAt: row.read<int?>('recipe_deleted_at'),

            // Convert JSON String to List<Ingredient>
            ingredients: row.read<String?>('recipe_ingredients') != null
                ? const IngredientListConverter().fromSql(row.read<String>('recipe_ingredients'))
                : [],

            // Convert JSON String to List<Step>
            steps: row.read<String?>('recipe_steps') != null
                ? const StepListConverter().fromSql(row.read<String>('recipe_steps'))
                : [],

            folderIds: row.read<String?>('recipe_folder_ids') != null
                ? List<String>.from(jsonDecode(row.read<String>('recipe_folder_ids')))
                : [],

            images: row.read<String?>('recipe_images') != null
                ? const RecipeImageListConverter().fromSql(row.read<String>('recipe_images'))
                : [],
          );
          recipeMap[recipeId] = RecipeWithFolders(recipe: recipe, folders: []);
        }

        // If a folder is joined, add it to the composite
        final folderId = row.read<String?>('folder_id');
        if (folderId != null) {
          final folder = RecipeFolderEntry(
            id: folderId,
            name: row.read<String>('folder_name'),
            deletedAt: row.read<int?>('folder_deleted_at'),
          );
          recipeMap[recipeId]!.folders.add(folder);
        }
      }
      return recipeMap.values.toList();
    });
  }

  Stream<RecipeEntry?> watchRecipeById(String id) {
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> removeFolderIdFromAllRecipes(String folderId) async {
    // Get all recipes that aren't deleted
    final recipesQuery = _db.select(_db.recipes)
      ..where((tbl) => tbl.deletedAt.isNull());

    final recipes = await recipesQuery.get();

    // Filter to recipes that contain this folder ID
    final recipesToUpdate = recipes.where((recipe) {
      return recipe.folderIds != null && recipe.folderIds!.contains(folderId);
    }).toList();

    // Update each recipe by removing the folder ID
    for (final recipe in recipesToUpdate) {
      final updatedFolderIds = List<String>.from(recipe.folderIds ?? [])..remove(folderId);
      final updatedRecipe = recipe.copyWith(
        folderIds: Value(updatedFolderIds),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
      await updateRecipe(updatedRecipe);
    }
  }

  Future<List<RecipeEntry>> searchRecipes(String query) async {
    if (containsJapanese(query)) {
      // Use MeCab to tokenize the Japanese query
      final terms = MecabWrapper().segment(query).split(' ').where((t) => t.isNotEmpty).toList();

      if (terms.isEmpty) return [];

      // First query: all terms must match (AND)
      final andConditions = terms.map((t) => "r.title LIKE '%$t%' OR r.description LIKE '%$t%'").join(" AND ");
      final andResults = await _db.customSelect(
        '''
      SELECT * FROM recipes r 
      WHERE r.deleted_at IS NULL AND ($andConditions)
      ORDER BY r.created_at DESC
      ''',
        readsFrom: {_db.recipes},
      ).get().then((rows) => rows.map(_rowToRecipe).toList());

      // Second query: any term matches (OR)
      final orConditions = terms.map((t) => "r.title LIKE '%$t%' OR r.description LIKE '%$t%'").join(" OR ");
      final orResults = await _db.customSelect(
        '''
      SELECT * FROM recipes r 
      WHERE r.deleted_at IS NULL AND ($orConditions)
      ORDER BY r.created_at DESC
      ''',
        readsFrom: {_db.recipes},
      ).get().then((rows) => rows.map(_rowToRecipe).toList());

      // Combine, keeping order and removing duplicates
      final all = [...andResults];
      for (var r in orResults) {
        if (!all.any((e) => e.id == r.id)) {
          all.add(r);
        }
      }
      return all;
    } else {
      final sanitized = sanitizeFtsQuery(query);
      final prefixed = '$sanitized*';

      // Use FTS for English
      final results = await _db.customSelect(
        '''
  SELECT r.* FROM fts_recipes
  JOIN recipes r ON fts_recipes.id = r.id
  WHERE fts_recipes MATCH ? AND r.deleted_at IS NULL
  ORDER BY rank
  ''',
        variables: [Variable(prefixed)],
        readsFrom: {_db.recipes},
      ).get();

      return results.map(_rowToRecipe).toList();
    }
  }

  RecipeEntry _rowToRecipe(QueryRow row) {
    return RecipeEntry(
      id: row.read<String>('id'),
      title: row.read<String>('title'),
      description: row.read<String?>('description') ?? '',
      rating: row.read<int?>('rating'),
      language: row.read<String?>('language'),
      servings: row.read<int?>('servings'),
      prepTime: row.read<int?>('prep_time'),
      cookTime: row.read<int?>('cook_time'),
      totalTime: row.read<int?>('total_time'),
      source: row.read<String?>('source'),
      nutrition: row.read<String?>('nutrition'),
      generalNotes: row.read<String?>('general_notes'),
      userId: row.read<String?>('user_id'),
      householdId: row.read<String?>('household_id'),
      createdAt: row.read<int?>('created_at'),
      updatedAt: row.read<int?>('updated_at'),
      deletedAt: row.read<int?>('deleted_at'),
      ingredients: row.read<String?>('ingredients') != null
          ? const IngredientListConverter().fromSql(row.read<String>('ingredients'))
          : [],
      steps: row.read<String?>('steps') != null
          ? const StepListConverter().fromSql(row.read<String>('steps'))
          : [],
      images: row.read<String?>('images') != null
          ? const RecipeImageListConverter().fromSql(row.read<String>('images'))
          : [],
      folderIds: row.read<String?>('folder_ids') != null
          ? List<String>.from(jsonDecode(row.read<String>('folder_ids')))
          : [],
    );
  }

  /// Find recipes that can be made with ingredients in the pantry
  ///
  /// Returns a list of [RecipePantryMatch] objects containing recipes that match
  /// at least one ingredient term in the pantry, sorted by match ratio (highest first)
  Future<List<RecipePantryMatch>> findMatchingRecipesFromPantry() async {
    try {
      final results = await _db.customSelect('''
  WITH ingredient_terms_with_mapping AS (
    SELECT
      rit.recipe_id,
      rit.ingredient_id,
      COALESCE(ito.mapped_term, rit.term) AS effective_term
    FROM recipe_ingredient_terms rit
    LEFT JOIN ingredient_term_overrides_flattened ito
      ON rit.term = ito.input_term
      AND ito.deleted_at IS NULL
  ),
  /* Find matching ingredients (not just terms) */
  matching_ingredients AS (
    SELECT
      itwm.recipe_id,
      itwm.ingredient_id,
      1 AS matched
    FROM ingredient_terms_with_mapping itwm
    INNER JOIN pantry_item_terms pit
      ON LOWER(itwm.effective_term) = LOWER(pit.term)
    GROUP BY itwm.recipe_id, itwm.ingredient_id
  ),
  /* Count matched ingredients per recipe */
  ingredient_matches AS (
    SELECT
      recipe_id,
      COUNT(DISTINCT ingredient_id) AS matched_ingredients,
      (
        SELECT GROUP_CONCAT(DISTINCT pantry_item_id)
        FROM ingredient_terms_with_mapping itwm
        INNER JOIN pantry_item_terms pit
          ON LOWER(itwm.effective_term) = LOWER(pit.term)
        WHERE itwm.recipe_id = mi.recipe_id
      ) AS matching_pantry_item_ids
    FROM matching_ingredients mi
    GROUP BY recipe_id
  ),
  /* Count total ingredients per recipe */
  total_ingredients AS (
    SELECT
      recipe_id,
      COUNT(DISTINCT ingredient_id) AS total_ingredients
    FROM recipe_ingredient_terms
    GROUP BY recipe_id
  )
  SELECT
    r.*,
    COALESCE(im.matched_ingredients, 0) AS matched_terms,
    ti.total_ingredients AS total_terms,
    (COALESCE(im.matched_ingredients, 0) * 1.0 / NULLIF(ti.total_ingredients, 0)) AS match_ratio,
    im.matching_pantry_item_ids
  FROM recipes r
  LEFT JOIN ingredient_matches im ON r.id = im.recipe_id
  LEFT JOIN total_ingredients ti ON r.id = ti.recipe_id
  WHERE r.deleted_at IS NULL AND COALESCE(im.matched_ingredients, 0) > 0
  ORDER BY match_ratio DESC, matched_terms DESC
''',
          readsFrom: {
            _db.recipes,
          }).get();

      return results.map((row) {
        final recipe = _rowToRecipe(row);
        final matchedTerms = row.read<int>('matched_terms');
        final totalTerms = row.read<int>('total_terms');
        final matchRatio = row.read<double>('match_ratio');

        // Parse matching pantry item IDs
        List<String>? matchedPantryItemIds;
        final pantryItemsString = row.read<String?>('matching_pantry_item_ids');
        if (pantryItemsString != null && pantryItemsString.isNotEmpty) {
          matchedPantryItemIds = pantryItemsString.split(',');
        }

        return RecipePantryMatch(
          recipe: recipe,
          matchedTerms: matchedTerms,
          totalTerms: totalTerms,
          matchRatio: matchRatio,
          matchedPantryItemIds: matchedPantryItemIds,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error finding matching recipes: $e');
      rethrow;
    }
  }

  /// Find pantry items that match ingredients for a specific recipe
  ///
  /// Returns a [RecipeIngredientMatches] object containing the matches for each ingredient
  Future<RecipeIngredientMatches> findPantryMatchesForRecipe(String recipeId) async {
    try {
      // First get the recipe to access its ingredients
      final recipe = await getRecipeById(recipeId);
      if (recipe == null || recipe.ingredients == null || recipe.ingredients!.isEmpty) {
        return RecipeIngredientMatches(recipeId: recipeId, matches: []);
      }

      // Prepare a map of ingredient IDs to ingredient objects
      final ingredientMap = {
        for (var ing in recipe.ingredients!) ing.id: ing
      };

      // Query to match ingredients with pantry items
      // Create a list of all ingredient IDs from the recipe
      final allIngredientIds = recipe.ingredients!.map((ing) => ing.id).toList();
      final ingredientIdParams = allIngredientIds.map((_) => '?').join(',');
      
      final results = await _db.customSelect('''
  WITH ingredient_terms_with_mapping AS (
    SELECT
      rit.recipe_id,
      rit.ingredient_id,
      COALESCE(ito.mapped_term, rit.term) AS effective_term
    FROM recipe_ingredient_terms rit
    LEFT JOIN ingredient_term_overrides_flattened ito
      ON rit.term = ito.input_term
      AND ito.deleted_at IS NULL
    WHERE rit.recipe_id = ?
  ),
  matching_pantry_items AS (
    SELECT
      itwm.ingredient_id,
      pit.pantry_item_id,
      MIN(pit.sort) AS term_priority
    FROM ingredient_terms_with_mapping itwm
    INNER JOIN pantry_item_terms pit
      ON LOWER(itwm.effective_term) = LOWER(pit.term)
    GROUP BY itwm.ingredient_id, pit.pantry_item_id
  )
  SELECT
    i.ingredient_id AS recipe_ingredient_id,
    p.pantry_item_id,
    p.id AS pantry_id,
    p.name,
    p.quantity,
    p.unit,
    p.user_id,
    p.household_id,
    p.created_at,
    p.updated_at,
    p.deleted_at,
    p.stock_status,
    p.is_staple
  FROM (
    SELECT ? AS ingredient_id
    ${allIngredientIds.length > 1 ? 'UNION ALL ' + allIngredientIds.skip(1).map((_) => 'SELECT ?').join(' UNION ALL ') : ''}
  ) i
  LEFT JOIN (
    SELECT 
      mpi.ingredient_id,
      mpi.pantry_item_id,
      pi.*
    FROM matching_pantry_items mpi
    INNER JOIN pantry_items pi ON mpi.pantry_item_id = pi.id
    WHERE pi.deleted_at IS NULL
      AND (mpi.ingredient_id, mpi.term_priority) IN (
        SELECT ingredient_id, MIN(term_priority)
        FROM matching_pantry_items
        GROUP BY ingredient_id
      )
  ) p ON i.ingredient_id = p.ingredient_id
''',
          variables: [
            Variable(recipeId),
            ...allIngredientIds.map((id) => Variable(id)),
          ],
          readsFrom: {
            _db.recipes,
            _db.pantryItems,
          }).get();

      // Process results into ingredient matches
      final matches = results.map((row) {
        final ingredientId = row.read<String>('recipe_ingredient_id');
        final ingredient = ingredientMap[ingredientId];

        if (ingredient == null) {
          // This shouldn't happen if the database is consistent
          debugPrint('Warning: Ingredient ID $ingredientId not found in recipe $recipeId');
          return null;
        }

        // Check if there's a matching pantry item
        final pantryItemId = row.readNullable<String>('pantry_id');
        PantryItemEntry? pantryItem;

        if (pantryItemId != null) {
          // Read stock_status directly as integer and convert to enum
          final stockStatusInt = row.read<int>('stock_status');
          final stockStatus = StockStatus.values[stockStatusInt];
          
          // Read is_staple as integer and convert to bool
          final isStapleInt = row.read<int>('is_staple');
          final isStaple = isStapleInt == 1;
          
          pantryItem = PantryItemEntry(
            id: pantryItemId,
            name: row.read<String>('name'),
            quantity: row.readNullable<double>('quantity'),
            unit: row.readNullable<String>('unit'),
            userId: row.readNullable<String>('user_id'),
            householdId: row.readNullable<String>('household_id'),
            createdAt: row.readNullable<int>('created_at'),
            updatedAt: row.readNullable<int>('updated_at'),
            deletedAt: row.readNullable<int>('deleted_at'),
            stockStatus: stockStatus,
            isStaple: isStaple,
          );
        }

        return IngredientPantryMatch(
          ingredient: ingredient,
          pantryItem: pantryItem,
        );
      }).whereType<IngredientPantryMatch>().toList();

      return RecipeIngredientMatches(
        recipeId: recipeId,
        matches: matches,
      );
    } catch (e) {
      debugPrint('Error finding pantry matches for recipe $recipeId: $e');
      rethrow;
    }
  }
}

// Separate the recipe repository provider from the dependency setup
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final repository = RecipeRepository(appDb);
  return repository;
});

String sanitizeFtsQuery(String query) {
  // Allow letters, numbers, spaces, and Japanese characters. Remove everything else.
  return query.replaceAll(RegExp(r'[^\w\s\u3040-\u30FF\u4E00-\u9FFF]'), '');
}
