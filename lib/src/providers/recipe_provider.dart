import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../models/recipe_with_folders.dart';
import '../repositories/recipe_repository.dart';

class RecipeNotifier extends StateNotifier<AsyncValue<List<RecipeWithFolders>>> {
  final RecipeRepository _repository;
  late final StreamSubscription<List<RecipeWithFolders>> _subscription;

  RecipeNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchRecipesWithFolders().listen(
          (recipesWithFolders) {
        state = AsyncValue.data(recipesWithFolders);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Add a new recipe. Note: Folder assignments can be handled separately.
  Future<void> addRecipe({
    required String title,
    required String language,
    required int rating,
    String? description,
    int? servings,
    int? prepTime,
    int? cookTime,
    int? totalTime,
    String? source,
    String? nutrition,
    String? generalNotes,
    String? userId,
    String? householdId,
    int? createdAt,
    int? updatedAt,
    String? ingredients,
    String? steps,
    // If you want to handle folder assignments immediately, pass folderIds.
    List<String> folderIds = const [],
  }) async {
    try {
      final recipeCompanion = RecipesCompanion.insert(
        title: title,
        description: Value(description),
        rating: rating,
        language: language,
        servings: Value(servings),
        prepTime: Value(prepTime),
        cookTime: Value(cookTime),
        totalTime: Value(totalTime),
        source: Value(source),
        nutrition: Value(nutrition),
        generalNotes: Value(generalNotes),
        userId: Value(userId),
        householdId: Value(householdId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        ingredients: Value(ingredients),
        steps: Value(steps),
      );

      // Insert the recipe.
      await _repository.addRecipe(recipeCompanion);

      // If desired, folder assignments can be added here using the
      // RecipeFolderAssignmentRepository.
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
