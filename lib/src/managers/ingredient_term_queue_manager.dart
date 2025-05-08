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
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/converter_provider.dart';
import '../repositories/ingredient_term_queue_repository.dart';
import '../repositories/recipe_repository.dart';
import '../services/ingredient_canonicalization_service.dart';

class IngredientTermQueueManager {
  final IngredientTermQueueRepository repository;
  RecipeRepository? _recipeRepository;
  final IngredientCanonicalizer canonicalizer;
  final AppDatabase db;
  final ConverterNotifier converterNotifier;

  bool _isProcessing = false;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _testMode = false;

  // Constants for backoff
  static const Duration baseDelay = Duration(seconds: 5);
  static const int maxRetries = 3;

  // Direct field access is sufficient, no need for getter/setter
  // but we keep the setter for clarity about the circular dependency resolution
  set recipeRepository(RecipeRepository? repository) {
    _recipeRepository = repository;
  }

  // Setter for test mode
  set testMode(bool value) {
    _testMode = value;
  }

  IngredientTermQueueManager({
    required this.repository,
    required RecipeRepository? recipeRepository,
    required this.canonicalizer,
    required this.db,
    required this.converterNotifier,
    bool testMode = false,
  }) {
    _recipeRepository = recipeRepository;
    _testMode = testMode;

    // Only set up connectivity listener if not in test mode
    if (!_testMode) {
      try {
        _connectivitySubscription =
            Connectivity().onConnectivityChanged.listen((results) {
              // If we have connectivity, process the queue
              if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
                debugPrint('Connectivity regained, processing ingredient term queue.');
                processQueue();
              }
            });
      } catch (e) {
        debugPrint('Warning: Could not initialize connectivity listener: $e');
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Process converters from the API response
  Future<void> _processConverters(Map<String, ConverterData> converters, String? householdId) async {
    if (converters.isEmpty) return;

    debugPrint('Processing ${converters.length} converters from API response');

    // Get the current user ID from Supabase
    final userId = Supabase.instance.client.auth.currentSession?.user.id;

    for (final entry in converters.entries) {
      final converter = entry.value;

      // Check if this converter already exists
      final exists = await converterNotifier.converterExists(
        term: converter.term,
        fromUnit: converter.fromUnit,
        toBaseUnit: converter.toBaseUnit,
      );

      // Only add if it doesn't exist
      if (!exists) {
        debugPrint('Adding new converter for ${converter.term} (${converter.fromUnit} to ${converter.toBaseUnit})');
        await converterNotifier.addConverter(
          term: converter.term,
          fromUnit: converter.fromUnit,
          toBaseUnit: converter.toBaseUnit,
          conversionFactor: converter.conversionFactor,
          isApproximate: converter.isApproximate,
          notes: converter.notes,
          userId: userId,
          householdId: householdId,
        );
      } else {
        debugPrint('Converter already exists for ${converter.term} (${converter.fromUnit} to ${converter.toBaseUnit})');
      }
    }
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

    // Skip if ingredient has no name or empty name
    if (ingredient.name == null || ingredient.name!.trim().isEmpty) {
      debugPrint('Skipping ingredient with empty name in recipe $recipeId');
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

    // Filter out invalid ingredients
    final validIngredients = ingredients.where((ingredient) =>
      ingredient.type == 'ingredient' &&
      ingredient.name != null &&
      ingredient.name!.trim().isNotEmpty
    ).toList();

    // Add queue entries for each valid ingredient
    for (final ingredient in validIngredients) {
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
    // Skip connectivity checks in test mode
    if (!_testMode) {
      try {
        // Check connectivity
        final List<ConnectivityResult> connectivityResults =
            await Connectivity().checkConnectivity();
        if (connectivityResults.contains(ConnectivityResult.none)) {
          debugPrint('Offline: ingredient term queue processing deferred.');
          return;
        }
      } catch (e) {
        debugPrint('Error checking connectivity. Assuming online: $e');
        // Continue processing in case of connectivity check errors
      }
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
        // Handle potentially null retryCount by defaulting to 0
        // This handles legacy entries that might have null values
        final retryCount = entry.retryCount ?? 0;

        // Calculate exponential backoff
        final backoffMillis = baseDelay.inMilliseconds * (1 << retryCount);
        final lastTry = entry.lastTryTimestamp ?? 0;

        // Skip if backoff period hasn't elapsed
        if (now - lastTry < backoffMillis) {
          continue;
        }

        // Skip if max retries exceeded
        if (retryCount >= maxRetries) {
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

        // Skip ingredients with missing or empty names
        final name = ingredientData['name'];
        if (name == null || (name is String && name.trim().isEmpty)) {
          debugPrint('Skipping ingredient with empty name in queue entry ${entry.id}');
          await repository.deleteEntry(entry.id);
          continue;
        }

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

          // Process any converters returned from the API
          if (results.converters.isNotEmpty) {
            // Get the recipe to determine household
            final recipe = await _recipeRepository?.getRecipeById(recipeId);
            final householdId = recipe?.householdId;

            // Process the converters
            await _processConverters(results.converters, householdId);
          }

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
              if (results.terms.containsKey(originalName)) {
                final terms = results.terms[originalName]!;

                // Update the ingredient with new terms
                currentIngredients[ingredientIndex] =
                    currentIngredients[ingredientIndex].copyWith(terms: terms);
                ingredientsChanged = true;

                // Mark the entry as completed
                final completedEntry = entry.copyWith(
                  status: 'completed',
                  responseData: Value(json.encode({
                    'terms': terms.map((t) => t.toJson()).toList(),
                    'converters': results.converters.containsKey(originalName)
                        ? _convertToJson(results.converters[originalName]!)
                        : null,
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

  /// Convert ConverterData to a JSON map
  Map<String, dynamic> _convertToJson(ConverterData converter) {
    return {
      'term': converter.term,
      'fromUnit': converter.fromUnit,
      'toBaseUnit': converter.toBaseUnit,
      'conversionFactor': converter.conversionFactor,
      'isApproximate': converter.isApproximate,
      'notes': converter.notes,
    };
  }
}

// Create a provider that doesn't directly depend on recipeRepositoryProvider
// to break the circular dependency
final ingredientTermQueueManagerProvider = Provider<IngredientTermQueueManager>((ref) {
  final repository = ref.watch(ingredientTermQueueRepositoryProvider);
  // We'll get the recipe repository later via a setter to avoid circular dependency
  final recipeRepositoryUninitialized = null;
  final canonicalizer = ref.watch(ingredientCanonicalizerProvider);
  final converterNotifier = ref.watch(convertersProvider.notifier);

  // Determine if we're in test mode by checking environment variables or other means
  // For now we'll default to false, but you can override this with the setter
  final bool isTestMode = false;

  return IngredientTermQueueManager(
    repository: repository,
    // Pass null initially, will be set via recipeRepositoryProvider
    recipeRepository: recipeRepositoryUninitialized,
    canonicalizer: canonicalizer,
    db: appDb,
    converterNotifier: converterNotifier,
    testMode: isTestMode,
  );
});
