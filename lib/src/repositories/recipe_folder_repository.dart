import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:uuid/uuid.dart';
import '../../database/converters.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../models/ingredient_term_search_result.dart';

class RecipeFolderRepository {
  final AppDatabase _db;

  RecipeFolderRepository(this._db);

  /// Helper to convert a raw SQL row to RecipeEntry with proper type conversion
  RecipeEntry _rowToRecipeEntry(QueryRow row) {
    const ingredientConverter = IngredientListConverter();
    const stepConverter = StepListConverter();
    const stringListConverter = StringListTypeConverter();
    const imageConverter = RecipeImageListConverter();

    final ingredientsRaw = row.readNullable<String>('ingredients');
    final stepsRaw = row.readNullable<String>('steps');
    final folderIdsRaw = row.readNullable<String>('folder_ids');
    final tagIdsRaw = row.readNullable<String>('tag_ids');
    final imagesRaw = row.readNullable<String>('images');

    return RecipeEntry(
      id: row.read<String>('id'),
      title: row.read<String>('title'),
      description: row.readNullable<String>('description'),
      rating: row.readNullable<int>('rating'),
      language: row.readNullable<String>('language'),
      servings: row.readNullable<int>('servings'),
      prepTime: row.readNullable<int>('prep_time'),
      cookTime: row.readNullable<int>('cook_time'),
      totalTime: row.readNullable<int>('total_time'),
      source: row.readNullable<String>('source'),
      nutrition: row.readNullable<String>('nutrition'),
      generalNotes: row.readNullable<String>('general_notes'),
      userId: row.read<String>('user_id'),
      householdId: row.readNullable<String>('household_id'),
      createdAt: row.readNullable<int>('created_at'),
      updatedAt: row.readNullable<int>('updated_at'),
      deletedAt: row.readNullable<int>('deleted_at'),
      pinned: row.read<int>('pinned'),
      pinnedAt: row.readNullable<int>('pinned_at'),
      ingredients: ingredientsRaw != null ? ingredientConverter.fromSql(ingredientsRaw) : null,
      steps: stepsRaw != null ? stepConverter.fromSql(stepsRaw) : null,
      folderIds: folderIdsRaw != null ? stringListConverter.fromSql(folderIdsRaw) : null,
      tagIds: tagIdsRaw != null ? stringListConverter.fromSql(tagIdsRaw) : null,
      images: imagesRaw != null ? imageConverter.fromSql(imagesRaw) : null,
    );
  }

  // Watch all recipe folders that are not marked as deleted.
  Stream<List<RecipeFolderEntry>> watchFolders() {
    return (_db.select(_db.recipeFolders)
      ..where((tbl) => tbl.deletedAt.isNull())
    ).watch();
  }

  /// Add a new folder and return the created folder entry
  Future<RecipeFolderEntry> addFolder({
    required String name,
    String? userId,
    String? householdId,
  }) async {
    final folderId = const Uuid().v4();
    final entry = RecipeFoldersCompanion(
      id: Value(folderId),
      name: Value(name),
      userId: Value(userId),
      householdId: Value(householdId),
    );

    await _db.into(_db.recipeFolders).insert(entry);
    return await (_db.select(_db.recipeFolders)
          ..where((tbl) => tbl.id.equals(folderId)))
        .getSingle();
  }

