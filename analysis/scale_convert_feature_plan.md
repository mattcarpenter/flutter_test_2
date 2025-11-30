# Scale and Convert Feature - Implementation Plan

## Overview

This document outlines the comprehensive plan for implementing ingredient scaling and unit conversion in the recipe app. The feature allows users to:
- Scale all ingredients by a multiplier (0.25x to 10x)
- Scale based on a specific ingredient's amount (e.g., "I have 500g pork, scale everything else")
- Scale based on servings (if available in recipe metadata)
- Convert between unit systems (Original, Imperial, Metric)

---

## Part 1: Architecture Analysis

### 1.1 Current State

#### Existing Infrastructure We Can Leverage

| Component | Location | Current Capability |
|-----------|----------|-------------------|
| `IngredientParserService` | `lib/src/services/ingredient_parser_service.dart` | Parses quantities, units, ranges; has `scaleIngredient()` extension |
| `Ingredient` Model | `lib/database/models/ingredients.dart` | Has structured amount fields (primaryAmount1Value/Unit/Type) but unused for display |
| `Converters` Table | `lib/database/models/converters.dart` | User-defined conversions (term→fromUnit→toBaseUnit with factor) |
| `SharedPreferences` | Various providers | Pattern for local preference persistence |
| `AppTextFieldGroup` | `lib/src/widgets/app_text_field_group.dart` | iOS-style grouped form sections |
| `AdaptivePullDownButton` | `lib/src/widgets/adaptive_pull_down/` | Platform-aware dropdown menus |
| `SliderTheme` | `unified_sort_filter_sheet.dart` | Slider styling pattern |
| `HapticFeedback` | Various widgets | `selectionClick()` pattern |

#### Current Ingredient Display Flow

```
Ingredient.name (raw string like "2 cups flour")
    ↓
IngredientParserService.parse()
    ↓
QuantitySpan objects (start, end, text)
    ↓
RichText with bold quantities
```

**Surfaces that display ingredients:**
1. `RecipeIngredientsView` (`lib/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart`)
2. `IngredientsSheet` (`lib/src/features/recipes/widgets/cook_modal/ingredients_sheet.dart`)

### 1.2 Key Architectural Decisions

#### Decision 1: Work with Raw Name vs Structured Fields

**Current state:** The `Ingredient` model has structured fields (`primaryAmount1Value`, `primaryAmount1Unit`, etc.) but the display code uses `ingredient.name` directly.

**Decision:** Continue working with the raw `name` field for display, but enhance the parser to:
1. Extract numeric values (not just positions)
2. Identify canonical unit types
3. Support scaling and conversion operations

**Rationale:**
- Backwards compatible with existing recipes
- No migration required for existing data
- Parser already handles complex formats (fractions, unicode, ranges, Japanese)
- Structured fields may not always be populated consistently

#### Decision 2: Where to Apply Scaling/Conversion

**Option A:** Transform at display time (chosen)
- Parse → Scale → Convert → Format → Display
- State stored per-recipe, applied when rendering

**Option B:** Transform data model
- Create scaled copies of ingredients
- More complex, potential data consistency issues

**Decision:** Option A - Transform at display time using a pure transformation pipeline.

#### Decision 3: Persistence Strategy

**Decision:** Use SharedPreferences with recipe-specific keys
- Key pattern: `recipe_scale_${recipeId}`
- Store: `{ scaleType, scaleFactor, selectedIngredientId, conversionMode }`
- Consistent with existing filter/sort persistence patterns

---

## Part 2: Core Logic Design

### 2.1 Data Models

