import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../repositories/recipe_folder_repository.dart';
import '../repositories/recipe_repository.dart';

// RecipeFolderNotifier manages a list of RecipeFolderEntry.
class RecipeFolderNotifier extends StateNotifier<AsyncValue<List<RecipeFolderEntry>>> {
  final RecipeFolderRepository _repository;
  final RecipeRepository _recipeRepository;
  late final StreamSubscription<List<RecipeFolderEntry>> _subscription;

  RecipeFolderNotifier(this._repository, this._recipeRepository) : super(const AsyncValue.loading()) {
    // Listen to the stream of folders from Drift.
    _subscription = _repository.watchFolders().listen(
          (folders) {
        state = AsyncValue.data(folders);
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

  /// Add a new folder and return its ID
  Future<String?> addFolder({
    required String name,
    String? householdId,
    String? userId,
  }) async {
    try {
      final newFolder = await _repository.addFolder(
        name: name,
        userId: userId,
        householdId: householdId,
      );
      return newFolder.id;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  // Delete a folder by id.
  Future<void> deleteFolder(String id) async {
    try {
      await _repository.deleteFolderAndCleanupReferences(id, _recipeRepository);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add a smart folder
  Future<String?> addSmartFolder({
    required String name,
    required int folderType,
    required int filterLogic,
    List<String>? tags,
    List<String>? terms,
    String? userId,
    String? householdId,
  }) async {
    try {
      final newFolder = await _repository.addSmartFolder(
        name: name,
        folderType: folderType,
        filterLogic: filterLogic,
        tags: tags,
        terms: terms,
        userId: userId,
        householdId: householdId,
      );
      return newFolder.id;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Update smart folder settings
  Future<void> updateSmartFolderSettings({
    required String id,
    String? name,
    int? filterLogic,
    List<String>? tags,
    List<String>? terms,
  }) async {
    try {
      await _repository.updateSmartFolderSettings(
        id: id,
        name: name,
        filterLogic: filterLogic,
        tags: tags,
        terms: terms,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider to expose the RecipeFolderNotifier.
final recipeFolderNotifierProvider = StateNotifierProvider<RecipeFolderNotifier, AsyncValue<List<RecipeFolderEntry>>>(
      (ref) {
    final repository = ref.watch(recipeFolderRepositoryProvider);
    final recipeRepository = ref.watch(recipeRepositoryProvider);
    return RecipeFolderNotifier(repository, recipeRepository);
  },
);
