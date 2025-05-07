// lib/src/managers/pantry_item_term_queue_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../database/database.dart';
import '../../database/models/pantry_item_terms.dart';
import '../../database/powersync.dart';
import '../repositories/pantry_item_term_queue_repository.dart';
import '../repositories/pantry_repository.dart';
import '../services/ingredient_canonicalization_service.dart';

class PantryItemTermQueueManager {
  final PantryItemTermQueueRepository repository;
  PantryRepository? _pantryRepository;
  final IngredientCanonicalizer canonicalizer;
  final AppDatabase db;

  bool _isProcessing = false;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _testMode = false;

  // Constants for backoff
  static const Duration baseDelay = Duration(seconds: 5);
  static const int maxRetries = 3;

  // Direct field access is sufficient, no need for getter/setter
  // but we keep the setter for clarity about the circular dependency resolution
  set pantryRepository(PantryRepository? repository) {
    _pantryRepository = repository;
  }
  
  // Setter for test mode
  set testMode(bool value) {
    _testMode = value;
  }

  PantryItemTermQueueManager({
    required this.repository,
    required PantryRepository? pantryRepository,
    required this.canonicalizer,
    required this.db,
    bool testMode = false,
  }) {
    _pantryRepository = pantryRepository;
    _testMode = testMode;
    
    // Only set up connectivity listener if not in test mode
    if (!_testMode) {
      try {
        _connectivitySubscription =
            Connectivity().onConnectivityChanged.listen((results) {
              // If we have connectivity, process the queue
              if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
                debugPrint('Connectivity regained, processing pantry item term queue.');
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

  /// Queue a pantry item for canonicalization
  Future<void> queuePantryItem({
    required String pantryItemId,
    required String name,
    List<PantryItemTerm>? existingTerms,
  }) async {
    // Skip if we already have terms (this is a manual override or previously processed)
    if (existingTerms != null && existingTerms.isNotEmpty) {
      return;
    }

    // Skip if pantry item has no name or empty name
    if (name.trim().isEmpty) {
      debugPrint('Skipping pantry item with empty name: $pantryItemId');
      return;
    }

    // Check if there's an existing entry for this pantry item
    final existingEntry = await repository.getEntryByPantryItemId(pantryItemId);
    if (existingEntry != null) {
      // If entry exists but failed previously, reset it to try again
      if (existingEntry.status == 'failed') {
        final resetEntry = existingEntry.copyWith(
          status: 'pending',
          retryCount: const Value(0),
          requestTimestamp: DateTime.now().millisecondsSinceEpoch,
          lastTryTimestamp: const Value(null),
        );
        await repository.updateEntry(resetEntry);
      }
      return;
    }

    // Add new entry to the queue
    await repository.insertQueueEntry(
      pantryItemId: pantryItemId,
      name: name,
    );

    // Schedule processing
    _scheduleProcessing();
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
          debugPrint('Offline: pantry item term queue processing deferred.');
          return;
        }
      } catch (e) {
        debugPrint('Error checking connectivity. Assuming online: $e');
        // Continue processing in case of connectivity check errors
      }
    }

    if (_isProcessing) return;
    _isProcessing = true;
    debugPrint('Processing pantry item term queue...');

    try {
      // Fetch all pending entries
      final pendingEntries = await repository.getPendingEntries();
      final now = DateTime.now().millisecondsSinceEpoch;
      bool hasReadyEntries = false;

      // Group entries by pantry item for batch processing
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

        // Parse pantry item data
        final Map<String, dynamic> pantryItemData =
            json.decode(entry.pantryItemData) as Map<String, dynamic>;

        // Skip pantry items with missing or empty names
        final name = pantryItemData['name'];
        if (name == null || (name is String && name.trim().isEmpty)) {
          debugPrint('Skipping pantry item with empty name in queue entry ${entry.id}');
          await repository.deleteEntry(entry.id);
          continue;
        }

        // Track the entry
        entryMap[entry.id] = {
          'entry': entry,
          'pantryItemId': entry.pantryItemId,
          'data': pantryItemData,
        };

        // Mark as processing
        final processingEntry = entry.copyWith(
          status: 'processing',
          lastTryTimestamp: Value(now),
        );
        await repository.updateEntry(processingEntry);
      }

      // Process each pantry item
      for (final entryId in entryMap.keys) {
        final entryData = entryMap[entryId]!;
        final entry = entryData['entry'] as PantryItemTermQueueEntry;
        final pantryItemId = entryData['pantryItemId'] as String;
        final pantryItemData = entryData['data'] as Map<String, dynamic>;
        
        try {
          // Call the canonicalization API - use the same API as ingredients
          // but without unit and quantity as per requirements
          final results = await canonicalizer.canonicalizeIngredients([pantryItemData]);

          // Check if we got results for this pantry item
          final name = pantryItemData['name'] as String;
          if (results.terms.containsKey(name)) {
            final ingredientTerms = results.terms[name]!;
            
            // Convert IngredientTerm to PantryItemTerm
            final terms = ingredientTerms.map((term) => PantryItemTerm(
              value: term.value,
              source: term.source,
              sort: term.sort,
            )).toList();

            // Update the pantry item with the new terms
            if (_pantryRepository != null) {
              await _pantryRepository!.updateItem(
                id: pantryItemId,
                terms: terms,
              );
            } else {
              debugPrint('Pantry repository not initialized, skipping pantry item update');
            }

            // Mark the entry as completed
            final completedEntry = entry.copyWith(
              status: 'completed',
              responseData: Value(json.encode({
                'terms': terms.map((t) => {
                  'value': t.value,
                  'source': t.source,
                  'sort': t.sort,
                }).toList(),
              })),
            );
            await repository.updateEntry(completedEntry);
          } else {
            // No terms found, mark as failed
            final failedEntry = entry.copyWith(
              status: 'failed',
              retryCount: Value(entry.retryCount != null ? entry.retryCount! + 1 : 1),
            );
            await repository.updateEntry(failedEntry);
          }
        } catch (e) {
          debugPrint('Error processing pantry item $pantryItemId: $e');

          // Mark entry as pending with incremented retry count
          final failedEntry = entry.copyWith(
            status: 'pending',
            retryCount: Value(entry.retryCount != null ? entry.retryCount! + 1 : 1),
          );
          await repository.updateEntry(failedEntry);
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

          // Handle potentially null retryCount by defaulting to 0
          final retryCount = entry.retryCount ?? 0;
          final delayForEntry = baseDelay.inMilliseconds * (1 << retryCount);
          final elapsed = currentTime - (entry.lastTryTimestamp ?? 0);
          final remaining = delayForEntry - elapsed;

          if (remaining > 0) {
            if (minDelayMillis == null || remaining < minDelayMillis) {
              minDelayMillis = remaining;
            }
          }
        }

        if (minDelayMillis != null && minDelayMillis > 0) {
          debugPrint('Scheduling next pantry item term processing in ${minDelayMillis}ms.');
          _scheduleProcessing(delay: Duration(milliseconds: minDelayMillis));
        }
      }

    } finally {
      _isProcessing = false;
    }
  }
}

// Create a provider that doesn't directly depend on pantryRepositoryProvider
// to break the circular dependency
final pantryItemTermQueueManagerProvider = Provider<PantryItemTermQueueManager>((ref) {
  final repository = ref.watch(pantryItemTermQueueRepositoryProvider);
  // We'll get the pantry repository later via a setter to avoid circular dependency
  const pantryRepositoryUninitialized = null;
  final canonicalizer = ref.watch(ingredientCanonicalizerProvider);
  
  // Determine if we're in test mode by checking environment variables or other means
  // For now we'll default to false, but you can override this with the setter
  const bool isTestMode = false;

  return PantryItemTermQueueManager(
    repository: repository,
    // Pass null initially, will be set via pantryRepositoryProvider
    pantryRepository: pantryRepositoryUninitialized,
    canonicalizer: canonicalizer,
    db: appDb,
    testMode: isTestMode,
  );
});