```dart
/// The type of scaling being applied
enum ScaleType {
  amount,      // Direct multiplier (0.25x - 10x)
  servings,    // Based on recipe servings
  ingredient,  // Based on a specific ingredient's target amount
}

/// The unit system for conversion
enum ConversionMode {
  original,    // Keep as written
  imperial,    // Convert to imperial (cups, oz, lb)
  metric,      // Convert to metric (ml, g, kg)
}

/// Unit measurement type categories
enum UnitType {
  volume,      // cups, ml, liters, tbsp, tsp
  weight,      // g, kg, oz, lb
  count,       // pieces, slices, cloves
  approximate, // pinch, dash, to taste
  unknown,     // unrecognized units
}

/// Parsed quantity from an ingredient string
class ParsedQuantity {
  final double value;              // Numeric value (e.g., 2.5)
  final double? rangeMax;          // For ranges like "2-3 cups", this is 3
  final String unit;               // Raw unit text (e.g., "cups", "g")
  final String canonicalUnit;      // Normalized unit (e.g., "cup", "gram")
  final UnitType unitType;         // Category of unit
  final int startIndex;            // Position in original string
  final int endIndex;              // End position in original string
  final String originalText;       // Original matched text
}

/// Complete parse result for an ingredient
class EnhancedParseResult {
  final String originalText;
  final List<ParsedQuantity> quantities;
  final String ingredientName;     // Cleaned name without quantities
  final String? note;              // Any note/modifier detected
}

/// State for scaling/conversion preferences
class ScaleConvertState {
  final ScaleType scaleType;
  final double scaleFactor;        // The multiplier to apply
  final String? selectedIngredientId;  // For ingredient-based scaling
  final double? targetIngredientAmount; // Target amount for selected ingredient
  final String? targetIngredientUnit;   // Unit for target amount
  final ConversionMode conversionMode;

  const ScaleConvertState({
    this.scaleType = ScaleType.amount,
    this.scaleFactor = 1.0,
    this.selectedIngredientId,
    this.targetIngredientAmount,
    this.targetIngredientUnit,
    this.conversionMode = ConversionMode.original,
  });
}
```

### 2.2 Unit Conversion System

#### Standard Conversion Definitions

```dart
/// Unit conversion constants
class UnitConversions {
  // Volume conversions (base: milliliter)
  static const Map<String, double> volumeToMl = {
    'ml': 1.0,
    'milliliter': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'cup': 236.588,
    'tablespoon': 14.787,
    'tbsp': 14.787,
    'teaspoon': 4.929,
    'tsp': 4.929,
    'fluid ounce': 29.574,
    'fl oz': 29.574,
    'pint': 473.176,
    'quart': 946.353,
    'gallon': 3785.41,
  };

  // Weight conversions (base: gram)
  static const Map<String, double> weightToGram = {
    'g': 1.0,
    'gram': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'mg': 0.001,
    'milligram': 0.001,
    'oz': 28.3495,
    'ounce': 28.3495,
    'lb': 453.592,
    'pound': 453.592,
  };

  // Preferred units for display by system
  static const Map<ConversionMode, Map<UnitType, List<String>>> preferredUnits = {
    ConversionMode.imperial: {
      UnitType.volume: ['cup', 'tablespoon', 'teaspoon', 'fluid ounce'],
      UnitType.weight: ['pound', 'ounce'],
    },
    ConversionMode.metric: {
      UnitType.volume: ['liter', 'milliliter'],
      UnitType.weight: ['kilogram', 'gram'],
    },
  };
}
```

#### Conversion Logic

The converter should handle these cases:

1. **Same system, no conversion needed**
   - `2 cups` in Imperial mode → `2 cups`

2. **Cross-system conversion**
   - `2 cups` in Metric mode → `473 ml`
   - `500g` in Imperial mode → `1.1 lb` or `17.6 oz`

3. **Smart unit selection**
   - Don't show `0.002 kg`, show `2 g`
   - Don't show `4732 ml`, show `4.7 L`
   - Round to sensible precision

4. **Non-convertible units preserved**
   - `3 cloves garlic` → `3 cloves garlic` (count units unchanged)
   - `pinch of salt` → `pinch of salt` (approximate units unchanged)

### 2.3 Scaling Logic

#### Scale by Amount (Direct Multiplier)
```
scaled_value = original_value × scale_factor
```

Example: Scale 1.5x
- `2 cups flour` → `3 cups flour`
- `1/2 tsp salt` → `3/4 tsp salt`

#### Scale by Servings
```
scale_factor = target_servings / recipe_servings
scaled_value = original_value × scale_factor
```

Example: Recipe serves 4, want to serve 6
- Scale factor = 6/4 = 1.5
- `2 cups flour` → `3 cups flour`

#### Scale by Ingredient
```
scale_factor = target_amount / original_amount
scaled_value = original_value × scale_factor
```

Example: Recipe has `200g ground pork`, user has `500g`
- Scale factor = 500/200 = 2.5
- All other ingredients scale by 2.5x

**Important consideration:** The target amount's unit might differ from the ingredient's original unit. We need to:
1. Parse the original ingredient to get its amount and unit
2. If units match, simple division
3. If units differ but convertible (g vs kg), convert first then divide
4. If units incompatible, show error or disable scaling

### 2.4 Edge Cases and Complex Scenarios

#### Ranges
- `2-3 cups flour` scaled 2x → `4-6 cups flour`
- Scale both bounds by the same factor

#### Multiple Quantities
- `1 cup + 2 tbsp flour` → Scale each quantity independently

