import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/recipes/models/scale_convert_state.dart';
import '../services/ingredient_parser_service.dart';
import '../services/ingredient_transform_service.dart';
import '../services/unit_conversion_service.dart';
import 'recipe_filter_sort_provider.dart';
import 'recipe_provider.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Provider for the unit conversion service
final unitConversionServiceProvider = Provider<UnitConversionService>((ref) {
  return UnitConversionService();
});

/// Provider for the ingredient parser service
final ingredientParserServiceProvider = Provider<IngredientParserService>((ref) {
  return IngredientParserService();
});

/// Provider for the ingredient transform service
final ingredientTransformServiceProvider = Provider<IngredientTransformService>((ref) {
  final parser = ref.watch(ingredientParserServiceProvider);
  final converter = ref.watch(unitConversionServiceProvider);
  return IngredientTransformService(parser: parser, converter: converter);
});

// ============================================================
// SCALE/CONVERT STATE PROVIDER
// ============================================================

/// Notifier for managing scale/convert state for a specific recipe.
///
/// This notifier handles:
/// - Scale type selection (amount, servings, ingredient)
/// - Scale factor updates
/// - Ingredient selection for ingredient-based scaling
/// - Conversion mode selection
/// - Persistence to SharedPreferences
class ScaleConvertNotifier extends FamilyNotifier<ScaleConvertState, String> {
  late String _recipeId;

  @override
  ScaleConvertState build(String recipeId) {
    _recipeId = recipeId;
    return _loadFromPrefs();
  }

  String get _prefsKey => 'recipe_scale_$_recipeId';

  /// Load state from SharedPreferences
  ScaleConvertState _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) {
      return const ScaleConvertState();
    }

    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) {
      return const ScaleConvertState();
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ScaleConvertState.fromJson(json);
    } catch (_) {
      // If parsing fails, return default state
      return const ScaleConvertState();
    }
  }

  /// Save current state to SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return;

    final jsonStr = jsonEncode(state.toJson());
    await prefs.setString(_prefsKey, jsonStr);
  }

  /// Set the scale type
  void setScaleType(ScaleType type) {
    state = state.copyWith(
      scaleType: type,
      // Clear ingredient selection when switching away from ingredient mode
      clearSelectedIngredient: type != ScaleType.ingredient,
      clearTargetAmount: type != ScaleType.ingredient,
    );
    _saveToPrefs();
  }

  /// Set the scale factor
  void setScaleFactor(double factor) {
    state = state.copyWith(scaleFactor: factor);
    _saveToPrefs();
  }

  /// Set the selected ingredient for ingredient-based scaling
  void setSelectedIngredient(String? ingredientId) {
    state = state.copyWith(
      selectedIngredientId: ingredientId,
      clearSelectedIngredient: ingredientId == null,
    );
    _saveToPrefs();
  }

  /// Set the target amount for ingredient-based scaling
  void setTargetAmount(double? amount, String? unit) {
    state = state.copyWith(
      targetIngredientAmount: amount,
      targetIngredientUnit: unit,
      clearTargetAmount: amount == null,
    );
    _saveToPrefs();
  }

  /// Set the conversion mode
  void setConversionMode(ConversionMode mode) {
    state = state.copyWith(conversionMode: mode);
    _saveToPrefs();
  }

  /// Reset to default state
  void reset() {
    state = const ScaleConvertState();
    _saveToPrefs();
  }

  /// Update scale factor based on ingredient target.
  ///
  /// Call this when the user sets a target amount for ingredient-based scaling.
  /// Returns true if the scale factor was updated, false if calculation failed.
  bool updateScaleFactorFromIngredientTarget({
    required String sourceIngredientText,
    required double targetAmount,
    required String targetUnit,
  }) {
    final transformer = ref.read(ingredientTransformServiceProvider);
    final factor = transformer.calculateIngredientScaleFactor(
      sourceIngredientText: sourceIngredientText,
      targetAmount: targetAmount,
      targetUnit: targetUnit,
    );

    if (factor != null) {
      state = state.copyWith(
        scaleFactor: factor,
        targetIngredientAmount: targetAmount,
        targetIngredientUnit: targetUnit,
      );
      _saveToPrefs();
      return true;
    }
    return false;
  }
}

