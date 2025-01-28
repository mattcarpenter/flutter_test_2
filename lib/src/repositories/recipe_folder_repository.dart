import '../models/recipe_folder.dart';

class RecipeFolderRepository {
  // In-memory storage for recipe folders
  final List<RecipeFolder> _folders = [];

  // Add a new folder
  Future<void> addFolder(RecipeFolder folder) async {
    // Generate a unique ID for the folder
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final folderWithId = RecipeFolder(
      id: uniqueId, // Assign generated ID
      name: folder.name,
      parentId: folder.parentId,
    );
    _folders.add(folderWithId);
  }

  // Fetch all folders
  Future<List<RecipeFolder>> getAllFolders() async {
    return List.unmodifiable(_folders); // Return an immutable copy of the list
  }

  // Fetch a folder by ID
  Future<RecipeFolder?> getFolderById(String id) async {
    try {
      return _folders.firstWhere((folder) => folder.id == id);
    } catch (e) {
      return null; // Return null if no folder matches
    }
  }

  // Delete a folder
  Future<void> deleteFolder(String id) async {
    _folders.removeWhere((folder) => folder.id == id);
  }
}
