import '../../models/crouton_recipe.dart';
import 'recipe_converter.dart';

/// Common cooking fractions for decimal-to-fraction conversion
/// Each entry is (decimal value, fraction string)
const _commonFractions = <(double, String)>[
  (0.125, '1/8'),
  (0.25, '1/4'),
  (0.333, '1/3'),
  (0.375, '3/8'),
  (0.5, '1/2'),
  (0.625, '5/8'),
  (0.666, '2/3'),
  (0.75, '3/4'),
  (0.875, '7/8'),
];

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
    final amount = quantity.amount!;
    final unit = _mapCroutonUnit(quantity.quantityType);

    // Format the amount based on unit type
    final formattedAmount = _formatAmount(amount, quantity.quantityType);
    if (formattedAmount.isNotEmpty) {
      parts.add(formattedAmount);
    }

    // Add unit if available
    if (unit != null) {
      parts.add(unit);
    }

    // Add ingredient name
    parts.add(name);

    return parts.join(' ');
  }

  /// Format a numeric amount, converting to fractions where appropriate
  /// based on the unit type
  String _formatAmount(double amount, String? quantityType) {
    if (amount == 0) return '';

    // Check if it's a whole number
    if (amount == amount.roundToDouble()) {
      return amount.round().toString();
    }

    // Determine if we should use fractions based on unit type
    final useFractions = _shouldUseFractions(quantityType);

    if (useFractions) {
      return _formatAsFraction(amount);
    } else {
      return _formatAsDecimal(amount, quantityType);
    }
  }

  /// Determine if fractions are appropriate for this unit type
  bool _shouldUseFractions(String? quantityType) {
    if (quantityType == null) return true; // ITEM type - use fractions

    return switch (quantityType) {
      // Volume units - use fractions
      'CUP' || 'TABLESPOON' || 'TEASPOON' || 'PINCH' => true,
      'MILLILITER' || 'LITER' => true,
      // Items - use fractions (e.g., "1/2 onion")
      'ITEM' => true,
      // Weight units - use decimals
      'GRAM' || 'KILOGRAM' || 'OUNCE' || 'POUND' => false,
      // Sub-recipes and unknown - use fractions
      _ => true,
    };
  }

  /// Format amount as a fraction (e.g., "1/3", "1 1/2", "2 2/3")
  String _formatAsFraction(double amount) {
    final wholeNumber = amount.floor();
    final fractionalPart = amount - wholeNumber;

    // If there's no fractional part, just return the whole number
    if (fractionalPart < 0.01) {
      return wholeNumber.toString();
    }

    // Try to match the fractional part to a common fraction
    String? fractionStr;
    for (final (decimal, fraction) in _commonFractions) {
      if ((fractionalPart - decimal).abs() < 0.02) {
        fractionStr = fraction;
        break;
      }
    }

    // If no fraction match, fall back to 2 decimal places
    if (fractionStr == null) {
      return amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    // Build the result
    if (wholeNumber == 0) {
      return fractionStr;
    } else {
      return '$wholeNumber $fractionStr';
    }
  }

  /// Format amount as a decimal based on unit type
  String _formatAsDecimal(double amount, String? quantityType) {
    return switch (quantityType) {
      // Grams - round to whole numbers (e.g., 333g not 333.33g)
      'GRAM' => amount.round().toString(),
      // Kilograms - 1-2 decimal places (e.g., 0.5 kg, 1.25 kg)
      'KILOGRAM' => amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''),
      // Ounces/pounds - 1 decimal place
      'OUNCE' || 'POUND' => amount.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
      // Default - 2 decimal places
      _ => amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''),
    };
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