#### Fractions and Unicode
- Handle: `1/2`, `½`, `1 1/2`, `1½`
- Output preference: Nice fractions when possible (`1/4`, `1/3`, `1/2`, `2/3`, `3/4`)
- Fall back to decimals for complex values (`1.7`)

#### Japanese Support
- Kanji numbers: `二` → 2
- Half: `半` → 0.5
- Combined: `二半` → 2.5
- Japanese units: `大さじ` (tablespoon), `小さじ` (teaspoon)

#### Approximate Quantities
- `to taste`, `as needed`, `pinch` → Do not scale
- These should pass through unchanged

#### Sub-recipes (linked recipes)
- Ingredients with `recipeId` are linked to other recipes
- Decision: Scale the amount of sub-recipe required, not the sub-recipe itself
- Example: `1 batch of pasta dough` → `2 batches of pasta dough`

#### Duplicate Ingredients in Different Sections
When an ingredient appears in multiple sections (e.g., "flour" in both "Dough" and "Coating"):
- In ingredient selection dropdown, disambiguate with section name
- Format: `Flour (Dough)` vs `Flour (Coating)`

---

## Part 3: Service Layer Design

### 3.1 Enhanced Ingredient Parser Service

**File:** `lib/src/services/ingredient_parser_service.dart`

Enhance the existing service to:

```dart
class EnhancedIngredientParserService {
  /// Parse ingredient and extract structured quantity data
  EnhancedParseResult parseEnhanced(String input);

  /// Scale a parsed ingredient
  String scaleIngredient(String input, double scaleFactor);

  /// Convert a parsed ingredient to different unit system
  String convertIngredient(String input, ConversionMode mode);

  /// Combined scale and convert
  String transformIngredient(String input, {
    double scaleFactor = 1.0,
    ConversionMode conversionMode = ConversionMode.original,
  });

  /// Extract numeric value from quantity text
  double parseNumericValue(String quantityText);

  /// Identify canonical unit and type
  (String canonicalUnit, UnitType unitType) identifyUnit(String unitText);

  /// Format number as nice fraction or decimal
  String formatNumber(double value, {bool preferFractions = true});
}
```

### 3.2 Unit Conversion Service

**File:** `lib/src/services/unit_conversion_service.dart` (new)

```dart
class UnitConversionService {
  /// Convert a value from one unit to another
  ConversionResult convert({
    required double value,
    required String fromUnit,
    required String toUnit,
  });

  /// Convert to the best unit in a target system
  ConversionResult convertToSystem({
    required double value,
    required String fromUnit,
    required ConversionMode targetSystem,
  });

  /// Check if two units are convertible
  bool areUnitsConvertible(String unit1, String unit2);

  /// Get the unit type for a given unit
  UnitType getUnitType(String unit);

  /// Find the most human-friendly unit for a value
  (String unit, double value) selectBestUnit({
    required double valueInBase,
    required UnitType unitType,
    required ConversionMode system,
  });
}

class ConversionResult {
  final double value;
  final String unit;
  final bool isApproximate;
  final String formattedString;
}
```

### 3.3 Ingredient Transform Service

**File:** `lib/src/services/ingredient_transform_service.dart` (new)

This service orchestrates parsing, scaling, and conversion:

```dart
class IngredientTransformService {
  final EnhancedIngredientParserService _parser;
  final UnitConversionService _converter;

  /// Transform an ingredient string with scaling and conversion
  TransformedIngredient transform({
    required String originalText,
    required ScaleConvertState state,
  });

  /// Transform a list of ingredients
  List<TransformedIngredient> transformAll({
    required List<Ingredient> ingredients,
    required ScaleConvertState state,
  });

  /// Calculate scale factor for ingredient-based scaling
  double calculateIngredientScaleFactor({
    required Ingredient sourceIngredient,
    required double targetAmount,
    required String targetUnit,
  });
}

class TransformedIngredient {
  final Ingredient original;
  final String displayText;           // Full transformed text
  final List<QuantityDisplay> quantities;  // For RichText rendering
  final bool wasScaled;
  final bool wasConverted;
}

class QuantityDisplay {
  final int start;
  final int end;
  final String text;
  final bool isBold;
}
```

---

## Part 4: State Management Design

### 4.1 Scale/Convert Provider

**File:** `lib/src/providers/scale_convert_provider.dart` (new)

