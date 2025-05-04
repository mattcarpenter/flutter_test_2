// lib/src/managers/ingredient_term_queue_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../database/database.dart';
// The IngredientTerm type is already included via import of ingredient_canonicalization_service.dart
import '../../database/models/ingredients.dart';
import '../../database/powersync.dart';
import '../repositories/ingredient_term_queue_repository.dart';
import '../repositories/recipe_repository.dart';
import '../services/ingredient_canonicalization_service.dart';

class IngredientTermQueueManager {
  final IngredientTermQueueRepository repository;
  RecipeRepository? _recipeRepository;
  final IngredientCanonicalizer canonicalizer;
  final AppDatabase db;

  bool _isProcessing = false;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Constants for backoff
  static const Duration baseDelay = Duration(seconds: 5);
  static const int maxRetries = 3;

  // Direct field access is sufficient, no need for getter/setter
  // but we keep the setter for clarity about the circular dependency resolution
  set recipeRepository(RecipeRepository? repository) {
    _recipeRepository = repository;
  }

  IngredientTermQueueManager({
    required this.repository,
    required RecipeRepository? recipeRepository,
    required this.canonicalizer,
    required this.db,
  }) {
    _recipeRepository = recipeRepository;
    // Listen to connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
          // If we have connectivity, process the queue
          if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
            debugPrint('Connectivity regained, processing ingredient term queue.');
            processQueue();
          }
        });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Queue an ingredient for canonicalization
  Future<void> queueIngredient({
    required String recipeId,
    required Ingredient ingredient,
  }) async {
    // Skip if this is not an actual ingredient (e.g., section headers)
    if (ingredient.type != 'ingredient') {
      return;
    }

    // Skip if we already have terms (this is a manual override or previously processed)
    if (ingredient.terms != null && ingredient.terms!.isNotEmpty) {
      return;
    }

    // Check if there's an existing entry for this ingredient
    final existingEntry = await repository.getEntryByIds(recipeId, ingredient.id);
    if (existingEntry != null) {
      // If entry exists but failed previously, reset it to try again
      if (existingEntry.status == 'failed') {
        final resetEntry = existingEntry.copyWith(
          status: 'pending',
          retryCount: 0,
          requestTimestamp: DateTime.now().millisecondsSinceEpoch,
          lastTryTimestamp: Value(null),
        );
        await repository.updateEntry(resetEntry);
      }
      return;
    }

    // Add new entry to the queue
    await repository.insertQueueEntry(
      recipeId: recipeId,
      ingredientId: ingredient.id,
      ingredient: ingredient,
    );

    // Schedule processing
    _scheduleProcessing();
  }

  /// Queue all ingredients in a recipe
  Future<void> queueRecipeIngredients(String recipeId, List<Ingredient> ingredients) async {
    // First, cancel any existing queue entries for this recipe
    // This helps when a recipe is updated
    await repository.deleteEntriesByRecipeId(recipeId);

    // Add queue entries for each ingredient
    for (final ingredient in ingredients) {
      await queueIngredient(
        recipeId: recipeId,
        ingredient: ingredient,
      );
    }
  }

  /// Schedule a debounced queue processing
  void _scheduleProcessing({Duration delay = const Duration(seconds: 3)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      processQueue();
    });
  }

  /// Process the queue
  Future<void> processQueue() async {
    // Check connectivity
    final List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      debugPrint('Offline: ingredient term queue processing deferred.');
      return;
    }

    if (_isProcessing) return;
    _isProcessing = true;
    debugPrint('Processing ingredient term queue...');

    try {
      // Fetch all pending entries
      final pendingEntries = await repository.getPendingEntries();
      final now = DateTime.now().millisecondsSinceEpoch;
      bool hasReadyEntries = false;

      // Group entries by recipe for batch processing
      final Map<String, List<Map<String, dynamic>>> recipeIngredients = {};
      final Map<String, Map<String, dynamic>> entryMap = {};

      // Organize entries for batch processing and apply backoff policy
      for (final entry in pendingEntries) {
        // Calculate exponential backoff
        final backoffMillis = baseDelay.inMilliseconds * (1 << entry.retryCount);
        final lastTry = entry.lastTryTimestamp ?? 0;

        // Skip if backoff period hasn't elapsed
        if (now - lastTry < backoffMillis) {
          continue;
        }

        // Skip if max retries exceeded
        if (entry.retryCount >= maxRetries) {
          final failedEntry = entry.copyWith(
            status: 'failed',
            lastTryTimestamp: Value(now),
          );
          await repository.updateEntry(failedEntry);
          continue;
        }

        hasReadyEntries = true;

        // Parse ingredient data
        final Map<String, dynamic> ingredientData =
            json.decode(entry.ingredientData) as Map<String, dynamic>;

        // Group by recipe ID for batch processing
        if (!recipeIngredients.containsKey(entry.recipeId)) {
          recipeIngredients[entry.recipeId] = [];
        }

        // Add to batch and track the entry
        recipeIngredients[entry.recipeId]!.add(ingredientData);
        entryMap[entry.id] = {
          'entry': entry,
          'ingredientId': entry.ingredientId,
          'recipeId': entry.recipeId,
        };

        // Mark as processing
        final processingEntry = entry.copyWith(
          status: 'processing',
          lastTryTimestamp: Value(now),
        );
        await repository.updateEntry(processingEntry);
      }

      // Process each recipe's ingredients in batches
      for (final recipeId in recipeIngredients.keys) {
        final ingredients = recipeIngredients[recipeId]!;

        try {
          // Call the canonicalization API
          final results = await canonicalizer.canonicalizeIngredients(ingredients);

          // Find the entries for this recipe and update them
          final recipeEntries = entryMap.values
              .where((e) => e['recipeId'] == recipeId)
              .toList();

          // Get the recipe to update
          if (_recipeRepository == null) {
            debugPrint('Recipe repository not initialized, skipping recipe update');
            continue;
          }
          
          final recipe = await _recipeRepository!.getRecipeById(recipeId);
          if (recipe == null) {
            // Recipe was deleted, remove the entries
            for (final entryData in recipeEntries) {
              final entry = entryData['entry'];
              await repository.deleteEntry(entry.id);
            }
            continue;
          }

          // Get the current ingredients
          final List<Ingredient> currentIngredients = recipe.ingredients ?? [];
          bool ingredientsChanged = false;

          // Update each ingredient with its terms
          for (final entryData in recipeEntries) {
            final entry = entryData['entry'];
            final ingredientId = entryData['ingredientId'];

            // Find the ingredient in the current list
            final ingredientIndex = currentIngredients
                .indexWhere((ingredient) => ingredient.id == ingredientId);

            if (ingredientIndex >= 0) {
              // Get the original ingredient data to match with API results
              final originalData = json.decode(entry.ingredientData) as Map<String, dynamic>;
              final originalName = originalData['name'] as String;

              // Find terms in the API response
              if (results.containsKey(originalName)) {
                final terms = results[originalName]!;

                // Update the ingredient with new terms
                currentIngredients[ingredientIndex] =
                    currentIngredients[ingredientIndex].copyWith(terms: terms);
                ingredientsChanged = true;

                // Mark the entry as completed
                final completedEntry = entry.copyWith(
                  status: 'completed',
                  responseData: Value(json.encode({
                    'terms': terms.map((t) => t.toJson()).toList(),
                  })),
                );
                await repository.updateEntry(completedEntry);
              } else {
                // No terms found, mark as failed
                final failedEntry = entry.copyWith(
                  status: 'failed',
                  retryCount: entry.retryCount + 1,
                );
                await repository.updateEntry(failedEntry);
              }
            } else {
              // Ingredient was removed from the recipe
              await repository.deleteEntry(entry.id);
            }
          }

          // Update the recipe with the modified ingredients
          if (ingredientsChanged && _recipeRepository != null) {
            final updatedRecipe = recipe.copyWith(
              ingredients: Value(currentIngredients),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            );
            await _recipeRepository!.updateRecipe(updatedRecipe);
          }

        } catch (e) {
          debugPrint('Error processing ingredients for recipe $recipeId: $e');

          // Mark all entries for this recipe as pending with incremented retry count
          final recipeEntries = entryMap.values
              .where((e) => e['recipeId'] == recipeId)
              .toList();

          for (final entryData in recipeEntries) {
            final entry = entryData['entry'];
            final failedEntry = entry.copyWith(
              status: 'pending',
              retryCount: entry.retryCount + 1,
            );
            await repository.updateEntry(failedEntry);
          }
        }
      }

      // Schedule another processing cycle if needed
      if (hasReadyEntries) {
        _scheduleProcessing();
      } else {
        // Check for pending entries that need future processing
        final pending = await repository.getPendingEntries();
        int? minDelayMillis;
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        for (final entry in pending) {
          if (entry.status == 'failed') continue;

          final delayForEntry = baseDelay.inMilliseconds * (1 << entry.retryCount);
          final elapsed = currentTime - (entry.lastTryTimestamp ?? 0);
          final remaining = delayForEntry - elapsed;

          if (remaining > 0) {
            if (minDelayMillis == null || remaining < minDelayMillis) {
              minDelayMillis = remaining;
            }
          }
        }

        if (minDelayMillis != null && minDelayMillis > 0) {
          debugPrint('Scheduling next ingredient term processing in ${minDelayMillis}ms.');
          _scheduleProcessing(delay: Duration(milliseconds: minDelayMillis));
        }
      }

    } finally {
      _isProcessing = false;
    }
  }
}

// Create a provider that doesn't directly depend on recipeRepositoryProvider
// to break the circular dependency
final ingredientTermQueueManagerProvider = Provider<IngredientTermQueueManager>((ref) {
  final repository = ref.watch(ingredientTermQueueRepositoryProvider);
  // We'll get the recipe repository later via a setter to avoid circular dependency
  final recipeRepositoryUninitialized = null;
  final canonicalizer = ref.watch(ingredientCanonicalizerProvider);

  return IngredientTermQueueManager(
    repository: repository,
    // Pass null initially, will be set via recipeRepositoryProvider
    recipeRepository: recipeRepositoryUninitialized,
    canonicalizer: canonicalizer,
    db: appDb,
  );
});