  // Soft delete a folder by updating its deletedAt column.
  Future<int> deleteFolder(String id) {
    return (_db.update(_db.recipeFolders)
      ..where((tbl) => tbl.id.equals(id))
    ).write(RecipeFoldersCompanion(
      deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteFolderAndCleanupReferences(String folderId, RecipeRepository recipeRepository) async {
    // Use a transaction to ensure atomicity
    return _db.transaction(() async {
      // First, remove folder ID from all recipes
      await recipeRepository.removeFolderIdFromAllRecipes(folderId);

      // Then soft-delete the folder
      await deleteFolder(folderId);
    });
  }

  /// Add a smart folder
  Future<RecipeFolderEntry> addSmartFolder({
    required String name,
    required int folderType,  // 1 = tag, 2 = ingredient
    required int filterLogic, // 0 = OR, 1 = AND
    List<String>? tags,
    List<String>? terms,
    String? userId,
    String? householdId,
  }) async {
    final folderId = const Uuid().v4();
    final entry = RecipeFoldersCompanion(
      id: Value(folderId),
      name: Value(name),
      userId: Value(userId),
      householdId: Value(householdId),
      folderType: Value(folderType),
      filterLogic: Value(filterLogic),
      smartFilterTags: Value(tags != null ? jsonEncode(tags) : null),
      smartFilterTerms: Value(terms != null ? jsonEncode(terms) : null),
    );
    await _db.into(_db.recipeFolders).insert(entry);
    return await (_db.select(_db.recipeFolders)
      ..where((tbl) => tbl.id.equals(folderId)))
      .getSingle();
  }

  /// Update smart folder settings (tags/terms/logic only, not type)
  Future<int> updateSmartFolderSettings({
    required String id,
    String? name,
    int? filterLogic,
    List<String>? tags,
    List<String>? terms,
  }) {
    return (_db.update(_db.recipeFolders)
      ..where((tbl) => tbl.id.equals(id))
    ).write(RecipeFoldersCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      filterLogic: filterLogic != null ? Value(filterLogic) : const Value.absent(),
      smartFilterTags: tags != null ? Value(jsonEncode(tags)) : const Value.absent(),
      smartFilterTerms: terms != null ? Value(jsonEncode(terms)) : const Value.absent(),
    ));
  }

  /// Get recipes matching a tag-based smart folder
  Future<List<RecipeEntry>> getRecipesForTagSmartFolder({
    required List<String> tagNames,
    required bool matchAll,
  }) async {
    if (tagNames.isEmpty) return [];

    // This query uses the recipe.tag_ids JSON array and joins with recipe_tags
    // to match by tag name (not ID) since smart folders store tag names
    final placeholders = tagNames.map((_) => '?').join(',');

    final results = await _db.customSelect('''
      WITH folder_tags AS (
        SELECT id, name FROM recipe_tags
        WHERE deleted_at IS NULL
        AND name IN ($placeholders)
      ),
      recipe_tag_matches AS (
        SELECT DISTINCT
          r.id as recipe_id,
          ft.name as matched_tag
        FROM recipes r,
             json_each(r.tag_ids) as tag_id,
             folder_tags ft
        WHERE tag_id.value = ft.id
        AND r.deleted_at IS NULL
      )
      SELECT r.*
      FROM recipes r
      WHERE r.id IN (
        SELECT recipe_id
        FROM recipe_tag_matches
        GROUP BY recipe_id
        ${matchAll ? 'HAVING COUNT(DISTINCT matched_tag) = ${tagNames.length}' : ''}
      )
    ''',
    variables: tagNames.map((t) => Variable(t)).toList(),
    readsFrom: {_db.recipes, _db.recipeTags}).get();

    return results.map(_rowToRecipeEntry).toList();
  }

  /// Get recipes matching an ingredient-based smart folder
  Future<List<RecipeEntry>> getRecipesForIngredientSmartFolder({
    required List<String> terms,
    required bool matchAll,
  }) async {
    if (terms.isEmpty) return [];

    // Search recipe_ingredient_terms table for matching terms
    final placeholders = terms.map((_) => 'LOWER(?)').join(',');

    final results = await _db.customSelect('''
      WITH matched_recipes AS (
        SELECT DISTINCT
          rit.recipe_id,
          rit.term as matched_term
        FROM recipe_ingredient_terms rit
        WHERE LOWER(rit.term) IN ($placeholders)
      )
      SELECT r.*
      FROM recipes r
      WHERE r.deleted_at IS NULL
      AND r.id IN (
        SELECT recipe_id
        FROM matched_recipes
        GROUP BY recipe_id
        ${matchAll ? 'HAVING COUNT(DISTINCT LOWER(matched_term)) >= ${terms.length}' : ''}
      )
    ''',
    variables: terms.map((t) => Variable(t)).toList(),
    readsFrom: {_db.recipes}).get();

    return results.map(_rowToRecipeEntry).toList();
  }

  /// Search ingredient terms for smart folder creation
  /// Returns terms matching the search query with recipe counts and details
  Future<List<IngredientTermSearchResult>> searchIngredientTerms(String query) async {
    if (query.trim().isEmpty) return [];

    final searchTerm = '%${query.toLowerCase()}%';

    // Get all matching terms with their recipes
    final results = await _db.customSelect('''
      SELECT
        rit.term,
        r.id as recipe_id,
        r.title as recipe_title
      FROM recipe_ingredient_terms rit
      INNER JOIN recipes r ON rit.recipe_id = r.id
      WHERE LOWER(rit.term) LIKE ?
      AND r.deleted_at IS NULL
      ORDER BY
        CASE
          WHEN LOWER(rit.term) = LOWER(?) THEN 0
          WHEN LOWER(rit.term) LIKE LOWER(?) THEN 1
          ELSE 2
        END,
        rit.term,
        r.title
    ''',
    variables: [
      Variable(searchTerm),
      Variable(query),
      Variable('$query%'),
    ],
    readsFrom: {_db.recipes}).get();

    // Group results by term (case-insensitive) and collect recipe info
    final Map<String, List<Map<String, String>>> termRecipes = {};
    final Map<String, String> termCanonical = {}; // Store the best casing

    for (final row in results) {
      final term = row.read<String>('term');
      final termLower = term.toLowerCase();
      final recipeId = row.read<String>('recipe_id');
      final recipeTitle = row.read<String>('recipe_title');

      // Keep the first occurrence's casing as canonical
      termCanonical.putIfAbsent(termLower, () => term);

      termRecipes.putIfAbsent(termLower, () => []);
      // Avoid duplicate recipes for the same term
      if (!termRecipes[termLower]!.any((r) => r['id'] == recipeId)) {
        termRecipes[termLower]!.add({
          'id': recipeId,
          'title': recipeTitle,
        });
      }
    }

    // Convert to IngredientTermSearchResult objects
    return termRecipes.entries.map((entry) {
      final termLower = entry.key;
      final recipes = entry.value;
      return IngredientTermSearchResult(
        term: termCanonical[termLower]!,
        recipeCount: recipes.length,
        recipeIds: recipes.map((r) => r['id']!).toList(),
        recipeTitles: recipes.map((r) => r['title']!).toList(),
      );
    }).toList();
  }
}


final recipeFolderRepositoryProvider = Provider<RecipeFolderRepository>((ref) {
  // Ensure the database is ready; if not, throw an exception.
  //final db = ref.watch(databaseProvider).maybeWhen(
  //  data: (db) => db,
  //  orElse: () => throw Exception('Database not initialized'),
  //);
  return RecipeFolderRepository(appDb);
});
