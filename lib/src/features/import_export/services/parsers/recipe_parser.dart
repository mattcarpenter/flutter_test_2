import 'dart:io';

/// Base interface for parsing recipe archives
abstract class RecipeParser<T> {
  /// File extensions this parser handles
  List<String> get supportedExtensions;

  /// Parse archive and extract recipes
  Future<List<T>> parseArchive(File archive);

  /// Parse a single recipe from bytes
  T parseRecipe(List<int> bytes, String filename);
}
