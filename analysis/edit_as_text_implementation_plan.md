# Edit as Text Feature - Implementation Plan

## Overview

Add "Edit as Text" functionality to the recipe editor's Ingredients and Steps sections. This provides a bulk text editing interface where users can:
- Copy/paste ingredients or steps from external sources
- Quickly edit multiple items without navigating individual fields
- View and edit all items in a familiar plaintext format

## Current Architecture Understanding

### Recipe Editor Modal Structure
**File:** `lib/src/features/recipes/views/add_recipe_modal.dart`

The recipe editor uses a **single-page Wolt modal sheet**:
```dart
WoltModalSheet.show(
  pageListBuilder: (bottomSheetContext) => [
    RecipeEditorModalPage.build(...),  // Single page
  ],
);
```

The form state is accessed via `GlobalKey<RecipeEditorFormState>` and exposes:
- `_ingredients` - `List<Ingredient>`
- `_steps` - `List<Step>`
- `_updateIngredient()`, `_addIngredient()`, etc.

### Stacked Bottom Sheet Pattern (What We'll Use)
**Example:** Folder selection flow opens a separate bottom sheet on top

The pattern is simple:
1. From within a bottom sheet, call `WoltModalSheet.show()` again
2. The new sheet stacks on top of the existing one
3. When the new sheet closes (`Navigator.pop()`), the original sheet is still there
4. Data is passed back via callback or return value

This avoids the complexity of multi-page navigation with `pageIndexNotifier`.

### Overflow Menu Pattern
**Files:**
- `lib/src/features/recipes/widgets/recipe_editor_form/sections/ingredients_section.dart` (line 187)
- `lib/src/features/recipes/widgets/recipe_editor_form/sections/steps_section.dart` (line 184)

Both use `AppOverflowButton` with `AdaptiveMenuItem` items:
```dart
AppOverflowButton(
  items: [
    AdaptiveMenuItem(
      title: 'Clear All Ingredients',
      icon: const Icon(Icons.clear_all),
      onTap: () { ... },
    ),
  ],
)
```

### Data Models

**Ingredient** (`lib/database/models/ingredients.dart`):
```dart
class Ingredient {
  final String id;           // UUID
  final String type;         // "ingredient" or "section"
  final String name;         // User-entered text (e.g., "1 cup flour")
  // ... other fields (amounts, terms, etc.)
}
```

**Step** (`lib/database/models/steps.dart`):
```dart
class Step {
  final String id;    // UUID
  final String type;  // "step" or "section"
  final String text;  // Step instruction text
  // ... other fields (note, timerDurationSeconds)
}
```

## Text Format Specification

### Format Rules

1. **One item per line** - Each line represents one ingredient or step
2. **Sections prefixed with `#`** - Lines starting with `#` become section headers
3. **Empty lines ignored** - Blank lines are filtered out during parsing
4. **Newlines scrubbed** - Any embedded newlines in item text are converted to spaces
5. **Sub-recipe links use `[recipe:Name]`** - Existing pattern from `RecipeTextRenderer`

### Sub-Recipe Link Format

**Leverages existing pattern:** The codebase already uses `[recipe:Name]` notation in step text (see `lib/src/utils/recipe_text_renderer.dart` line 281). This is parsed and rendered as tappable links that resolve by recipe title.

**For ingredients with sub-recipe links:**
```
2 cups [recipe:Chicken Stock]
1 batch [recipe:Pizza Dough]
```

**Serialization (when converting to text):**
- If ingredient has `recipeId`, look up recipe by ID to get its title
- The ingredient name likely already contains the recipe name (e.g., "2 cups Chicken Stock")
- We append `[recipe:Title]` to mark it as linked
- Example: `{name: "2 cups Chicken Stock", recipeId: "abc-123"}` → `2 cups Chicken Stock [recipe:Chicken Stock]`

**Note:** This creates some redundancy ("Chicken Stock" appears twice), but it's explicit and lossless. The brackets clearly mark which part is the linked recipe.

