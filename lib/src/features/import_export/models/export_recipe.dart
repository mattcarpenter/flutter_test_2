import 'package:json_annotation/json_annotation.dart';

part 'export_recipe.g.dart';

/// Model for Stockpot export format
/// Represents a recipe in the portable JSON export format
@JsonSerializable(includeIfNull: false)
class ExportRecipe {
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
  final bool? pinned;
  final List<String>? folderNames;
  final List<String>? tagNames;
  final List<ExportIngredient>? ingredients;
  final List<ExportStep>? steps;
  final List<ExportImage>? images;

  ExportRecipe({
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
    this.pinned,
    this.folderNames,
    this.tagNames,
    this.ingredients,
    this.steps,
    this.images,
  });

  factory ExportRecipe.fromJson(Map<String, dynamic> json) =>
      _$ExportRecipeFromJson(json);

  Map<String, dynamic> toJson() => _$ExportRecipeToJson(this);
}

/// Ingredient in the export format
/// Note: Export format excludes the id field and recipeId (sub-recipe reference)
/// as these are meaningless across accounts
@JsonSerializable(includeIfNull: false)
class ExportIngredient {
  final String type; // "ingredient" or "section"
  final String name;
  final String? note;
  final List<ExportIngredientTerm>? terms;
  final bool? isCanonicalised;
  final String? category;

  ExportIngredient({
    required this.type,
    required this.name,
    this.note,
    this.terms,
    this.isCanonicalised,
    this.category,
  });

  factory ExportIngredient.fromJson(Map<String, dynamic> json) =>
      _$ExportIngredientFromJson(json);

  Map<String, dynamic> toJson() => _$ExportIngredientToJson(this);
}

/// Ingredient term in the export format
@JsonSerializable(includeIfNull: false)
class ExportIngredientTerm {
  final String value;
  final String source; // "user", "ai", or "inferred"
  final int sort;

  ExportIngredientTerm({
    required this.value,
    required this.source,
    required this.sort,
  });

  factory ExportIngredientTerm.fromJson(Map<String, dynamic> json) =>
      _$ExportIngredientTermFromJson(json);

  Map<String, dynamic> toJson() => _$ExportIngredientTermToJson(this);
}

/// Step in the export format
/// Note: Export format excludes the id field as it's meaningless across accounts
@JsonSerializable(includeIfNull: false)
class ExportStep {
  final String type; // "step", "section", or "timer"
  final String text;
  final String? note;
  final int? timerDurationSeconds;

  ExportStep({
    required this.type,
    required this.text,
    this.note,
    this.timerDurationSeconds,
  });

  factory ExportStep.fromJson(Map<String, dynamic> json) =>
      _$ExportStepFromJson(json);

  Map<String, dynamic> toJson() => _$ExportStepToJson(this);
}

/// Image in the export format
/// Note: Export format excludes id and fileName fields
/// Uses either publicUrl (preferred) or base64 data as fallback
@JsonSerializable(includeIfNull: false)
class ExportImage {
  final bool? isCover;
  final String? data; // Base64 encoded image (fallback if no publicUrl)
  final String? publicUrl; // Supabase storage URL (preferred)

  ExportImage({
    this.isCover,
    this.data,
    this.publicUrl,
  });

  factory ExportImage.fromJson(Map<String, dynamic> json) =>
      _$ExportImageFromJson(json);

  Map<String, dynamic> toJson() => _$ExportImageToJson(this);
}