```dart
/// State for a specific recipe's scale/convert preferences
class ScaleConvertNotifier extends StateNotifier<ScaleConvertState> {
  final String recipeId;
  final SharedPreferences _prefs;

  ScaleConvertNotifier(this.recipeId, this._prefs)
      : super(const ScaleConvertState()) {
    _loadFromPrefs();
  }

  void setScaleType(ScaleType type);
  void setScaleFactor(double factor);
  void setSelectedIngredient(String? ingredientId);
  void setTargetAmount(double amount, String unit);
  void setConversionMode(ConversionMode mode);
  void reset();

  Future<void> _saveToPrefs();
  void _loadFromPrefs();
}

/// Provider family keyed by recipe ID
final scaleConvertProvider = StateNotifierProvider.family<
    ScaleConvertNotifier,
    ScaleConvertState,
    String
>((ref, recipeId) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ScaleConvertNotifier(recipeId, prefs);
});

/// Provider for transformed ingredients
final transformedIngredientsProvider = Provider.family<
    List<TransformedIngredient>,
    String
>((ref, recipeId) {
  final recipe = ref.watch(recipeByIdStreamProvider(recipeId)).valueOrNull;
  final scaleState = ref.watch(scaleConvertProvider(recipeId));
  final transformer = ref.watch(ingredientTransformServiceProvider);

  if (recipe?.ingredients == null) return [];

  return transformer.transformAll(
    ingredients: recipe!.ingredients!,
    state: scaleState,
  );
});
```

### 4.2 Persistence Schema

**SharedPreferences key:** `recipe_scale_${recipeId}`

**JSON structure:**
```json
{
  "scaleType": "amount",
  "scaleFactor": 1.5,
  "selectedIngredientId": null,
  "targetIngredientAmount": null,
  "targetIngredientUnit": null,
  "conversionMode": "original"
}
```

---

## Part 5: UI Implementation Design

### 5.1 Scale/Convert Panel Structure

Replace the placeholder in `RecipeIngredientsView` with:

```
┌─────────────────────────────────────────────────┐
│ Scale Group                                      │
├─────────────────────────────────────────────────┤
│ Scale        │ [Amount ▾]                       │  ← Row 1: Scale type dropdown
├─────────────────────────────────────────────────┤
│ Ingredient   │ [Select ingredient ▾]            │  ← Row 2: Only if type=Ingredient
├─────────────────────────────────────────────────┤
│ Amount: 1x   │ ═══════●═══════════════════     │  ← Row 3: Slider with label
└─────────────────────────────────────────────────┘
   12px gap
┌─────────────────────────────────────────────────┐
│ Convert Group                                    │
├─────────────────────────────────────────────────┤
│ Convert      │ [Original ▾]                     │
└─────────────────────────────────────────────────┘
   8px gap
┌─────────────────────────────────────────────────┐
│             [Reset]                              │  ← TextButton
└─────────────────────────────────────────────────┘
```

### 5.2 Component Hierarchy

```dart
ScaleConvertPanel
├── ScaleGroup (AppTextFieldGroup)
│   ├── ScaleTypeRow
│   │   ├── Label: "Scale"
│   │   └── AdaptivePullDownButton: Amount/Servings/Ingredient
│   │
│   ├── IngredientSelectorRow (AnimatedSize, only if type=Ingredient)
│   │   ├── Label: "Ingredient"
│   │   └── AdaptivePullDownButton: List of ingredients (with section disambiguation)
│   │
│   └── ScaleSliderRow
│       ├── Label: "Amount: 1.5x" or "Servings: 6" (dynamic)
│       └── Slider (with haptic feedback)
│
├── SizedBox(height: 12)
│
├── ConvertGroup (AppTextFieldGroup)
│   └── ConvertRow
│       ├── Label: "Convert"
│       └── AdaptivePullDownButton: Original/Imperial/Metric
│
├── SizedBox(height: 8)
│
└── ResetButton (TextButton, center-aligned)
```

### 5.3 Dropdown Button Styling

Based on the pattern from `ingredient_matches_bottom_sheet.dart`:

```dart
Widget _buildDropdownButton(BuildContext context, String text, VoidCallback onTap) {
  final colors = AppColors.of(context);

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              text,
              style: TextStyle(
                color: colors.chipText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_down,
            size: 14,
            color: colors.chipText,
          ),
        ],
      ),
    ),
  );
}
```

### 5.4 Slider Configuration

