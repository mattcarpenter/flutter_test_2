import '../../models/crouton_recipe.dart';
import 'recipe_converter.dart';

/// Converts Crouton recipe format (.crumb) to ImportedRecipe
class CroutonConverter extends RecipeConverter<CroutonRecipe> {
  @override
  ImportedRecipe convert(CroutonRecipe source) {
    return ImportedRecipe(
      title: source.name,
      description: null, // Crouton doesn't have a separate description field
      rating: null, // Crouton doesn't have ratings
      language: null, // Crouton doesn't have language field
      servings: source.serves,
      prepTime: _secondsToMinutes(source.duration),
      cookTime: _secondsToMinutes(source.cookingDuration),
      totalTime: _secondsToMinutes(
        (source.duration ?? 0) + (source.cookingDuration ?? 0),
      ),
      source: source.webLink,
      nutrition: source.nutritionalInfo,
      generalNotes: source.notes,
      createdAt: null, // Crouton doesn't export creation date
      updatedAt: null,
      pinned: false,
      tagNames: source.tags ?? [],
      folderNames: [], // Ignore folderIDs as they're meaningless without folder data
      ingredients: _convertIngredients(source.ingredients ?? []),
      steps: _convertSteps(source.steps ?? []),
      images: _convertImages(source.images ?? []),
    );
  }

  /// Convert seconds to minutes (null if 0 or null)
  int? _secondsToMinutes(int? seconds) {
    if (seconds == null || seconds == 0) return null;
    return (seconds / 60).round();
  }

  /// Convert Crouton ingredients to ImportedIngredient
  List<ImportedIngredient> _convertIngredients(List<CroutonIngredient> ingredients) {
    return ingredients.map((ingredient) {
      // Check if this is a section header (no ingredient info, just order)
      if (ingredient.ingredient == null) {
        // This might be a section, but Crouton doesn't explicitly mark sections
        // For now, skip entries without ingredient info
        return null;
      }

      // Build ingredient name from structured data: "{amount} {unit} {name}"
      final name = _buildIngredientName(
        ingredient.quantity,
        ingredient.ingredient!.name,
      );

      return ImportedIngredient(
        type: 'ingredient',
        name: name,
        note: null,
        terms: null,
        isCanonicalised: false, // Crouton ingredients need canonicalization
        category: null,
      );
    }).whereType<ImportedIngredient>().toList();
  }

  /// Build ingredient name from quantity and name
  String _buildIngredientName(CroutonQuantity? quantity, String name) {
    if (quantity == null || quantity.amount == null) {
      return name;
    }

    final parts = <String>[];

    // Add amount (format nicely, remove trailing zeros)
    final amount = quantity.amount!;
    if (amount == amount.roundToDouble()) {
      parts.add(amount.round().toString());
    } else {
      parts.add(amount.toString());
    }

    // Add unit if available
    final unit = _mapCroutonUnit(quantity.quantityType);
    if (unit != null) {
      parts.add(unit);
    }

    // Add ingredient name
    parts.add(name);

    return parts.join(' ');
  }

  /// Map Crouton quantity types to unit abbreviations
  String? _mapCroutonUnit(String? quantityType) {
    if (quantityType == null) return null;

    return switch (quantityType) {
      'ITEM' => null, // No unit for items (e.g., "2 eggs")
      'CUP' => 'cup',
      'TABLESPOON' => 'tbsp',
      'TEASPOON' => 'tsp',
      'GRAM' => 'g',
      'KILOGRAM' => 'kg',
      'OUNCE' => 'oz',
      'POUND' => 'lb',
      'MILLILITER' => 'ml',
      'LITER' => 'l',
      'PINCH' => 'pinch',
      'RECIPE' => null, // Sub-recipe handled separately
      _ => null,
    };
  }

  /// Convert Crouton steps to ImportedStep
  List<ImportedStep> _convertSteps(List<CroutonStep> steps) {
    return steps.map((step) {
      // Determine if this is a section based on isSection flag
      final type = (step.isSection ?? false) ? 'section' : 'step';

      return ImportedStep(
        type: type,
        text: step.step ?? '',
        note: null,
        timerDurationSeconds: null,
      );
    }).toList();
  }

  /// Convert Crouton images (base64 strings) to ImportedImage
  List<ImportedImage> _convertImages(List<String> images) {
    return images.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return ImportedImage(
        isCover: index == 0, // First image is cover
        data: data,
        publicUrl: null,
      );
    }).toList();
  }
}