**Deserialization (when parsing back):**
- Detect `[recipe:Name]` pattern in each line
- Extract the recipe name and look it up via `recipeByTitleProvider`
- If found, set `recipeId` to the resolved recipe's ID
- Replace `[recipe:Name]` with just `Name` (remove brackets, keep the name!)
- Example: `2 cups [recipe:Chicken Stock]` → `{name: "2 cups Chicken Stock", recipeId: "resolved-id"}`

**Why keep the name:** The `name` field is what displays in the UI. The `recipeId` is just metadata for pantry matching. Without the name, "2 cups" alone would be meaningless.

**Edge cases:**
- Recipe not found by title → `recipeId` set to `null`, name includes the bracket text
- Multiple `[recipe:]` on one line → Only first one used for linking
- Recipe was renamed → Link breaks, but user can re-link

### Ingredients Text Format
```
# Dough
2 cups all-purpose flour
1 tsp salt
1 cup warm water
2 cups Chicken Stock [recipe:Chicken Stock]

# Filling
1 lb ground beef
1 batch Taco Seasoning [recipe:Taco Seasoning]
```

Parsing produces:
- `{type: 'section', name: 'Dough'}`
- `{type: 'ingredient', name: '2 cups all-purpose flour'}`
- `{type: 'ingredient', name: '1 tsp salt'}`
- `{type: 'ingredient', name: '1 cup warm water'}`
- `{type: 'ingredient', name: '2 cups Chicken Stock', recipeId: '<resolved-id>'}`
- `{type: 'section', name: 'Filling'}`
- `{type: 'ingredient', name: '1 lb ground beef'}`
- `{type: 'ingredient', name: '1 batch Taco Seasoning', recipeId: '<resolved-id>'}`

### Steps Text Format
```
# Preparation
Preheat oven to 350F.
Mix dry ingredients in a large bowl.

# Assembly
Roll dough into 6 inch circles.
Add filling to center of each circle.
```

Parsing produces:
- `{type: 'section', text: 'Preparation'}`
- `{type: 'step', text: 'Preheat oven to 350F.'}`
- etc.

**Note:** Steps don't have sub-recipe links at the data model level (they use inline `[recipe:Name]` in the text itself which is rendered by `RecipeTextRenderer`). No special handling needed for steps.

## Implementation Plan

### Phase 1: Create Standalone "Edit as Text" Modal Functions

**New File:** `lib/src/features/recipes/widgets/recipe_editor_form/modals/edit_as_text_modal.dart`

Create two entry-point functions that open stacked bottom sheets:

```dart
/// Shows a modal for editing ingredients as text.
/// Returns the updated ingredients list, or null if cancelled.
Future<List<Ingredient>?> showEditIngredientsAsTextModal(
  BuildContext context, {
  required List<Ingredient> ingredients,
  required WidgetRef ref,
}) async {
  return WoltModalSheet.show<List<Ingredient>>(
    context: context,
    useRootNavigator: true,
    pageListBuilder: (bottomSheetContext) => [
      _EditIngredientsAsTextPage.build(
        context: bottomSheetContext,
        ingredients: ingredients,
        ref: ref,
      ),
    ],
  );
}

/// Shows a modal for editing steps as text.
/// Returns the updated steps list, or null if cancelled.
Future<List<Step>?> showEditStepsAsTextModal(
  BuildContext context, {
  required List<Step> steps,
}) async {
  return WoltModalSheet.show<List<Step>>(
    context: context,
    useRootNavigator: true,
    pageListBuilder: (bottomSheetContext) => [
      _EditStepsAsTextPage.build(
        context: bottomSheetContext,
        steps: steps,
      ),
    ],
  );
}
```

**Key points:**
- Each function takes current data and returns updated data (or null if cancelled)
- Opens as a stacked sheet on top of the recipe editor
- No changes needed to `add_recipe_modal.dart`
- Self-contained - no shared state management needed

### Phase 2: Add Menu Items to Sections

**File:** `lib/src/features/recipes/widgets/recipe_editor_form/sections/ingredients_section.dart`

Add callback prop and menu item:
```dart
class IngredientsSection extends StatefulWidget {
  // ... existing props
  final VoidCallback? onEditAsText;  // NEW
}

// In AppOverflowButton items:
AdaptiveMenuItem(
  title: 'Edit as Text',
  icon: const Icon(Icons.edit_note),
  onTap: () => widget.onEditAsText?.call(),
),
```

