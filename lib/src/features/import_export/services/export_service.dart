import 'dart:io';
import 'dart:convert';
import 'dart:math' show min;
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/export_recipe.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/steps.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../../database/models/ingredient_terms.dart';

/// Service for exporting recipes to Stockpot ZIP format
class ExportService {
  /// Export recipes to a ZIP file
  /// Returns the File path of the created archive
  ///
  /// The archive will be named: stockpot_export_YYYYMMDD_HHMMSS.zip
  /// Each recipe becomes a JSON file: {sanitized-title}-{short-hash}.json
  ///
  /// [outputDirectory] - Optional directory for the output file. If not provided,
  /// uses the app's documents directory. Useful for testing.
  Future<File> exportRecipes({
    required List<RecipeExportData> recipes,
    void Function(int current, int total)? onProgress,
    Directory? outputDirectory,
  }) async {
    // Create archive
    final archive = Archive();

    // Convert each recipe to ExportRecipe and add to archive
    for (var i = 0; i < recipes.length; i++) {
      final recipeData = recipes[i];

      // Report progress
      onProgress?.call(i + 1, recipes.length);

      // Convert to ExportRecipe
      final exportRecipe = _convertToExportRecipe(recipeData);

      // Serialize to JSON
      final jsonString = JsonEncoder.withIndent('  ').convert(exportRecipe.toJson());
      final jsonBytes = utf8.encode(jsonString);

      // Generate unique filename
      final filename = _generateFilename(recipeData.title, i);

      // Add to archive
      final file = ArchiveFile(filename, jsonBytes.length, jsonBytes);
      archive.addFile(file);
    }

    // Encode archive to ZIP bytes
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // Write to output directory (defaults to app documents directory)
    final directory = outputDirectory ?? await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'stockpot_export_$timestamp.zip';
    final file = File('${directory.path}/$filename');

    await file.writeAsBytes(zipBytes);

    return file;
  }

  /// Convert RecipeExportData to ExportRecipe model
  ExportRecipe _convertToExportRecipe(RecipeExportData data) {
    return ExportRecipe(
      title: data.title,
      description: data.description,
      rating: data.rating,
      language: data.language,
      servings: data.servings,
      prepTime: data.prepTime,
      cookTime: data.cookTime,
      totalTime: data.totalTime,
      source: data.source,
      nutrition: data.nutrition,
      generalNotes: data.generalNotes,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      pinned: data.pinned,
      folderNames: data.folderNames.isNotEmpty ? data.folderNames : null,
      tagNames: data.tagNames.isNotEmpty ? data.tagNames : null,
      ingredients: data.ingredients?.map(_convertIngredient).toList(),
      steps: data.steps?.map(_convertStep).toList(),
      images: data.images?.map(_convertImage).toList(),
    );
  }

  /// Convert database Ingredient to ExportIngredient
  ExportIngredient _convertIngredient(Ingredient ingredient) {
    return ExportIngredient(
      type: ingredient.type,
      name: ingredient.name,
      note: ingredient.note,
      terms: ingredient.terms?.map(_convertTerm).toList(),
      isCanonicalised: ingredient.isCanonicalised,
      category: ingredient.category,
    );
  }

  /// Convert database IngredientTerm to ExportIngredientTerm
  ExportIngredientTerm _convertTerm(IngredientTerm term) {
    return ExportIngredientTerm(
      value: term.value,
      source: term.source,
      sort: term.sort,
    );
  }

  /// Convert database Step to ExportStep
  ExportStep _convertStep(Step step) {
    return ExportStep(
      type: step.type,
      text: step.text,
      note: step.note,
      timerDurationSeconds: step.timerDurationSeconds,
    );
  }

  /// Convert database RecipeImage to ExportImage
  /// For now, only includes publicUrl (image processing can be added later)
  ExportImage _convertImage(RecipeImage image) {
    return ExportImage(
      isCover: image.isCover,
      publicUrl: image.publicUrl,
      // TODO: Add base64 encoding of local images when publicUrl is null
      // This would require reading the local file, resizing to 1200px max width,
      // compressing as JPEG at 85% quality, and base64 encoding
      data: null,
    );
  }

  /// Generate unique filename for recipe
  /// Format: {sanitized-title}-{short-hash}.json
  String _generateFilename(String title, int index) {
    final sanitized = _sanitizeFilename(title);
    final hashString = title.hashCode.abs().toRadixString(16);
    final hash = hashString.substring(0, min(6, hashString.length)).padLeft(6, '0');
    return '$sanitized-$hash.json';
  }

  /// Sanitize title for use as filename
  /// - Converts to lowercase
  /// - Removes special characters
  /// - Replaces spaces with hyphens
  /// - Limits to 50 characters
  String _sanitizeFilename(String title) {
    if (title.isEmpty) {
      return 'recipe';
    }

    final sanitized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    return sanitized.substring(0, min(50, sanitized.length));
  }
}

/// Data needed to export a recipe
/// Contains all recipe fields with folder/tag names already resolved
class RecipeExportData {
  final String id;
  final String title;
  final String? description;
  final int? rating;
  final String? language;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final int? totalTime;
  final String? source;
  final String? nutrition;
  final String? generalNotes;
  final int? createdAt;
  final int? updatedAt;
  final bool pinned;
  final List<String> folderNames;  // Already resolved names
  final List<String> tagNames;     // Already resolved names
  final List<Ingredient>? ingredients;
  final List<Step>? steps;
  final List<RecipeImage>? images;

  RecipeExportData({
    required this.id,
    required this.title,
    this.description,
    this.rating,
    this.language,
    this.servings,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.source,
    this.nutrition,
    this.generalNotes,
    this.createdAt,
    this.updatedAt,
    required this.pinned,
    required this.folderNames,
    required this.tagNames,
    this.ingredients,
    this.steps,
    this.images,
  });
}
