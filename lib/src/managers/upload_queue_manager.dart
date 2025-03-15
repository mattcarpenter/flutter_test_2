// lib/managers/upload_queue_manager.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/upload_queue_repository.dart';

// Stub function simulating an upload to Supabase Storage.
// Replace this with your actual upload logic.
Future<String> uploadImageToSupabase(File file) async {
  await Future.delayed(const Duration(seconds: 2));
  return 'https://your-supabase-bucket.com/${file.uri.pathSegments.last}';
}

class UploadQueueManager {
  final UploadQueueRepository repository;
  final AppDatabase db;
  bool _isProcessing = false;

  UploadQueueManager({
    required this.repository,
    required this.db,
  });

  /// Process pending entries.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Fetch all pending entries.
      final pendingEntries = await repository.getPendingEntries();

      for (final entry in pendingEntries) {
        // Update status to 'uploading'.
        final uploadingEntry = entry.copyWith(
          status: 'uploading',
          lastTryTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
        );
        await repository.updateEntry(uploadingEntry);

        try {
          // Resolve full file path.
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
          await _updateRecipesWithUploadedImage(entry.fileName, uploadedUrl);
        } catch (e) {
          // On error, increment retry count and set status back to pending.
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
    } finally {
      _isProcessing = false;
    }
  }

  /// Update recipes that contain an image with the given filename.
  /// (Pseudocode: implement according to your RecipeImageListConverter and recipe model.)
  Future<void> _updateRecipesWithUploadedImage(
      String fileName, String uploadedUrl) async {
    // 1. Query the recipes table for any recipe whose images JSON contains the given fileName.
    // 2. For each matching recipe:
    //    - Decode the JSON (via your RecipeImageListConverter)
    //    - Find the image with the given fileName and update its status to 'uploaded' and add the uploadedUrl.
    //    - Update the recipe record in the database.
    // Implementation details will depend on your JSON structure and conversion logic.
    debugPrint('Updating recipes with image $fileName to status "uploaded" with URL: $uploadedUrl');
  }
}


// Provider for the UploadQueueManager.
final uploadQueueManagerProvider = Provider<UploadQueueManager>((ref) {
  final repository = ref.watch(uploadQueueRepositoryProvider);
  return UploadQueueManager(repository: repository, db: appDb);
});
