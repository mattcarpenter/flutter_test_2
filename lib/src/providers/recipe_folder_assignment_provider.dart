// lib/providers/recipe_folder_assignment_provider.dart

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';

import '../../database/powersync.dart';
import '../repositories/recipe_folder_assignment_repository.dart';

// Provider for the AppDatabase (adjust as needed to match your setup).
final databaseProvider = Provider<AppDatabase>((ref) {
  // Replace 'appDb' with your actual global database instance.
  return appDb;
});

class RecipeFolderAssignmentNotifier extends StateNotifier<AsyncValue<List<RecipeFolderAssignmentEntry>>> {
  final RecipeFolderAssignmentRepository _repository;
  late final StreamSubscription<List<RecipeFolderAssignmentEntry>> _subscription;

  RecipeFolderAssignmentNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchAssignments().listen(
          (assignments) {
        state = AsyncValue.data(assignments);
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

  /// Adds a new folder assignment.
  Future<void> addAssignment({
    required String recipeId,
    required String folderId,
    required String userId,
    String? householdId,
    int? createdAt,
  }) async {
    try {
      final assignment = RecipeFolderAssignmentsCompanion.insert(
        recipeId: recipeId,
        folderId: folderId,
        userId: userId,
        householdId: Value(householdId),
        createdAt: Value(createdAt),
      );
      await _repository.addAssignment(assignment);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Deletes a folder assignment by its [id].
  Future<void> deleteAssignment(String id) async {
    try {
      await _repository.deleteAssignment(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the RecipeFolderAssignmentNotifier.
// This notifier exposes an AsyncValue<List<RecipeFolderAssignmentEntry>>.
final recipeFolderAssignmentNotifierProvider =
StateNotifierProvider<RecipeFolderAssignmentNotifier, AsyncValue<List<RecipeFolderAssignmentEntry>>>((ref) {
  final repository = ref.watch(recipeFolderAssignmentRepositoryProvider);
  return RecipeFolderAssignmentNotifier(repository);
});