```dart
Widget _buildScaleSlider(BuildContext context, ScaleConvertState state) {
  final colors = AppColors.of(context);

  // Determine slider range based on scale type
  final (min, max, initial) = switch (state.scaleType) {
    ScaleType.amount => (0.25, 10.0, 1.0),
    ScaleType.servings => (1.0, 20.0, recipeServings.toDouble()),
    ScaleType.ingredient => _getIngredientSliderRange(state),
  };

  return SliderTheme(
    data: SliderTheme.of(context).copyWith(
      activeTrackColor: colors.primary,
      inactiveTrackColor: AppColorSwatches.neutral[300],
      thumbColor: colors.primary,
      overlayColor: colors.primary.withOpacity(0.1),
      trackHeight: 4,
    ),
    child: Slider(
      value: state.scaleFactor,
      min: min,
      max: max,
      // Position 1x at ~25% from left for amount mode
      onChanged: (value) {
        HapticFeedback.selectionClick();
        ref.read(scaleConvertProvider(recipeId).notifier)
            .setScaleFactor(value);
      },
    ),
  );
}
```

**Slider Value Positioning for Amount Mode:**
- The slider goes from 0.25x to 10x
- Value 1x should appear at approximately 25% from left
- This is achieved naturally if min=0.25 (which is 1/4 of the way to 1x visually)
- Alternative: Use a logarithmic scale for better distribution

### 5.5 Ingredient Selector Dropdown

When scale type is "Ingredient", show a dropdown with all scalable ingredients:

```dart
List<AdaptiveMenuItem> _buildIngredientMenuItems(List<Ingredient> ingredients) {
  final items = <AdaptiveMenuItem>[];
  String? currentSection;

  for (final ingredient in ingredients) {
    if (ingredient.type == 'section') {
      currentSection = ingredient.name;
      continue;
    }

    // Skip ingredients without parseable quantities
    final parsed = parser.parseEnhanced(ingredient.name);
    if (parsed.quantities.isEmpty) continue;

    // Build display name with section disambiguation
    final displayName = currentSection != null
        ? '${ingredient.name} ($currentSection)'
        : ingredient.name;

    items.add(AdaptiveMenuItem(
      title: displayName,
      icon: const Icon(CupertinoIcons.circle),
      onTap: () => selectIngredient(ingredient.id),
    ));
  }

  return items;
}
```

### 5.6 Animated Row for Ingredient Selector

```dart
AnimatedSize(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  child: state.scaleType == ScaleType.ingredient
      ? _IngredientSelectorRow(...)
      : const SizedBox.shrink(),
)
```

---

## Part 6: Integration Points

### 6.1 RecipeIngredientsView Integration

**File:** `lib/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart`

Changes needed:
1. Replace placeholder accordion content with `ScaleConvertPanel`
2. Consume `transformedIngredientsProvider` instead of raw ingredients
3. Update `_buildParsedIngredientText` to use `TransformedIngredient.quantities`

```dart
// Current
child: _buildParsedIngredientText(
  ingredient.name,
  fontSize: scaledFontSize,
  isLinkedRecipe: ingredient.recipeId != null,
),

// Updated
final transformed = transformedIngredients.firstWhere(
  (t) => t.original.id == ingredient.id,
);
child: _buildTransformedIngredientText(
  transformed,
  fontSize: scaledFontSize,
  isLinkedRecipe: ingredient.recipeId != null,
),
```

### 6.2 IngredientsSheet (Cook Modal) Integration

**File:** `lib/src/features/recipes/widgets/cook_modal/ingredients_sheet.dart`

The cook modal needs to access the same scale/convert state:

```dart
void showIngredientsModal(
  BuildContext context,
  List<Ingredient> ingredients,
  String recipeId,  // Add recipeId parameter
) {
  // ... modal setup
}

class IngredientsSheet extends ConsumerWidget {
  final List<Ingredient> ingredients;
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get transformed ingredients using same provider
    final transformedIngredients = ref.watch(
      transformedIngredientsProvider(recipeId)
    );

    // Render using transformed data
    // ...
  }
}
```

### 6.3 Cook Modal Launch Point

**File:** `lib/src/features/recipes/widgets/cook_modal/cook_modal.dart`

Update `showIngredientsModal` call to pass recipeId:

```dart
// In cook_content.dart where ingredients button calls showIngredientsModal
showIngredientsModal(context, _ingredients!, widget.recipeId);
```

---

## Part 7: Testing Strategy

### 7.1 Unit Tests

#### Parsing Tests (`test/services/ingredient_parser_test.dart`)

