import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/shopping_list_item_term_queue_repository.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/ingredient_canonicalization_service.dart';

class ShoppingListItemTermQueueManager {
  final ShoppingListItemTermQueueRepository repository;
  ShoppingListRepository? _shoppingListRepository;
  final IngredientCanonicalizer canonicalizer;
  final AppDatabase db;

  bool _isProcessing = false;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _testMode = false;

  // Constants for backoff
  static const Duration baseDelay = Duration(seconds: 5);
  static const int maxRetries = 3;

  set shoppingListRepository(ShoppingListRepository? repository) {
    _shoppingListRepository = repository;
  }

  set testMode(bool value) {
    _testMode = value;
  }

  ShoppingListItemTermQueueManager({
    required this.repository,
    required ShoppingListRepository? shoppingListRepository,
    required this.canonicalizer,
    required this.db,
    bool testMode = false,
  }) {
    _shoppingListRepository = shoppingListRepository;
    _testMode = testMode;

    // Only set up connectivity listener if not in test mode
    if (!_testMode) {
      try {
        _connectivitySubscription =
            Connectivity().onConnectivityChanged.listen((results) {
              // If we have connectivity, process the queue
              if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
                debugPrint('Connectivity regained, processing shopping list item term queue.');
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

  /// Queue a shopping list item for canonicalization
  Future<void> queueShoppingListItem({
    required String shoppingListItemId,
    required String name,
    String? userId,
    double? amount,
    String? unit,
  }) async {
    // Skip if in test mode to avoid race conditions
    if (_testMode) {
      return;
    }

    // Skip if shopping list item has no name or empty name
    if (name.trim().isEmpty) {
      debugPrint('Skipping shopping list item with empty name: $shoppingListItemId');
      return;
    }

    // Check if there's an existing entry for this shopping list item
    final existingEntry = await repository.getEntryByShoppingListItemId(shoppingListItemId);
    if (existingEntry != null) {
      // If entry exists but failed previously, reset it to try again
      if (existingEntry.status == 'failed') {
        await repository.updateEntry(
          shoppingListItemId: shoppingListItemId,
          status: 'pending',
          retryCount: 0,
          error: null,
        );
      } else {
        // Entry already exists and is being processed
        return;
      }
    } else {
      // Add new entry to queue
      await repository.addEntry(
        shoppingListItemId: shoppingListItemId,
        name: name,
        userId: userId,
        amount: amount,
        unit: unit,
      );
    }

    // Debounce the processing to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      processQueue();
    });
  }

  /// Process the queue of pending shopping list items
  Future<void> processQueue() async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      // Get all pending entries
      final pendingEntries = await repository.watchPendingEntries().first;
      
      if (pendingEntries.isEmpty) {
        debugPrint('No pending shopping list items to process');
        return;
      }

      debugPrint('Processing ${pendingEntries.length} pending shopping list items');

      // Group entries by user for batch processing
      final entriesByUser = <String?, List<ShoppingListItemTermQueueEntry>>{};
      for (final entry in pendingEntries) {
        final userId = entry.userId;
        entriesByUser.putIfAbsent(userId, () => []).add(entry);
      }

      // Process each user's entries
      for (final userEntries in entriesByUser.values) {
        await _processUserEntries(userEntries);
      }

      // Check for retryable entries
      final retryableEntries = await repository.getRetryableEntries(maxRetries);
      if (retryableEntries.isNotEmpty) {
        debugPrint('Found ${retryableEntries.length} retryable entries');
        for (final entry in retryableEntries) {
          await _processEntry(entry, isRetry: true);
        }
      }
    } catch (e) {
      debugPrint('Error processing shopping list item term queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processUserEntries(List<ShoppingListItemTermQueueEntry> entries) async {
    // Process in batches of 10
    const batchSize = 10;
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = entries.skip(i).take(batchSize).toList();
      await _processBatch(batch);
    }
  }

  Future<void> _processBatch(List<ShoppingListItemTermQueueEntry> batch) async {
    try {
      // Update status to processing
      for (final entry in batch) {
        await repository.updateEntry(
          shoppingListItemId: entry.shoppingListItemId,
          status: 'processing',
        );
      }

      // Prepare ingredients for canonicalization
      final ingredients = batch.map((entry) => {
        'name': entry.name,
        if (entry.amount != null) 'quantity': entry.amount,
        if (entry.unit != null) 'unit': entry.unit,
      }).toList();

      // Call canonicalization API
      final result = await canonicalizer.canonicalizeIngredients(ingredients);

      // Process results
      for (var i = 0; i < batch.length; i++) {
        final entry = batch[i];
        final originalName = entry.name;
        
        // Get terms and category for this ingredient
        final terms = result.terms[originalName];
        final category = result.categories[originalName];

        if (terms != null && terms.isNotEmpty) {
          // Convert IngredientTerm objects to strings for storage
          final termStrings = terms.map((t) => t.value).toList();
          
          // Update shopping list item with terms and category
          await _shoppingListRepository?.updateItem(
            itemId: entry.shoppingListItemId,
            terms: termStrings,
            category: category,
          );

          // Mark as completed
          await repository.updateEntry(
            shoppingListItemId: entry.shoppingListItemId,
            status: 'completed',
          );

          debugPrint('Successfully canonicalized shopping list item: $originalName -> ${termStrings.join(', ')}');
        } else {
          // No terms returned, mark as failed
          await repository.updateEntry(
            shoppingListItemId: entry.shoppingListItemId,
            status: 'failed',
            error: 'No terms returned from canonicalization',
            retryCount: entry.retryCount + 1,
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing batch: $e');
      
      // Mark all entries in batch as failed
      for (final entry in batch) {
        await repository.updateEntry(
          shoppingListItemId: entry.shoppingListItemId,
          status: 'failed',
          error: e.toString(),
          retryCount: entry.retryCount + 1,
        );
      }
    }
  }

  Future<void> _processEntry(ShoppingListItemTermQueueEntry entry, {bool isRetry = false}) async {
    try {
      // Update status to processing
      await repository.updateEntry(
        shoppingListItemId: entry.shoppingListItemId,
        status: 'processing',
      );

      // Call canonicalization API for single item
      final result = await canonicalizer.canonicalizeSingleIngredient(
        entry.name,
        quantity: entry.amount,
        unit: entry.unit,
      );

      if (result != null) {
        final terms = result.terms[entry.name];
        final category = result.categories[entry.name];

        if (terms != null && terms.isNotEmpty) {
          // Convert IngredientTerm objects to strings
          final termStrings = terms.map((t) => t.value).toList();
          
          // Update shopping list item
          await _shoppingListRepository?.updateItem(
            itemId: entry.shoppingListItemId,
            terms: termStrings,
            category: category,
          );

          // Mark as completed
          await repository.updateEntry(
            shoppingListItemId: entry.shoppingListItemId,
            status: 'completed',
          );

          debugPrint('Successfully canonicalized shopping list item: ${entry.name} -> ${termStrings.join(', ')}');
        } else {
          throw Exception('No terms returned from canonicalization');
        }
      } else {
        throw Exception('Canonicalization returned null');
      }
    } catch (e) {
      debugPrint('Error processing entry ${entry.shoppingListItemId}: $e');
      
      final newRetryCount = entry.retryCount + 1;
      final shouldRetryLater = newRetryCount < maxRetries;
      
      await repository.updateEntry(
        shoppingListItemId: entry.shoppingListItemId,
        status: 'failed',
        error: e.toString(),
        retryCount: newRetryCount,
      );

      if (shouldRetryLater && !isRetry) {
        // Schedule retry with exponential backoff
        final delay = baseDelay * (1 << entry.retryCount);
        Timer(delay, () async {
          await _processEntry(entry, isRetry: true);
        });
      }
    }
  }

  /// Remove a shopping list item from the queue
  Future<void> removeFromQueue(String shoppingListItemId) async {
    await repository.deleteEntry(shoppingListItemId);
  }

  /// Reset all failed entries to pending
  Future<void> resetFailedEntries() async {
    await repository.resetFailedEntries();
    processQueue();
  }
}