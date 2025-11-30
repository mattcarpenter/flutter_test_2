/// Result of converting a recipe, ready for import
class ImportedRecipe {
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
  final List<String> tagNames; // Tags to create/resolve by name
  final List<String> folderNames; // Folders to create/resolve by name
  final List<ImportedIngredient> ingredients;
  final List<ImportedStep> steps;
  final List<ImportedImage> images;

  ImportedRecipe({
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
    this.pinned = false,
    this.tagNames = const [],
    this.folderNames = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.images = const [],
  });
}

/// Imported ingredient ready for database insertion
class ImportedIngredient {
  final String type;
  final String name;
  final String? note;
  final List<ImportedTerm>? terms;
  final bool isCanonicalised;
  final String? category;

  ImportedIngredient({
    required this.type,
    required this.name,
    this.note,
    this.terms,
    this.isCanonicalised = false,
    this.category,
  });
}

/// Imported term for ingredient matching
class ImportedTerm {
  final String value;
  final String source;
  final int sort;

  ImportedTerm({
    required this.value,
    required this.source,
    required this.sort,
  });
}

/// Imported step ready for database insertion
class ImportedStep {
  final String type;
  final String text;
  final String? note;
  final int? timerDurationSeconds;

  ImportedStep({
    required this.type,
    required this.text,
    this.note,
    this.timerDurationSeconds,
  });
}

/// Imported image ready for download/storage
class ImportedImage {
  final bool isCover;
  final String? data; // Base64 image data
  final String? publicUrl; // Public URL if available

  ImportedImage({
    this.isCover = false,
    this.data,
    this.publicUrl,
  });
}

/// Base converter interface
abstract class RecipeConverter<T> {
  ImportedRecipe convert(T source);

  List<ImportedRecipe> convertAll(List<T> sources) {
    return sources.map(convert).toList();
  }
}
