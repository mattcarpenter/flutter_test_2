import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../repositories/recipe_tag_repository.dart';
import '../../../repositories/recipe_repository.dart';

/// State for tag management operations
class TagManagementState {
  final List<RecipeTagEntry> tags;
  final Map<String, int> recipeCounts;
  final bool isLoading;
  final String? error;

  const TagManagementState({
    this.tags = const [],
    this.recipeCounts = const {},
    this.isLoading = false,
    this.error,
  });

  TagManagementState copyWith({
    List<RecipeTagEntry>? tags,
    Map<String, int>? recipeCounts,
    bool? isLoading,
    String? error,
  }) {
    return TagManagementState(
      tags: tags ?? this.tags,
      recipeCounts: recipeCounts ?? this.recipeCounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for managing tag operations and recipe counts
class TagManagementNotifier extends StateNotifier<TagManagementState> {
  final RecipeTagRepository _tagRepository;
  final RecipeRepository _recipeRepository;

  TagManagementNotifier(this._tagRepository, this._recipeRepository) : super(const TagManagementState()) {
    _loadTagsAndCounts();
  }

  /// Load all tags and their recipe counts
  Future<void> _loadTagsAndCounts() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Load tags and counts in parallel
      final futures = await Future.wait([
        _tagRepository.watchTags().first,
        _tagRepository.getRecipeCountsByTag(),
      ]);
      
      final tags = futures[0] as List<RecipeTagEntry>;
      final recipeCounts = futures[1] as Map<String, int>;
      
      state = state.copyWith(
        tags: tags,
        recipeCounts: recipeCounts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tags: $e',
      );
    }
  }

  /// Refresh tags and counts
  Future<void> refresh() async {
    await _loadTagsAndCounts();
  }

  /// Update a tag's color
  Future<void> updateTagColor(String tagId, String color) async {
    try {
      await _tagRepository.updateTag(tagId: tagId, color: color);
      // Refresh to get updated tag
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update tag color: $e');
    }
  }

  /// Delete a tag (soft delete)
  Future<void> deleteTag(String tagId) async {
    try {
      await _tagRepository.deleteTagAndCleanupReferences(tagId, _recipeRepository);
      // Refresh to remove deleted tag
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete tag: $e');
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for tag management state
final tagManagementProvider = StateNotifierProvider<TagManagementNotifier, TagManagementState>((ref) {
  final tagRepository = ref.watch(recipeTagRepositoryProvider);
  final recipeRepository = ref.watch(recipeRepositoryProvider);
  return TagManagementNotifier(tagRepository, recipeRepository);
});