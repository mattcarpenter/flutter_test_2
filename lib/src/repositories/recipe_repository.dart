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
    print('🔍 [RecipeRepository] Updating recipe ${recipe.id} with tagIds: ${recipe.tagIds}');
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
      r.tag_ids AS recipe_tag_ids,
      r.images AS recipe_images,
      r.deleted_at AS recipe_deleted_at,
      r.pinned AS recipe_pinned,
      r.pinned_at AS recipe_pinned_at,
      
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
            pinned: row.read<int?>('recipe_pinned'),
            pinnedAt: row.read<int?>('recipe_pinned_at'),

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
            
            tagIds: row.read<String?>('recipe_tag_ids') != null
                ? List<String>.from(jsonDecode(row.read<String>('recipe_tag_ids')))
                : [],
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
      r.tag_ids AS recipe_tag_ids,
      r.images AS recipe_images,
      r.deleted_at AS recipe_deleted_at,
      r.pinned AS recipe_pinned,
      r.pinned_at AS recipe_pinned_at,
      
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
      print('🔍 [RecipeRepository] watchRecipesWithFolders SQL returned ${rows.length} rows');
      
      // Debug: Check if tag_ids column exists and has data for our test recipe
      _db.customSelect('SELECT id, title, tag_ids FROM recipes WHERE id = ? LIMIT 1', 
        variables: [Variable.withString('02d5b515-0159-47da-b562-08f28fa78dd6')]
      ).getSingleOrNull().then((result) {
        if (result != null) {
          print('🔍 [RecipeRepository] Direct SQL check for test recipe: ${result.data}');
        } else {
          print('🔍 [RecipeRepository] Test recipe not found in direct SQL query');
        }
      }).catchError((e) {
        print('🔍 [RecipeRepository] Direct SQL error (probably missing column): $e');
      });
      
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
            pinned: row.read<int?>('recipe_pinned'),
            pinnedAt: row.read<int?>('recipe_pinned_at'),

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

            tagIds: row.read<String?>('recipe_tag_ids') != null
                ? List<String>.from(jsonDecode(row.read<String>('recipe_tag_ids')))
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
    // First, let's check what's actually in the database with a raw query
    _db.customSelect(
      'SELECT id, title, tag_ids FROM recipes WHERE id = ?',
      variables: [Variable.withString(id)]
    ).getSingleOrNull().then((rawResult) {
      if (rawResult != null) {
        print('🔍 [RecipeRepository] Raw DB data for $id: ${rawResult.data}');
        final tagIdsRaw = rawResult.data['tag_ids'];
        print('🔍 [RecipeRepository] Raw tag_ids value: "$tagIdsRaw" (type: ${tagIdsRaw.runtimeType})');
      }
    }).catchError((e) {
      print('🔍 [RecipeRepository] Raw query error: $e');
    });
    
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull().map((recipe) {
          if (recipe != null) {
            print('🔍 [RecipeRepository] Loaded recipe ${recipe.id} with tagIds: ${recipe.tagIds}');
          }
          return recipe;
        });
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

  Future<void> removeTagIdFromAllRecipes(String tagId) async {
    // Get all recipes that aren't deleted
    final recipesQuery = _db.select(_db.recipes)
      ..where((tbl) => tbl.deletedAt.isNull());
    final recipes = await recipesQuery.get();
    
    // Filter to recipes that contain this tag ID
    final recipesToUpdate = recipes.where((recipe) {
      return recipe.tagIds != null && recipe.tagIds!.contains(tagId);
    }).toList();
    
    // Update each recipe by removing the tag ID
    for (final recipe in recipesToUpdate) {
      final updatedTagIds = List<String>.from(recipe.tagIds ?? [])..remove(tagId);
      final updatedRecipe = recipe.copyWith(
        tagIds: Value(updatedTagIds),
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
      pinned: row.read<int?>('pinned'),
      pinnedAt: row.read<int?>('pinned_at'),
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
      // Step 1: Get recipes and their unique ingredients with match information
      final results = await _db.customSelect('''
  WITH ingredient_terms_with_mapping AS (
    SELECT
      rit.recipe_id,
      rit.ingredient_id,
      COALESCE(ito.mapped_term, rit.term) AS effective_term,
      rit.linked_recipe_id
    FROM recipe_ingredient_terms rit
    LEFT JOIN ingredient_term_overrides_flattened ito
      ON rit.term = ito.input_term
      AND ito.deleted_at IS NULL
  ),
  /* Find direct pantry matches for ingredients */
  direct_pantry_matches AS (
    SELECT DISTINCT
      itwm.recipe_id,
      itwm.ingredient_id
    FROM ingredient_terms_with_mapping itwm
    INNER JOIN pantry_item_terms pit ON LOWER(itwm.effective_term) = LOWER(pit.term)
    INNER JOIN pantry_items pi ON pit.pantry_item_id = pi.id 
      AND pi.stock_status = 2 AND pi.deleted_at IS NULL
    WHERE itwm.linked_recipe_id IS NULL
  ),
  /* Get unique ingredients per recipe with their match status */
  recipe_ingredients AS (
    SELECT DISTINCT
      r.id as recipe_id,
      rit.ingredient_id,
      rit.linked_recipe_id,
      CASE WHEN dpm.ingredient_id IS NOT NULL THEN 1 ELSE 0 END as has_direct_match
    FROM recipes r
    INNER JOIN recipe_ingredient_terms rit ON r.id = rit.recipe_id
    LEFT JOIN direct_pantry_matches dpm ON r.id = dpm.recipe_id AND rit.ingredient_id = dpm.ingredient_id
    WHERE r.deleted_at IS NULL
  )
  SELECT
    r.*,
    ri.ingredient_id,
    ri.linked_recipe_id,
    ri.has_direct_match,
    (
      SELECT GROUP_CONCAT(DISTINCT pi.id)
      FROM ingredient_terms_with_mapping itwm
      INNER JOIN pantry_item_terms pit ON LOWER(itwm.effective_term) = LOWER(pit.term)
      INNER JOIN pantry_items pi ON pit.pantry_item_id = pi.id
        AND pi.stock_status = 2 AND pi.deleted_at IS NULL
      WHERE itwm.recipe_id = r.id AND itwm.linked_recipe_id IS NULL
    ) AS matching_pantry_item_ids
  FROM recipes r
  INNER JOIN recipe_ingredients ri ON r.id = ri.recipe_id
  WHERE r.deleted_at IS NULL
  ORDER BY r.id, ri.ingredient_id
''',
          readsFrom: {
            _db.recipes,
          }).get();

      // Step 2: Process results in Dart to handle recipe dependencies
      return await _processRecipeMatches(results);
    } catch (e) {
      debugPrint('Error finding matching recipes: $e');
      rethrow;
    }
  }

  /// Process recipe match results with recursive recipe dependency checking
  Future<List<RecipePantryMatch>> _processRecipeMatches(List<QueryRow> rows) async {
    // Group results by recipe
    final Map<String, List<QueryRow>> recipeRows = {};
    for (final row in rows) {
      final recipeId = row.read<String>('id');
      recipeRows.putIfAbsent(recipeId, () => []).add(row);
    }

    final List<RecipePantryMatch> matches = [];
    final Set<String> visitedRecipes = <String>{};

    for (final entry in recipeRows.entries) {
      final recipeId = entry.key;
      final ingredientRows = entry.value;
      
      // Get the recipe data from the first row
      final firstRow = ingredientRows.first;
      final recipe = _rowToRecipe(firstRow);
      
      // Calculate match status with recursive checking
      final matchResult = await _calculateRecipeMatchWithDependencies(
        recipeId, 
        ingredientRows, 
        visitedRecipes,
        depth: 0
      );
      
      // Include recipe if it has any match (even partial)
      if (matchResult.hasAnyMatch) {
        // Parse matching pantry item IDs
        List<String>? matchedPantryItemIds;
        final pantryItemsString = firstRow.read<String?>('matching_pantry_item_ids');
        if (pantryItemsString != null && pantryItemsString.isNotEmpty) {
          matchedPantryItemIds = pantryItemsString.split(',');
        }

        matches.add(RecipePantryMatch(
          recipe: recipe,
          matchedTerms: matchResult.matchedIngredients,
          totalTerms: matchResult.totalIngredients,
          matchRatio: matchResult.matchRatio,
          matchedPantryItemIds: matchedPantryItemIds,
        ));
      }
    }

    // Sort by match ratio descending
    matches.sort((a, b) => b.matchRatio.compareTo(a.matchRatio));
    return matches;
  }

  /// Calculate recipe match including recursive dependencies
  Future<_RecipeMatchResult> _calculateRecipeMatchWithDependencies(
    String recipeId, 
    List<QueryRow> ingredientRows,
    Set<String> visitedRecipes,
    {int depth = 0}
  ) async {
    // Prevent infinite recursion
    if (depth > 3 || visitedRecipes.contains(recipeId)) {
      return _RecipeMatchResult(0, ingredientRows.length, false);
    }

    visitedRecipes.add(recipeId);
    int matchedIngredients = 0;
    
    for (final row in ingredientRows) {
      final hasDirectMatch = row.read<int>('has_direct_match') == 1;
      final linkedRecipeId = row.readNullable<String>('linked_recipe_id');
      
      if (hasDirectMatch) {
        matchedIngredients++;
      } else if (linkedRecipeId != null) {
        // Check if the linked recipe is makeable
        final linkedRecipeMatch = await _isLinkedRecipeMakeable(linkedRecipeId, visitedRecipes, depth + 1);
        if (linkedRecipeMatch) {
          matchedIngredients++;
        }
      }
    }
    
    visitedRecipes.remove(recipeId);
    final hasAnyMatch = matchedIngredients > 0;
    final matchRatio = ingredientRows.isNotEmpty ? matchedIngredients / ingredientRows.length : 0.0;
    
    return _RecipeMatchResult(matchedIngredients, ingredientRows.length, hasAnyMatch, matchRatio);
  }

  /// Check if a linked recipe can be made with current pantry
  Future<bool> _isLinkedRecipeMakeable(String recipeId, Set<String> visitedRecipes, int depth) async {
    if (depth > 3 || visitedRecipes.contains(recipeId)) {
      return false;
    }

    // Get unique ingredient data for the linked recipe
    final linkedIngredientRows = await _db.customSelect('''
      WITH ingredient_terms_with_mapping AS (
        SELECT
          rit.recipe_id,
          rit.ingredient_id,
          COALESCE(ito.mapped_term, rit.term) AS effective_term,
          rit.linked_recipe_id
        FROM recipe_ingredient_terms rit
        LEFT JOIN ingredient_term_overrides_flattened ito
          ON rit.term = ito.input_term
          AND ito.deleted_at IS NULL
        WHERE rit.recipe_id = ?
      ),
      direct_pantry_matches AS (
        SELECT DISTINCT
          itwm.recipe_id,
          itwm.ingredient_id
        FROM ingredient_terms_with_mapping itwm
        INNER JOIN pantry_item_terms pit ON LOWER(itwm.effective_term) = LOWER(pit.term)
        INNER JOIN pantry_items pi ON pit.pantry_item_id = pi.id 
          AND pi.stock_status = 2 AND pi.deleted_at IS NULL
      )
      SELECT DISTINCT
        rit.ingredient_id,
        rit.linked_recipe_id,
        CASE WHEN dpm.ingredient_id IS NOT NULL THEN 1 ELSE 0 END as has_direct_match
      FROM recipe_ingredient_terms rit
      LEFT JOIN direct_pantry_matches dpm ON rit.recipe_id = dpm.recipe_id AND rit.ingredient_id = dpm.ingredient_id
      WHERE rit.recipe_id = ?
    ''',
        variables: [Variable(recipeId), Variable(recipeId)],
        readsFrom: {_db.recipes}).get();

    final matchResult = await _calculateRecipeMatchWithDependencies(
      recipeId, 
      linkedIngredientRows, 
      visitedRecipes,
      depth: depth
    );
    
    // Recipe is makeable if ALL ingredients are matched (100% match ratio)
    return matchResult.matchRatio >= 1.0;
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
      COALESCE(ito.mapped_term, rit.term) AS effective_term,
      rit.linked_recipe_id
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
    INNER JOIN pantry_items pi ON pit.pantry_item_id = pi.id
    WHERE pi.deleted_at IS NULL
      AND pi.stock_status = 2  -- Only in-stock items (StockStatus.inStock = 2)
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
    p.is_staple,
    p.is_canonicalised,
    (
      SELECT linked_recipe_id 
      FROM ingredient_terms_with_mapping itwm2 
      WHERE itwm2.ingredient_id = i.ingredient_id 
        AND itwm2.linked_recipe_id IS NOT NULL 
      LIMIT 1
    ) AS linked_recipe_id
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
    WHERE (mpi.ingredient_id, mpi.term_priority) IN (
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
      final matches = <IngredientPantryMatch>[];
      for (final row in results) {
        final ingredientId = row.read<String>('recipe_ingredient_id');
        final ingredient = ingredientMap[ingredientId];

        if (ingredient == null) {
          // This shouldn't happen if the database is consistent
          debugPrint('Warning: Ingredient ID $ingredientId not found in recipe $recipeId');
          continue;
        }

        // Check if there's a matching pantry item
        final pantryItemId = row.readNullable<String>('pantry_id');
        final linkedRecipeId = row.readNullable<String>('linked_recipe_id');
        PantryItemEntry? pantryItem;
        bool hasRecipeMatch = false;

        if (pantryItemId != null) {
          // Read stock_status directly as integer and convert to enum
          final stockStatusInt = row.read<int>('stock_status');
          final stockStatus = StockStatus.values[stockStatusInt];
          
          // Read is_staple as integer and convert to bool
          final isStapleInt = row.read<int>('is_staple');
          final isStaple = isStapleInt == 1;
          
          // Read is_canonicalised as integer and convert to bool
          final isCanonicalizedInt = row.read<int>('is_canonicalised');
          final isCanonicalised = isCanonicalizedInt == 1;
          
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
            isCanonicalised: isCanonicalised,
          );
        } else if (linkedRecipeId != null) {
          // Check if the linked recipe is makeable (this will be done recursively)
          hasRecipeMatch = await _isLinkedRecipeMakeable(linkedRecipeId, <String>{}, 0);
        }

        matches.add(IngredientPantryMatch(
          ingredient: ingredient,
          pantryItem: pantryItem,
          hasRecipeMatch: hasRecipeMatch,
        ));
      }

      return RecipeIngredientMatches(
        recipeId: recipeId,
        matches: matches,
      );
    } catch (e) {
      debugPrint('Error finding pantry matches for recipe $recipeId: $e');
      rethrow;
    }
  }

  // Batch fetch recipes by IDs
  Future<List<RecipeEntry>> getRecipesByIds(List<String> recipeIds) async {
    if (recipeIds.isEmpty) return [];
    
    final recipes = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.isIn(recipeIds) & tbl.deletedAt.isNull()))
      .get();
    
    return recipes;
  }

  // Toggle pin status for a recipe
  Future<bool> toggleRecipePin(String recipeId, bool pinned) async {
    final recipe = await getRecipeById(recipeId);
    if (recipe != null) {
      final updatedRecipe = recipe.copyWith(
        pinned: Value(pinned ? 1 : 0),
        pinnedAt: Value(pinned ? DateTime.now().millisecondsSinceEpoch : null),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
      return updateRecipe(updatedRecipe);
    }
    return false;
  }

  // Get pinned recipes, sorted by most recently pinned first
  Future<List<RecipeEntry>> getPinnedRecipes({int limit = 10}) async {
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.pinned.equals(1) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.pinnedAt)])
      ..limit(limit))
      .get();
  }

  // Watch pinned recipes stream
  Stream<List<RecipeEntry>> watchPinnedRecipes({int limit = 10}) {
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.pinned.equals(1) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.pinnedAt)])
      ..limit(limit))
      .watch();
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

/// Helper class for recipe matching results
class _RecipeMatchResult {
  final int matchedIngredients;
  final int totalIngredients;
  final bool hasAnyMatch;
  final double matchRatio;

  _RecipeMatchResult(this.matchedIngredients, this.totalIngredients, this.hasAnyMatch, [double? ratio])
      : matchRatio = ratio ?? (totalIngredients > 0 ? matchedIngredients / totalIngredients : 0.0);
}
