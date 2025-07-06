import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../managers/ingredient_term_queue_manager.dart';
import '../managers/upload_queue_manager.dart';
import '../repositories/recipe_repository.dart';

/// This provider initializes and wires up the services that have circular dependencies.
/// It handles connecting the RecipeRepository and IngredientTermQueueManager without
/// creating dependency cycles in the providers.
final dependencySetupProvider = Provider<void>((ref) {
  // Access both objects
  final recipeRepository = ref.read(recipeRepositoryProvider);
  final ingredientTermManager = ref.read(ingredientTermQueueManagerProvider);
  
  // Connect them bidirectionally
  ingredientTermManager.recipeRepository = recipeRepository;
  recipeRepository.ingredientTermQueueManager = ingredientTermManager;
  
  return;
});

/// This provider initializes and starts the background services that
/// need to run whenever the app is active. It processes both the
/// upload queue for images and the ingredient term queue.
final appServicesProvider = Provider<void>((ref) {
  // First ensure the circular dependencies are resolved
  ref.watch(dependencySetupProvider);
  
  // Access the managers to ensure they're created
  final uploadManager = ref.watch(uploadQueueManagerProvider);
  final ingredientTermManager = ref.watch(ingredientTermQueueManagerProvider);
  
  // Start processing queues
  uploadManager.processQueue();
  ingredientTermManager.processQueue();
  
  // Household data migration is now handled automatically by PostgreSQL triggers
  
  // Return void
  return;
});