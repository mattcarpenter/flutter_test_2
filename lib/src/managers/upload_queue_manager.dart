// lib/managers/upload_queue_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/upload_queue_repository.dart';

// Stub function simulating an upload to Supabase Storage.
// Replace with your actual upload logic.
Future<String> uploadImageToSupabase(File file) async {
  final supabase = Supabase.instance.client;
  final bucketName = 'recipe_images';

  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception("User is not logged in");
  }

  // Extract the original filename.
  String originalFilename = path.basename(file.path);

  // Define the file path using the user ID and original filename.
  final filePath = '${user.id}/$originalFilename';

  // Upload file to Supabase Storage.
  await supabase.storage.from(bucketName).upload(filePath, file);

  // Get the public URL.
  final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);

  return publicUrl;
}

class UploadQueueManager {
  final UploadQueueRepository repository;
  final RecipeRepository recipeRepository;
  final AppDatabase db;
  bool _isProcessing = false;
  Timer? _debounceTimer;
  // According to your docs, onConnectivityChanged emits a List<ConnectivityResult>.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Constants for backoff.
  static const Duration baseDelay = Duration(seconds: 2);
  static const int maxRetries = 5;

  UploadQueueManager({
    required this.repository,
    required this.db,
    required this.recipeRepository,
  }) {
    // Listen to connectivity changes.
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
          // If the list does NOT contain ConnectivityResult.none, assume connectivity.
          if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
            debugPrint('Connectivity regained, processing upload queue.');
            processQueue();
          }
        });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Adds a new image to the upload queue.
  Future<int> addToQueue({
    required String fileName,
    required String recipeId,
  }) async {

    final existingEntry = await repository.getEntryByFileName(fileName);
    if (existingEntry != null) {
      debugPrint('Entry for file $fileName already exists in the queue.');
      return 0;
    }

    final id = await repository.insertUploadQueueEntry(
      fileName: fileName,
      recipeId: recipeId,
    );
    _scheduleProcessing();
    return id;
  }

  /// Schedules a debounced call to process the queue.
  void _scheduleProcessing({Duration delay = const Duration(seconds: 2)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      processQueue();
    });
  }

  /// Process pending entries.
  Future<void> processQueue() async {
    // Check connectivity.
    final List<ConnectivityResult> connectivityResults =
    await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      debugPrint('Offline: upload queue processing deferred.');
      return;
    }

    // Check if the user is logged in.
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      debugPrint("User not logged in: skipping upload processing.");
      return;
    }

    if (_isProcessing) return;
    _isProcessing = true;
    debugPrint('Processing upload queue...');

    try {
      // Fetch all pending entries.
      final pendingEntries = await repository.getPendingEntries();
      final now = DateTime.now().millisecondsSinceEpoch;
      bool hasReadyEntries = false;

      for (final entry in pendingEntries) {
        // Compute exponential backoff delay: baseDelay * 2^(retryCount)
        final backoffMillis = baseDelay.inMilliseconds * (1 << entry.retryCount);
        final lastTry = entry.lastTryTimestamp ?? 0;
        // If this entry was tried recently and hasn't exceeded the backoff delay, skip it.
        if (now - lastTry < backoffMillis) {
          continue;
        }

        // If maximum retries exceeded, mark as failed and skip.
        if (entry.retryCount >= maxRetries) {
          final failedEntry = entry.copyWith(
            status: 'failed',
            lastTryTimestamp: Value(now),
          );
          await repository.updateEntry(failedEntry);
          continue;
        }

        hasReadyEntries = true;

        // Update status to 'uploading'.
        final uploadingEntry = entry.copyWith(
          status: 'uploading',
          lastTryTimestamp: Value(now),
        );
        await repository.updateEntry(uploadingEntry);

        try {
          // Resolve the full file path.
          final fullPath = await repository.resolveFullPath(entry.fileName);
          final file = File(fullPath);

          // Attempt to upload.
          final uploadedUrl = await uploadImageToSupabase(file);
          debugPrint('Upload succeeded: $uploadedUrl');

          // Mark entry as uploaded.
          final uploadedEntry = entry.copyWith(
            status: 'uploaded',
            lastTryTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
          );
          await repository.updateEntry(uploadedEntry);

          // Update recipes that reference this image.
          await recipeRepository.updateImageForRecipe(
            recipeId: entry.recipeId,
            fileName: entry.fileName,
            publicUrl: uploadedUrl,
          );

        } catch (e) {
          // On error, increment retry count and revert status to pending.
          final newRetryCount = entry.retryCount + 1;
          debugPrint('Upload failed for ${entry.fileName}: $e');
          final failedEntry = entry.copyWith(
            retryCount: newRetryCount,
            lastTryTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
            status: 'pending',
          );
          await repository.updateEntry(failedEntry);
        }
      }

      // If there are ready entries, we can trigger another immediate cycle.
      if (hasReadyEntries) {
        _scheduleProcessing();
      } else {
        // Otherwise, if there are pending entries that are not ready yet,
        // determine the minimum remaining delay and schedule processing accordingly.
        final pending = await repository.getPendingEntries();
        int? minDelayMillis;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        for (final entry in pending) {
          // Skip entries that are already failed.
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
          debugPrint('Scheduling next processing cycle in ${minDelayMillis}ms.');
          _scheduleProcessing(delay: Duration(milliseconds: minDelayMillis));
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}

// Riverpod Provider for the UploadQueueManager.
final uploadQueueManagerProvider = Provider<UploadQueueManager>((ref) {
  final repository = ref.watch(uploadQueueRepositoryProvider);
  final recipeRepository = ref.watch(recipeRepositoryProvider);
  return UploadQueueManager(repository: repository, db: appDb, recipeRepository: recipeRepository);
});
