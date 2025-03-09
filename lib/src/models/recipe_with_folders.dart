// lib/models/recipe_with_folders.dart

import '../../database/database.dart';

class RecipeWithFolders {
  final RecipeEntry recipe;
  final List<RecipeFolderEntry> folders;

  RecipeWithFolders({
    required this.recipe,
    required this.folders,
  });
}
