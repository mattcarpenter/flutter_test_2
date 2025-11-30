import '../../models/paprika_recipe.dart';
import 'recipe_converter.dart';

/// Converts Paprika recipe format to ImportedRecipe
class PaprikaConverter extends RecipeConverter<PaprikaRecipe> {
  @override
  ImportedRecipe convert(PaprikaRecipe source) {
    return ImportedRecipe(
      title: source.name,
      description: source.description,
      rating: source.rating,
      language: null, // Paprika doesn't have language field
      servings: _parseServings(source.servings),
      prepTime: _parseTimeString(source.prepTime),
      cookTime: _parseTimeString(source.cookTime),
      totalTime: _parseTimeString(source.totalTime),
      source: source.source ?? source.sourceUrl,
      nutrition: source.nutritionalInfo,
      generalNotes: source.notes,
      createdAt: _parseCreatedDate(source.created),
      updatedAt: null, // Paprika doesn't have updatedAt
      pinned: false,
      tagNames: source.categories ?? [],
      folderNames: [], // User can choose to convert categories to folders at import time
      ingredients: _parseIngredients(source.ingredients ?? ''),
      steps: _parseDirections(source.directions ?? ''),
      images: _parseImages(source),
    );
  }

  /// Parse servings string like "4 servings" or "4" → int
  int? _parseServings(String? servings) {
    if (servings == null || servings.isEmpty) return null;

    // Try to extract first number from the string
    final match = RegExp(r'(\d+)').firstMatch(servings);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }

  /// Parse time strings like "15 mins", "1 hour", "1 hr 30 min" → minutes as int
  int? _parseTimeString(String? time) {
    if (time == null || time.isEmpty) return null;

    int totalMinutes = 0;

    // Match patterns like "1 hour", "30 mins", "1 hr", "30 min"
    final regex = RegExp(
      r'(\d+)\s*(h|hr|hour|hours|m|min|mins|minute|minutes)',
      caseSensitive: false,
    );

    final matches = regex.allMatches(time);

    for (final match in matches) {
      final value = int.tryParse(match.group(1)!) ?? 0;
      final unit = match.group(2)!.toLowerCase();

      if (unit.startsWith('h')) {
        // hour/hr/hours
        totalMinutes += value * 60;
      } else if (unit.startsWith('m')) {
        // min/mins/minute/minutes
        totalMinutes += value;
      }
    }

    return totalMinutes > 0 ? totalMinutes : null;
  }

  /// Parse created date string (ISO 8601 format) → Unix timestamp in milliseconds
  int? _parseCreatedDate(String? created) {
    if (created == null || created.isEmpty) return null;

    try {
      final date = DateTime.parse(created);
      return date.millisecondsSinceEpoch;
    } catch (e) {
      return null;
    }
  }

  /// Parse plain text ingredients (newline separated) into structured ingredients
  List<ImportedIngredient> _parseIngredients(String ingredients) {
    if (ingredients.isEmpty) return [];

    final lines = ingredients.split('\n');
    final result = <ImportedIngredient>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check if this is a section header (all caps or ends with colon)
      final isSection = _isSection(trimmed);

      result.add(ImportedIngredient(
        type: isSection ? 'section' : 'ingredient',
        name: trimmed,
        note: null,
        terms: null,
        isCanonicalised: false, // Paprika ingredients need canonicalization
        category: null,
      ));
    }

    return result;
  }

  /// Parse plain text directions into structured steps
  List<ImportedStep> _parseDirections(String directions) {
    if (directions.isEmpty) return [];

    // First try splitting by numbered steps (e.g., "1.", "2.")
    final numberedSteps = RegExp(r'^\s*\d+\.\s*', multiLine: true);
    final hasNumberedSteps = numberedSteps.hasMatch(directions);

    List<String> lines;
    if (hasNumberedSteps) {
      // Split by numbered steps
      lines = directions.split(numberedSteps).where((s) => s.trim().isNotEmpty).toList();
    } else {
      // Split by paragraphs (double newline) or single newline
      final paragraphs = directions.split(RegExp(r'\n\s*\n'));
      if (paragraphs.length > 1) {
        lines = paragraphs;
      } else {
        lines = directions.split('\n');
      }
    }

    final result = <ImportedStep>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check if this is a section header
      final isSection = _isSection(trimmed);

      result.add(ImportedStep(
        type: isSection ? 'section' : 'step',
        text: trimmed,
        note: null,
        timerDurationSeconds: null,
      ));
    }

    return result;
  }

  /// Determine if a line is likely a section header
  bool _isSection(String line) {
    // Consider it a section if:
    // 1. All uppercase (at least 3 chars)
    // 2. Ends with colon
    // 3. Short (less than 50 chars) and doesn't contain common ingredient/step words
    if (line.length >= 3 && line == line.toUpperCase() && line.contains(RegExp(r'[A-Z]'))) {
      return true;
    }

    if (line.endsWith(':') && line.length < 50) {
      return true;
    }

    return false;
  }

  /// Parse images from photo_data and photos array
  List<ImportedImage> _parseImages(PaprikaRecipe source) {
    final images = <ImportedImage>[];

    // Add main photo_data if available
    if (source.photoData != null && source.photoData!.isNotEmpty) {
      images.add(ImportedImage(
        isCover: true,
        data: source.photoData,
        publicUrl: null,
      ));
    }

    // Add additional photos from photos array
    if (source.photos != null) {
      for (final photo in source.photos!) {
        if (photo.data != null && photo.data!.isNotEmpty) {
          images.add(ImportedImage(
            isCover: false,
            data: photo.data,
            publicUrl: null,
          ));
        }
      }
    }

    return images;
  }
}