```dart
group('EnhancedIngredientParserService', () {
  test('parses simple quantities', () {
    expect(parse('2 cups flour'), hasQuantity(2.0, 'cup'));
  });

  test('parses fractions', () {
    expect(parse('1/2 cup sugar'), hasQuantity(0.5, 'cup'));
    expect(parse('½ cup sugar'), hasQuantity(0.5, 'cup'));
    expect(parse('1 1/2 cups flour'), hasQuantity(1.5, 'cup'));
  });

  test('parses ranges', () {
    final result = parse('2-3 cups flour');
    expect(result.quantities[0].value, 2.0);
    expect(result.quantities[0].rangeMax, 3.0);
  });

  test('handles multiple quantities', () {
    expect(parse('1 cup + 2 tbsp flour'), hasQuantityCount(2));
  });

  test('identifies unit types correctly', () {
    expect(identifyUnit('cups'), (equals('cup'), equals(UnitType.volume)));
    expect(identifyUnit('g'), (equals('gram'), equals(UnitType.weight)));
    expect(identifyUnit('cloves'), (equals('clove'), equals(UnitType.count)));
  });

  test('handles approximate quantities', () {
    final result = parse('salt to taste');
    expect(result.quantities, isEmpty);
    expect(result.ingredientName, contains('salt'));
  });

  // Japanese tests
  test('parses Japanese quantities', () {
    expect(parse('大さじ2'), hasQuantity(2.0, '大さじ'));
    expect(parse('二カップ'), hasQuantity(2.0, 'カップ'));
  });
});
```

#### Conversion Tests (`test/services/unit_conversion_test.dart`)

```dart
group('UnitConversionService', () {
  test('converts cups to ml', () {
    final result = convert(value: 2, fromUnit: 'cup', toUnit: 'ml');
    expect(result.value, closeTo(473.18, 0.1));
  });

  test('converts grams to ounces', () {
    final result = convert(value: 100, fromUnit: 'g', toUnit: 'oz');
    expect(result.value, closeTo(3.53, 0.01));
  });

  test('selects best metric unit for small values', () {
    final result = convertToSystem(value: 5, fromUnit: 'g', targetSystem: ConversionMode.metric);
    expect(result.unit, equals('g')); // Not 0.005 kg
  });

  test('selects best metric unit for large values', () {
    final result = convertToSystem(value: 1500, fromUnit: 'g', targetSystem: ConversionMode.metric);
    expect(result.unit, equals('kg'));
    expect(result.value, closeTo(1.5, 0.01));
  });

  test('returns unchanged for count units', () {
    final result = convertToSystem(value: 3, fromUnit: 'cloves', targetSystem: ConversionMode.metric);
    expect(result.unit, equals('cloves'));
    expect(result.value, equals(3));
  });
});
```

#### Scaling Tests (`test/services/ingredient_transform_test.dart`)

```dart
group('IngredientTransformService', () {
  test('scales ingredient by factor', () {
    final result = transform('2 cups flour', scaleFactor: 1.5);
    expect(result.displayText, equals('3 cups flour'));
  });

  test('scales and formats fractions nicely', () {
    final result = transform('1 cup flour', scaleFactor: 0.5);
    expect(result.displayText, equals('1/2 cup flour'));
  });

  test('scales range quantities', () {
    final result = transform('2-3 cups broth', scaleFactor: 2);
    expect(result.displayText, equals('4-6 cups broth'));
  });

  test('converts while scaling', () {
    final result = transform(
      '1 cup flour',
      scaleFactor: 1.0,
      conversionMode: ConversionMode.metric,
    );
    expect(result.displayText, contains('ml'));
  });

  test('preserves approximate quantities when scaling', () {
    final result = transform('salt to taste', scaleFactor: 2);
    expect(result.displayText, equals('salt to taste'));
  });

  test('calculates ingredient-based scale factor', () {
    final factor = calculateIngredientScaleFactor(
      sourceIngredient: Ingredient(name: '200g pork'),
      targetAmount: 500,
      targetUnit: 'g',
    );
    expect(factor, equals(2.5));
  });
});
```

### 7.2 Widget Tests

```dart
group('ScaleConvertPanel', () {
  testWidgets('shows scale type dropdown', (tester) async {
    // ...
  });

  testWidgets('shows ingredient selector when type is ingredient', (tester) async {
    // ...
  });

  testWidgets('hides ingredient selector when type is amount', (tester) async {
    // ...
  });

  testWidgets('slider triggers haptic feedback', (tester) async {
    // ...
  });

  testWidgets('reset button clears all settings', (tester) async {
    // ...
  });
});
```

### 7.3 Integration Tests

