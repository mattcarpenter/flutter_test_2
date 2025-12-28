import 'recipe_preview.dart';

/// Represents an ingredient extracted from recipe text
class ExtractedIngredient {
  final String name;
  final String type; // 'ingredient' or 'section'

  const ExtractedIngredient({
    required this.name,
    required this.type,
  });

  factory ExtractedIngredient.fromJson(Map<String, dynamic> json) {
    return ExtractedIngredient(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'ingredient',
    );
  }

  bool get isSection => type == 'section';
  bool get isIngredient => type == 'ingredient';
}

/// Represents a step extracted from recipe text
class ExtractedStep {
  final String text;
  final String type; // 'step' or 'section'

  const ExtractedStep({
    required this.text,
    required this.type,
  });

  factory ExtractedStep.fromJson(Map<String, dynamic> json) {
    return ExtractedStep(
      text: json['text'] as String,
      type: json['type'] as String? ?? 'step',
    );
  }

  bool get isSection => type == 'section';
  bool get isStep => type == 'step';
}

/// Represents a recipe extracted from clipping text
class ExtractedRecipe {
  final String title;
  final String? description;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final List<ExtractedIngredient> ingredients;
  final List<ExtractedStep> steps;
  final String? source;
  final String? imageUrl;

  const ExtractedRecipe({
    required this.title,
    this.description,
    this.servings,
    this.prepTime,
    this.cookTime,
    required this.ingredients,
    required this.steps,
    this.source,
    this.imageUrl,
  });

  factory ExtractedRecipe.fromJson(Map<String, dynamic> json) {
    return ExtractedRecipe(
      title: json['title'] as String,
      description: json['description'] as String?,
      servings: json['servings'] as int?,
      prepTime: json['prepTime'] as int?,
      cookTime: json['cookTime'] as int?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => ExtractedIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => ExtractedStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      source: json['source'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Converts extracted ingredients to database Ingredient objects
  List<Map<String, dynamic>> toIngredientsList() {
    return ingredients.map((e) {
      final id = DateTime.now().microsecondsSinceEpoch.toString() +
                 ingredients.indexOf(e).toString();
      return {
        'id': id,
        'type': e.type,
        'name': e.name,
        // Other fields will be null, to be canonicalized later
      };
    }).toList();
  }

  /// Converts extracted steps to database Step objects
  List<Map<String, dynamic>> toStepsList() {
    return steps.map((e) {
      final id = DateTime.now().microsecondsSinceEpoch.toString() +
                 steps.indexOf(e).toString();
      return {
        'id': id,
        'type': e.type,
        'text': e.text,
      };
    }).toList();
  }

  /// Converts this full recipe to a preview (for display before purchase).
  ///
  /// The preview contains title, truncated description, and first 4 ingredients
  /// (excluding section headers).
  RecipePreview toPreview() {
    final desc = description ?? '';
    return RecipePreview(
      title: title,
      description: desc.length > 100 ? '${desc.substring(0, 97)}...' : desc,
      previewIngredients: ingredients
          .where((ing) => ing.isIngredient) // Exclude section headers
          .take(4)
          .map((ing) => ing.name)
          .toList(),
    );
  }
}
