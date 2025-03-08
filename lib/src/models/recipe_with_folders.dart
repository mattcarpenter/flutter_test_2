// lib/models/recipe_with_folders.dart

import '../../database/database.dart';

class RecipeFolderDetail {
  final RecipeFolderAssignmentEntry assignment;
  final RecipeFolderEntry folder; // Contains folder details such as folder name, etc.

  RecipeFolderDetail({
    required this.assignment,
    required this.folder,
  });
}

class RecipeWithFolders {
  final RecipeEntry recipe;
  final List<RecipeFolderDetail> folderDetails;

  RecipeWithFolders({
    required this.recipe,
    required this.folderDetails,
  });
}