```dart
group('Scale/Convert Integration', () {
  testWidgets('scaling updates ingredient display', (tester) async {
    // Load recipe page
    // Expand scale panel
    // Set scale to 2x
    // Verify ingredient quantities doubled
  });

  testWidgets('conversion updates ingredient display', (tester) async {
    // Load recipe page with imperial ingredients
    // Expand scale panel
    // Set conversion to metric
    // Verify units converted
  });

  testWidgets('cook modal respects scale settings', (tester) async {
    // Set scale to 2x on recipe page
    // Open cook modal
    // Open ingredients sheet
    // Verify ingredients show scaled amounts
  });

  testWidgets('settings persist across navigation', (tester) async {
    // Set scale to 1.5x
    // Navigate away
    // Navigate back
    // Verify scale is still 1.5x
  });
});
```

---

## Part 8: Implementation Order

### Phase 1: Core Services (Foundation)
1. Create `UnitConversionService` with conversion logic and unit definitions
2. Enhance `IngredientParserService` with `parseEnhanced()` method
3. Create `IngredientTransformService` to orchestrate parsing, scaling, conversion
4. Write comprehensive unit tests for all services

### Phase 2: State Management
5. Create `ScaleConvertState` model
6. Create `scaleConvertProvider` with SharedPreferences persistence
7. Create `transformedIngredientsProvider`
8. Test state persistence and restoration

### Phase 3: UI Components
9. Create `ScaleConvertPanel` widget with grouped sections
10. Implement scale type dropdown (Amount/Servings/Ingredient)
11. Implement ingredient selector dropdown (with section disambiguation)
12. Implement scale slider with haptic feedback
13. Implement conversion dropdown
14. Implement reset button
15. Wire up animations for accordion and ingredient selector row

### Phase 4: Integration
16. Update `RecipeIngredientsView` to use transformed ingredients
17. Update `IngredientsSheet` to use transformed ingredients
18. Pass recipeId through cook modal flow
19. Test end-to-end on recipe page
20. Test end-to-end in cook modal

### Phase 5: Polish
21. Handle edge cases (empty ingredients, no quantities, etc.)
22. Add loading states if needed
23. Test with Japanese recipes
24. Test with complex ingredient formats
25. Performance optimization if needed

---

## Part 9: File Changes Summary

### New Files to Create

| File | Purpose |
|------|---------|
| `lib/src/services/unit_conversion_service.dart` | Unit conversion logic |
| `lib/src/services/ingredient_transform_service.dart` | Orchestrates parse/scale/convert |
| `lib/src/providers/scale_convert_provider.dart` | State management for scale/convert |
| `lib/src/features/recipes/widgets/scale_convert/scale_convert_panel.dart` | Main UI panel |
| `lib/src/features/recipes/widgets/scale_convert/scale_type_row.dart` | Scale type selector |
| `lib/src/features/recipes/widgets/scale_convert/ingredient_selector_row.dart` | Ingredient dropdown |
| `lib/src/features/recipes/widgets/scale_convert/scale_slider_row.dart` | Slider component |
| `lib/src/features/recipes/widgets/scale_convert/convert_row.dart` | Conversion selector |
| `lib/src/features/recipes/models/scale_convert_state.dart` | State models |
| `test/services/unit_conversion_service_test.dart` | Conversion tests |
| `test/services/ingredient_transform_service_test.dart` | Transform tests |
| `test/services/enhanced_ingredient_parser_test.dart` | Enhanced parser tests |

### Files to Modify

| File | Changes |
|------|---------|
| `lib/src/services/ingredient_parser_service.dart` | Add `parseEnhanced()` and related methods |
| `lib/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart` | Replace placeholder, use transformed ingredients |
| `lib/src/features/recipes/widgets/cook_modal/ingredients_sheet.dart` | Accept recipeId, use transformed ingredients |
| `lib/src/features/recipes/widgets/cook_modal/cook_content.dart` | Pass recipeId to ingredients sheet |

---

## Part 10: Open Questions for Review

1. **Slider Range for Ingredient-Based Scaling:** When scaling by ingredient, what should the slider range be? Options:
   - Fixed range (e.g., 10% to 500% of original)
   - Dynamic based on ingredient amount (e.g., original/10 to original×10)
   - Text input instead of slider for precision?

2. **Fractional Precision:** When displaying scaled values, how precise should we be?
   - Current: Show nice fractions (1/4, 1/3, 1/2, 2/3, 3/4) or decimals
   - Consider: Round to nearest 1/4 for simplicity?
   - Consider: Show exact calculation with option to round?

3. **Conversion for Ambiguous Units:** Some units can be volume or weight (e.g., "1 cup butter" could be ~227g, but depends on the ingredient). Options:
   - Use standard conversions regardless of ingredient
   - Flag approximate conversions
   - Eventually integrate with user-defined converters table