**File:** `lib/src/features/recipes/widgets/recipe_editor_form/sections/steps_section.dart`

Same pattern:
```dart
class StepsSection extends StatefulWidget {
  final VoidCallback? onEditAsText;  // NEW
}
```

**File:** `lib/src/features/recipes/widgets/recipe_editor_form/recipe_editor_form.dart`

Handle the callbacks directly - open the stacked modal and update state:
```dart
IngredientsSection(
  // ... existing props
  onEditAsText: () => _openEditIngredientsAsText(),
)

StepsSection(
  // ... existing props
  onEditAsText: () => _openEditStepsAsText(),
)

Future<void> _openEditIngredientsAsText() async {
  final result = await showEditIngredientsAsTextModal(
    context,
    ingredients: _ingredients,
    ref: ref,
  );
  if (result != null) {
    setState(() {
      _ingredients = result;
    });
  }
}

Future<void> _openEditStepsAsText() async {
  final result = await showEditStepsAsTextModal(
    context,
    steps: _steps,
  );
  if (result != null) {
    setState(() {
      _steps = result;
    });
  }
}
```

### Phase 3: Create Text Serialization Utilities

**New File:** `lib/src/features/recipes/widgets/recipe_editor_form/utils/text_serialization.dart`

```dart
import 'package:uuid/uuid.dart';
import '../../../../../../database/models/ingredients.dart';
import '../../../../../../database/models/steps.dart';
import '../../../../../repositories/recipe_repository.dart';

/// Regex pattern for [recipe:Name] - matches existing RecipeTextRenderer pattern
final _recipePattern = RegExp(r'\[recipe:([^\]]+)\]');

/// Converts a list of Ingredients to text format.
///
/// Async because we need to look up recipe titles for sub-recipe links.
/// Pass the repository to resolve recipeId → recipe title.
Future<String> ingredientsToText(
  List<Ingredient> ingredients,
  RecipeRepository repository,
) async {
  final lines = <String>[];

  for (final ing in ingredients) {
    String text = ing.name.replaceAll('\n', ' ').trim();

    if (ing.type == 'section') {
      if (text.isNotEmpty) {
        lines.add('# $text');
      }
      continue;
    }

    // If ingredient has a sub-recipe link, append [recipe:Title]
    if (ing.recipeId != null && ing.recipeId!.isNotEmpty) {
      final linkedRecipe = await repository.getRecipeById(ing.recipeId!);
      if (linkedRecipe != null) {
        text = '$text [recipe:${linkedRecipe.title}]';
      }
    }

    if (text.isNotEmpty) {
      lines.add(text);
    }
  }

  return lines.join('\n');
}

/// Parses text format back to Ingredients.
///
/// Async because we need to resolve recipe names to IDs for sub-recipe links.
/// Pass the repository to resolve recipe title → recipeId.
Future<List<Ingredient>> textToIngredients(
  String text,
  RecipeRepository repository,
) async {
  final lines = text.split('\n');
  final ingredients = <Ingredient>[];
  final uuid = const Uuid();

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    // Check for section header
    if (line.startsWith('#')) {
      final name = line.substring(1).trim();
      ingredients.add(Ingredient(
        id: uuid.v4(),
        type: 'section',
        name: name.isEmpty ? 'New Section' : name,
      ));
      continue;
    }

    // Check for [recipe:Name] pattern
    String? recipeId;
    String ingredientName = line;

    final match = _recipePattern.firstMatch(line);
    if (match != null) {
      final recipeName = match.group(1)!;
      // Try to resolve recipe by title
      final recipe = await repository.getRecipeByTitle(recipeName);
      if (recipe != null) {
        recipeId = recipe.id;
        // Replace [recipe:Name] with just Name (remove brackets, keep the name!)
        // This preserves the ingredient description while stripping the link syntax
        ingredientName = line.replaceFirst(_recipePattern, recipeName).trim();
      }
      // If recipe not found, leave the text as-is (including brackets)
      // so user knows the link didn't resolve
    }

    ingredients.add(Ingredient(
      id: uuid.v4(),
      type: 'ingredient',
      name: ingredientName,
      recipeId: recipeId,
      primaryAmount1Value: '',
      primaryAmount1Unit: 'g',
      primaryAmount1Type: 'weight',
    ));
  }

  return ingredients;
}

/// Converts a list of Steps to text format.
///
/// Synchronous - steps don't have sub-recipe links at the model level.
/// (They use inline [recipe:Name] in the text itself, which we preserve as-is)
String stepsToText(List<Step> steps) {
  return steps.map((step) {
    final text = step.text.replaceAll('\n', ' ').trim();
    if (step.type == 'section') {
      return '# $text';
    }
    return text;
  }).where((line) => line.isNotEmpty).join('\n');
}

/// Parses text format back to Steps.
///
/// Synchronous - no recipe resolution needed for steps.
List<Step> textToSteps(String text) {
  final lines = text.split('\n');
  final uuid = const Uuid();

  return lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) {
        if (line.startsWith('#')) {
          final stepText = line.substring(1).trim();
          return Step(
            id: uuid.v4(),
            type: 'section',
            text: stepText.isEmpty ? 'New Section' : stepText,
          );
        }
        return Step(
          id: uuid.v4(),
          type: 'step',
          text: line,
        );
      })
      .toList();
}
```