/// Provider family for scale/convert state, keyed by recipe ID.
///
/// Usage:
/// ```dart
/// final scaleState = ref.watch(scaleConvertProvider(recipeId));
/// ref.read(scaleConvertProvider(recipeId).notifier).setScaleFactor(2.0);
/// ```
final scaleConvertProvider =
    NotifierProvider.family<ScaleConvertNotifier, ScaleConvertState, String>(
  ScaleConvertNotifier.new,
);

// ============================================================
// TRANSFORMED INGREDIENTS PROVIDER
// ============================================================

/// Provider for transformed ingredients based on the current scale/convert state.
///
/// This provider watches both the recipe's ingredients and the scale/convert state,
/// then applies transformations to produce display-ready ingredient strings.
///
/// Usage:
/// ```dart
/// final transformed = ref.watch(transformedIngredientsProvider(recipeId));
/// ```
final transformedIngredientsProvider =
    Provider.family<List<TransformedIngredient>, String>((ref, recipeId) {
  // Watch the recipe to get ingredients
  final recipeAsync = ref.watch(recipeByIdStreamProvider(recipeId));

  // Watch the scale/convert state
  final scaleState = ref.watch(scaleConvertProvider(recipeId));

  // Get the transform service
  final transformer = ref.watch(ingredientTransformServiceProvider);

  // Handle loading/error states
  final recipe = recipeAsync.valueOrNull;
  if (recipe == null || recipe.ingredients == null) {
    return [];
  }

  // Transform all ingredient names
  final ingredientNames = recipe.ingredients!
      .where((ing) => ing.type != 'section') // Skip section headers
      .map((ing) => ing.name)
      .toList();

  return transformer.transformAll(
    ingredientNames: ingredientNames,
    state: scaleState,
  );
});

/// Provider that returns a map of ingredient ID to transformed ingredient.
///
/// Useful for looking up transformed ingredients by ID when rendering.
final transformedIngredientsByIdProvider =
    Provider.family<Map<String, TransformedIngredient>, String>((ref, recipeId) {
  // Watch the recipe to get ingredients with IDs
  final recipeAsync = ref.watch(recipeByIdStreamProvider(recipeId));

  // Watch the scale/convert state
  final scaleState = ref.watch(scaleConvertProvider(recipeId));

  // Get the transform service
  final transformer = ref.watch(ingredientTransformServiceProvider);

  // Handle loading/error states
  final recipe = recipeAsync.valueOrNull;
  if (recipe == null || recipe.ingredients == null) {
    return {};
  }

  // Build map of ingredient ID to transformed result
  final result = <String, TransformedIngredient>{};

  for (final ingredient in recipe.ingredients!) {
    if (ingredient.type == 'section') continue;

    final transformed = transformer.transform(
      originalText: ingredient.name,
      state: scaleState,
    );
    result[ingredient.id] = transformed;
  }

  return result;
});

/// Provider for getting a list of scalable ingredients for the dropdown.
///
/// Returns ingredients that are suitable for ingredient-based scaling selection.
/// This includes:
/// - Ingredients with parseable quantities (e.g., "2 cups flour")
/// - Bare ingredients without quantities (e.g., "Carrot") - treated as 1 unit
///
/// Excludes:
/// - Approximate terms like "to taste", "pinch", "dash", etc.
final scalableIngredientsProvider =
    Provider.family<List<({String id, String name, String displayName})>, String>(
        (ref, recipeId) {
  final recipeAsync = ref.watch(recipeByIdStreamProvider(recipeId));
  final converter = ref.watch(unitConversionServiceProvider);

  final recipe = recipeAsync.valueOrNull;
  if (recipe == null || recipe.ingredients == null) {
    return [];
  }

  final result = <({String id, String name, String displayName})>[];
  String? currentSection;

  for (final ingredient in recipe.ingredients!) {
    if (ingredient.type == 'section') {
      currentSection = ingredient.name;
      continue;
    }

    // Exclude ingredients with approximate terms (pinch, to taste, etc.)
    if (converter.containsApproximateTerm(ingredient.name)) {
      continue;
    }

    // Build display name with section disambiguation if needed
    final displayName = currentSection != null
        ? '${ingredient.name} ($currentSection)'
        : ingredient.name;

    result.add((
      id: ingredient.id,
      name: ingredient.name,
      displayName: displayName,
    ));
  }

  return result;
});