4. **Sub-recipe Scaling:** When a recipe includes a sub-recipe (linked `recipeId`), should we:
   - Just scale the "batch" count (current thinking)
   - Provide option to view scaled sub-recipe?
   - Something else?

5. **Servings UI When Not Available:** If a recipe doesn't have servings defined:
   - Disable "Servings" option in dropdown (current thinking)
   - Show but display helpful message when selected
   - Allow user to enter assumed servings?

---

## Appendix A: UI Mockup (ASCII)

### Collapsed State
```
┌────────────────────────────────────────────────────────┐
│ Ingredients                        [Scale or Convert ▾]│
├────────────────────────────────────────────────────────┤
│ • 2 cups flour                                    [●]  │
│ • 1 tsp salt                                      [○]  │
│ • 1/2 cup butter                                  [●]  │
│ ...                                                    │
└────────────────────────────────────────────────────────┘
```

### Expanded State (Amount Mode)
```
┌────────────────────────────────────────────────────────┐
│ Ingredients                        [Scale or Convert ▲]│
├────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐ │
│ │ Scale            │                      [Amount ▾] │ │
│ ├────────────────────────────────────────────────────┤ │
│ │ Amount: 1.5x     │ ═══════●═══════════════════════ │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ Convert          │                    [Original ▾] │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│                       [Reset]                          │
├────────────────────────────────────────────────────────┤
│ • 3 cups flour                                    [●]  │
│ • 1 1/2 tsp salt                                  [○]  │
│ • 3/4 cup butter                                  [●]  │
│ ...                                                    │
└────────────────────────────────────────────────────────┘
```

### Expanded State (Ingredient Mode)
```
┌────────────────────────────────────────────────────────┐
│ Ingredients                        [Scale or Convert ▲]│
├────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐ │
│ │ Scale            │                  [Ingredient ▾] │ │
│ ├────────────────────────────────────────────────────┤ │
│ │ Ingredient       │              [500g ground pork] │ │
│ ├────────────────────────────────────────────────────┤ │
│ │ Amount: 500g     │ ═════════════●═════════════════ │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ Convert          │                    [Original ▾] │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│                       [Reset]                          │
├────────────────────────────────────────────────────────┤
│ • 500g ground pork (scaled from 200g)             [●]  │
│ • 2 1/2 tbsp soy sauce                            [○]  │
│ • 1 1/4 cups flour                                [●]  │
│ ...                                                    │
└────────────────────────────────────────────────────────┘
```

---

## Appendix B: Unit Conversion Reference Tables

### Volume Conversions (Base: milliliter)

**Important Note on Regional Units:** Units like `cup` and `カップ` are treated as *distinct units* with their own conversion factors - not as translations of the same unit. A Japanese cup (カップ) is 200ml while a US cup is ~237ml. The unit text itself determines the conversion factor, not language detection.

Future enhancement: A user setting could allow overriding regional defaults (e.g., "my cups are UK cups at 250ml").

| Unit | To ml | Notes |
|------|-------|-------|
| milliliter (ml) | 1 | |
| teaspoon (tsp) | 4.929 | US teaspoon |
| tablespoon (tbsp) | 14.787 | US tablespoon |
| fluid ounce (fl oz) | 29.574 | US fluid ounce |
| cup | 236.588 | US cup |
| pint | 473.176 | US pint |
| quart | 946.353 | US quart |
| liter (L) | 1000 | |
| gallon | 3785.41 | US gallon |
| カップ | 200.0 | Japanese cup |
| 大さじ | 15.0 | Japanese tablespoon |
| 小さじ | 5.0 | Japanese teaspoon |
| 合 | 180.0 | Traditional rice measure |
| 升 | 1800.0 | Traditional measure (10 合) |

### Weight Conversions (Base: gram)

| Unit | To g | From g |
|------|------|--------|
| milligram (mg) | 0.001 | 1000 |
| gram (g) | 1 | 1 |
| ounce (oz) | 28.3495 | 0.0353 |
| pound (lb) | 453.592 | 0.0022 |
| kilogram (kg) | 1000 | 0.001 |

### Preferred Display Units by System

**Imperial:**
- Volume: cup → tbsp → tsp → fl oz
- Weight: lb → oz

**Metric:**
- Volume: L → ml
- Weight: kg → g

### Unit Display Thresholds

| Unit | Show if value >= | Show if value < |
|------|-----------------|-----------------|
| L | 0.5 | - |
| ml | - | 500 |
| kg | 0.5 | - |
| g | - | 500 |
| lb | 0.25 | - |
| oz | - | 4 |
| cup | 0.25 | - |
| tbsp | - | 4 |
| tsp | - | 3 |