**Key Design Decisions:**

1. **Async for ingredients** - Recipe ID ↔ title lookup requires database access
2. **Sync for steps** - Steps preserve `[recipe:Name]` as literal text (rendered by `RecipeTextRenderer`)
3. **Repository passed in** - Keeps serialization testable and decoupled
4. **Graceful fallback** - If recipe not found by title, brackets stay in text as visual indicator

### Phase 4: Create Edit as Text Page Widgets

**In the same file:** `lib/src/features/recipes/widgets/recipe_editor_form/modals/edit_as_text_modal.dart`

```dart
class _EditIngredientsAsTextPage {
  static WoltModalSheetPage build({
    required BuildContext context,
    required List<Ingredient> ingredients,
    required WidgetRef ref,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () => Navigator.of(context).pop(), // Cancel - return null
        child: Text('Cancel', style: TextStyle(
          color: AppColors.of(context).primary,
          fontSize: 17,
        )),
      ),
      // Trailing "Update" button is inside the content widget
      // (needs access to text controller state)
      child: _EditIngredientsContent(
        ingredients: ingredients,
        ref: ref,
      ),
    );
  }
}

class _EditIngredientsContent extends ConsumerStatefulWidget {
  final List<Ingredient> ingredients;
  final WidgetRef ref;

  const _EditIngredientsContent({
    required this.ingredients,
    required this.ref,
  });

  @override
  ConsumerState<_EditIngredientsContent> createState() => _EditIngredientsContentState();
}

class _EditIngredientsContentState extends ConsumerState<_EditIngredientsContent> {
  late TextEditingController _textController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _initializeText();
  }

  Future<void> _initializeText() async {
    final repository = ref.read(recipeRepositoryProvider);
    final text = await ingredientsToText(widget.ingredients, repository);
    _textController.text = text;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onUpdate() async {
    final repository = ref.read(recipeRepositoryProvider);
    final ingredients = await textToIngredients(_textController.text, repository);
    if (mounted) {
      Navigator.of(context).pop(ingredients); // Return updated list
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with title and Update button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Ingredients',
                style: AppTypography.h4.copyWith(color: colors.textPrimary),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _onUpdate,
                child: Text('Update', style: TextStyle(
                  color: colors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'One ingredient per line. Use # for sections. Link recipes with [recipe:Name].',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.lg),
          // Text field - expands to fill available space
          Flexible(
            child: AppTextFieldSimple(
              controller: _textController,
              placeholder: '# Section\n1 cup flour\n2 cups Chicken Stock [recipe:Chicken Stock]\n...',
              multiline: true,
              minLines: 10,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Steps version is similar but simpler (synchronous):**

```dart
class _EditStepsAsTextPage {
  static WoltModalSheetPage build({
    required BuildContext context,
    required List<Step> steps,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Cancel', style: TextStyle(
          color: AppColors.of(context).primary,
          fontSize: 17,
        )),
      ),
      child: _EditStepsContent(steps: steps),
    );
  }
}

