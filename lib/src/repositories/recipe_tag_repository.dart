import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/models/recipe_tags.dart';
import '../../database/powersync.dart';
import 'recipe_repository.dart';

class RecipeTagRepository {
  final AppDatabase _db;

  RecipeTagRepository(this._db);

  /// Watch all recipe tags that are not marked as deleted, ordered by name
  Stream<List<RecipeTagEntry>> watchTags() {
    return (_db.select(_db.recipeTags)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Add a new tag
  Future<RecipeTagEntry> addTag({
    required String name,
    required String color,
    String? userId,
  }) async {
    final tagId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = RecipeTagsCompanion(
      id: Value(tagId),
      name: Value(name),
      color: Value(color),
      userId: Value(userId),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _db.into(_db.recipeTags).insert(entry);
    return await (_db.select(_db.recipeTags)
          ..where((tbl) => tbl.id.equals(tagId)))
        .getSingle();
  }

  /// Update a tag's properties
  Future<void> updateTag({
    required String tagId,
    String? name,
    String? color,
  }) async {
    await (_db.update(_db.recipeTags)
          ..where((tbl) => tbl.id.equals(tagId)))
        .write(RecipeTagsCompanion(
          name: name != null ? Value(name) : const Value.absent(),
          color: color != null ? Value(color) : const Value.absent(),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
  }

  /// Soft delete a tag by updating its deletedAt column
  Future<void> deleteTag(String tagId) async {
    await (_db.update(_db.recipeTags)
          ..where((tbl) => tbl.id.equals(tagId)))
        .write(RecipeTagsCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
  }

  /// Delete a tag and cleanup all references from recipes
  Future<void> deleteTagAndCleanupReferences(String tagId, RecipeRepository recipeRepository) async {
    // Use a transaction to ensure atomicity
    return _db.transaction(() async {
      // First, remove tag ID from all recipes
      await recipeRepository.removeTagIdFromAllRecipes(tagId);

      // Then soft-delete the tag
      await deleteTag(tagId);
    });
  }

  /// Get a single tag by ID
  Future<RecipeTagEntry?> getTagById(String id) {
    return (_db.select(_db.recipeTags)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get tags by IDs
  Future<List<RecipeTagEntry>> getTagsByIds(List<String> tagIds) {
    if (tagIds.isEmpty) return Future.value([]);
    
    return (_db.select(_db.recipeTags)
          ..where((tbl) => tbl.id.isIn(tagIds) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }
  
  /// Get recipe counts for all tags
  /// Returns a map of tag ID to recipe count
  Future<Map<String, int>> getRecipeCountsByTag() async {
    // Query to count recipes for each tag
    // Since tag_ids is stored as JSON array, we need to use JSON functions
    final results = await _db.customSelect(
      '''
      SELECT 
        r.tag_ids,
        COUNT(*) as recipe_count
      FROM recipes r
      WHERE r.deleted_at IS NULL 
        AND r.tag_ids IS NOT NULL 
        AND r.tag_ids != '[]'
      GROUP BY r.tag_ids
      '''
    ).get();
    
    // Process results to extract individual tag counts
    final Map<String, int> tagCounts = {};
    
    for (final row in results) {
      final tagIdsJson = row.data['tag_ids'] as String?;
      final recipeCount = row.data['recipe_count'] as int;
      
      if (tagIdsJson != null && tagIdsJson.isNotEmpty && tagIdsJson != '[]') {
        try {
          // Parse the JSON array of tag IDs
          final tagIdsList = (jsonDecode(tagIdsJson) as List<dynamic>).cast<String>();
          
          // Add count to each tag in the recipe
          for (final tagId in tagIdsList) {
            tagCounts[tagId] = (tagCounts[tagId] ?? 0) + recipeCount;
          }
        } catch (e) {
          // Skip malformed JSON
          continue;
        }
      }
    }
    
    return tagCounts;
  }
  
  /// Get recipe count for a specific tag
  Future<int> getRecipeCountForTag(String tagId) async {
    final result = await _db.customSelect(
      '''
      SELECT COUNT(*) as count
      FROM recipes r
      WHERE r.deleted_at IS NULL 
        AND r.tag_ids IS NOT NULL
        AND json_extract(r.tag_ids, '\$') LIKE '%"' || ? || '"%'
      ''',
      variables: [Variable.withString(tagId)]
    ).getSingleOrNull();
    
    return result?.data['count'] as int? ?? 0;
  }
}

final recipeTagRepositoryProvider = Provider<RecipeTagRepository>((ref) {
  return RecipeTagRepository(appDb);
});