class _EditStepsContent extends StatefulWidget {
  final List<Step> steps;

  const _EditStepsContent({required this.steps});

  @override
  State<_EditStepsContent> createState() => _EditStepsContentState();
}

class _EditStepsContentState extends State<_EditStepsContent> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: stepsToText(widget.steps));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    final steps = textToSteps(_textController.text);
    Navigator.of(context).pop(steps);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Steps',
                style: AppTypography.h4.copyWith(color: colors.textPrimary),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _onUpdate,
                child: Text('Update', style: TextStyle(
                  color: colors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'One step per line. Use # for sections.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.lg),
          Flexible(
            child: AppTextFieldSimple(
              controller: _textController,
              placeholder: '# Preparation\nPreheat oven to 350°F.\nMix ingredients.\n...',
              multiline: true,
              minLines: 10,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Key simplifications from stacked sheet pattern:**
- No formKey or pageIndexNotifier needed
- Data passed in, result returned via `Navigator.pop(result)`
- Each modal is self-contained
- Ingredients modal is async (recipe lookup), Steps modal is sync

## File Changes Summary

### New Files
1. `lib/src/features/recipes/widgets/recipe_editor_form/utils/text_serialization.dart`
   - `ingredientsToText()` - async, handles sub-recipe link serialization
   - `textToIngredients()` - async, handles sub-recipe link resolution
   - `stepsToText()` - sync
   - `textToSteps()` - sync

2. `lib/src/features/recipes/widgets/recipe_editor_form/modals/edit_as_text_modal.dart`
   - `showEditIngredientsAsTextModal()` - entry point function
   - `showEditStepsAsTextModal()` - entry point function
   - `_EditIngredientsAsTextPage` - page builder
   - `_EditIngredientsContent` - content widget (ConsumerStatefulWidget)
   - `_EditStepsAsTextPage` - page builder
   - `_EditStepsContent` - content widget (StatefulWidget)

### Modified Files
1. `lib/src/features/recipes/widgets/recipe_editor_form/recipe_editor_form.dart`
   - Add `_openEditIngredientsAsText()` method
   - Add `_openEditStepsAsText()` method
   - Pass `onEditAsText` callbacks to section widgets

2. `lib/src/features/recipes/widgets/recipe_editor_form/sections/ingredients_section.dart`
   - Add `onEditAsText` callback prop
   - Add "Edit as Text" menu item to `AppOverflowButton`

3. `lib/src/features/recipes/widgets/recipe_editor_form/sections/steps_section.dart`
   - Add `onEditAsText` callback prop
   - Add "Edit as Text" menu item to `AppOverflowButton`

### Unchanged Files
- `lib/src/features/recipes/views/add_recipe_modal.dart` - No changes needed!

## UI/UX Design Details

### Edit as Text Page Layout

```
┌─────────────────────────────────────┐
│  Back                      Update   │  <- Nav bar
├─────────────────────────────────────┤
│                                     │
│  Edit Ingredients                   │  <- Title (h4)
│                                     │
│  One ingredient per line.           │  <- Helper text (body, secondary)
│  Use # for section headers.         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ # Dough                     │   │  <- Multi-line text field
│  │ 2 cups flour                │   │     (fills remaining space)
│  │ 1 tsp salt                  │   │
│  │                             │   │
│  │ # Filling                   │   │
│  │ 1 lb ground beef           │   │
│  │ ...                         │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Design System Adherence
- Use `AppSpacing.lg` (16px) for padding
- Use `AppTypography.h4` for title
- Use `AppTypography.body` with `colors.textSecondary` for helper text
- Use `AppTextFieldSimple` for the text area
- Use `CupertinoButton` for Back button (matches existing pattern)
- Text button for "Update" (matches "Create"/"Save" pattern)

### Accessibility Considerations
- Clear helper text explaining the format
- Placeholder text showing example format
- Large touch targets for navigation buttons

## Edge Cases & Validation

### Parsing Edge Cases
1. **Empty input** - Returns empty list
2. **Only whitespace** - Returns empty list
3. **Section with no name** (just `#`) - Creates section with name "New Section"
4. **Multiple `#` at start** - Treat as section (e.g., `## Heading` becomes section "# Heading")
5. **`#` in middle of line** - Not a section (e.g., "Item #3" is ingredient)

### Sub-Recipe Link Edge Cases
1. **Recipe not found by title** - Keep brackets in text as visual indicator (user can see it didn't resolve)
2. **Multiple `[recipe:]` on one line** - Only first match used for `recipeId`, rest kept as literal text
3. **Recipe was renamed** - Link breaks on re-parse; user would need to update text manually
4. **Circular reference** - Not our problem; pantry matching already handles this
5. **Recipe title contains `]`** - Regex stops at first `]`, so `[recipe:Foo]Bar]` → matches "Foo"

### Data Preservation Summary

| Field | Preserved? | Notes |
|-------|------------|-------|
| `type` (section/ingredient) | ✅ Yes | Via `#` prefix |
| `name` / `text` | ✅ Yes | Main content |
| `recipeId` (sub-recipe) | ✅ Yes | Via `[recipe:Name]` notation |
| `terms` | ❌ No | Will be re-canonicalized |
| `isCanonicalised` | ❌ No | Reset to false |
| `category` | ❌ No | Will be re-derived |
| `note` | ❌ No | Lost (rarely used) |
| `timerDurationSeconds` | ❌ No | Lost (steps only) |
| `amounts` (primary/secondary) | ❌ No | Reset to defaults |

**What this means:**
- Sub-recipe links are preserved (the main concern)
- Canonicalization terms are regenerated automatically by the system
- Step timers and notes are lost (minor, rarely used)
- Ingredient amounts are lost (parsed from name text anyway)

### Helper Text for UI

**For Ingredients:**
> "One ingredient per line. Use # for sections. Link recipes with [recipe:Name]."

**For Steps:**
> "One step per line. Use # for sections."

## Testing Considerations

### Unit Tests
- `ingredientsToText()` serialization
- `textToIngredients()` parsing
- `stepsToText()` serialization
- `textToSteps()` parsing
- Edge cases (empty, whitespace, section variations)

### Integration Tests
- Navigate to Edit as Text page
- Modify text and tap Update
- Verify ingredients/steps updated correctly
- Navigate back shows updated items

### Manual Testing
- Copy/paste from external source
- Edit existing ingredients in text mode
- Test with Japanese text (should work - just plain text)
- Test with very long ingredient lists

## Questions for Clarification

1. ~~**Sub-recipe link preservation?**~~ ✅ **RESOLVED**
   - Using existing `[recipe:Name]` pattern from `RecipeTextRenderer`
   - Serialization: Look up recipe title from ID
   - Deserialization: Resolve recipe ID from title

2. **Should we support exporting text (copy to clipboard)?**
   - Could add "Copy" button in addition to the text field
   - User can already select-all and copy manually
   - Recommendation: Not in v1, can add later if requested

3. **How to handle very long lists?**
   - Current design uses expanding text field
   - For 100+ items, might want virtualization
   - Recommendation: Start simple, optimize if needed

4. **Should "Edit as Text" be a separate full-screen page or stay in modal?**
   - Recommendation: Stay in modal for consistency with folders/tags pattern

## Implementation Order

1. Create `text_serialization.dart` utility functions
2. Create `edit_as_text_modal.dart` with both modal functions and page widgets
3. Add `onEditAsText` prop to `IngredientsSection` + menu item
4. Add `onEditAsText` prop to `StepsSection` + menu item
5. Add `_openEditIngredientsAsText()` and `_openEditStepsAsText()` to `RecipeEditorFormState`
6. Wire up callbacks in `RecipeEditorForm.build()`
7. Test all flows

**Estimated complexity: Low-Medium**
- Only 2 new files
- 3 modified files (minimal changes)
- No changes to existing modal structure
- Stacked sheet pattern is simple and well-established
