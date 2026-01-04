# Ingredient Display Name Implementation Plan

## Problem Statement

When importing recipes from websites, ingredients often contain verbose preparation instructions:

```
"2 boneless, skin-on chicken thighs ((about 7.4 oz (210 g) each; use the largest chicken thighs you can find))"
"2 green onions/scallions ((you can substitute leek or Tokyo negi))"
"5 slices ginger ((peeled and thinly cut, from 1 knob))"
```

**Two related issues:**

1. **Canonicalization terms include prep instructions** - The AI sometimes includes preparation notes in canonical terms, which pollutes pantry matching.

2. **Shopping list uses verbose surface form** - When adding ingredients to shopping list, the `IngredientParserService.parse()` only strips quantity/unit, leaving prep instructions intact:
   - Input: `"2 boneless, skin-on chicken thighs ((about 7.4 oz...))"`
   - Current cleanName: `"boneless, skin-on chicken thighs ((about 7.4 oz...))"`
   - Desired: `"boneless, skin-on chicken thighs"`

## Solution: Add `displayName` Field

Have the AI generate a clean, shopping-list-friendly display name during canonicalization.

### Data Model Change

```
surfaceForm: "2 boneless, skin-on chicken thighs ((about 7.4 oz each; use the largest...))"
                    ↓ AI Canonicalization ↓
displayName: "boneless, skin-on chicken thighs"  ← NEW FIELD
terms: ["chicken thighs", "boneless chicken thighs"]
category: "Meat & Seafood"
```

---

## Current Architecture Summary

### Backend (`/users/matt/repos/recipe_app_server/`)

| Component | File | Purpose |
|-----------|------|---------|
| API Endpoint | `src/controllers/ingredientController.ts` | `POST /v1/ingredients/analyze` |
| Core Service | `src/services/openaiService.ts` | OpenAI calls, caching, response parsing |
| Type Definitions | `src/types/index.ts` | Zod schemas, TypeScript types |
| Prompts | `src/prompts/canonicalization/en.ts`, `ja.ts` | Locale-specific AI instructions |
| Cache DB | `src/services/dbService.ts` | SQLite cache for terms/categories |

**Current Response Schema (openaiService.ts:43-49):**
```typescript
{
  original: { name: string },
  terms: string[],
  category: IngredientCategory
}
```

### Frontend (`/Users/matt/repos/flutter_test_2/`)

| Component | File | Purpose |
|-----------|------|---------|
| Ingredient Model | `lib/database/models/ingredients.dart` | Dart model with JSON serialization |
| Canonicalization Service | `lib/src/services/ingredient_canonicalization_service.dart` | API client, response parsing |
| Queue Manager | `lib/src/managers/ingredient_term_queue_manager.dart` | Async processing pipeline |
| Shopping List Add | `lib/src/features/recipes/widgets/recipe_view/add_recipe_ingredients_to_shopping_list_modal.dart` | Recipe→shopping list flow |

**Current Ingredient Fields (ingredients.dart):**
- `name` - Raw ingredient text (surface form)
- `terms` - List<IngredientTerm> for matching
- `category` - From API
- `isCanonicalised` - Processing flag
- No `displayName` field

---

## Implementation Plan

### Phase 1: Backend Schema & Prompt Updates

#### 1.1 Update Type Definitions

**File:** `src/types/index.ts`

Add `displayName` to the analyzed ingredient response type.

**Current (lines 73-77):**
```typescript
export interface AnalyzedIngredient {
  original: IngredientInput;
  terms: string[];
  category: IngredientCategory;
}
```

**New:**
```typescript
export interface AnalyzedIngredient {
  original: IngredientInput;
  displayName: string;        // NEW: Clean name for shopping lists
  terms: string[];
  category: IngredientCategory;
}
```

#### 1.2 Update Zod Response Schema

**File:** `src/services/openaiService.ts`

Update the Zod schema used for OpenAI structured output.

**Current schema (lines 43-49):**
```typescript
const ingredientSchema = z.object({
  original: z.object({ name: z.string() }),
  terms: z.array(z.string()),
  category: ingredientCategoryEnum,
});
```

**New schema:**
```typescript
const ingredientSchema = z.object({
  original: z.object({ name: z.string() }),
  displayName: z.string(),    // NEW
  terms: z.array(z.string()),
  category: ingredientCategoryEnum,
});
```

Also update the non-English schema (lines 56-63) to include `displayName`.

#### 1.3 Update Cache Schema

**File:** `src/services/dbService.ts`

Add a `display_name` column to the existing `terms` table. Since we're deleting the cache DB anyway, no migration needed.

**Updated table schema:**
```sql
CREATE TABLE IF NOT EXISTS terms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ingredient_name TEXT NOT NULL,
  locale TEXT NOT NULL DEFAULT 'en',
  terms TEXT NOT NULL,           -- JSON array
  display_name TEXT,             -- NEW: nullable for backwards compat
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ingredient_name, locale)
);
```

**Update existing functions:**

```typescript
// Update getTermsByIngredient to also return display_name
function getTermsByIngredient(ingredientName: string, locale: string = 'en'):
  { terms: string[], displayName: string | null } | null

// Update saveTerms to also save display_name
function saveTerms(ingredientName: string, locale: string, terms: string[], displayName: string): void
```

#### 1.4 Update Cache Lookup Logic

**File:** `src/services/openaiService.ts`

Modify `separateCachedIngredients()` to handle the updated return type from `getTermsByIngredient()`.

**Current (lines 116-140):** Returns cached terms and categories separately.

**New:** `getTermsByIngredient()` now returns `{ terms, displayName }`. Update the cache lookup to extract both and include displayName in the cached results.

Update the cache save logic (around lines 166-176) to pass displayName to `saveTerms()`.

#### 1.5 Update Prompts - English

**File:** `src/prompts/canonicalization/en.ts`

**Current USER_PROMPT (lines 9-32):** Instructs AI to generate terms and categories.

**Updated USER_PROMPT with displayName and refined term guidance:**

```typescript
export const USER_PROMPT = `
For each ingredient, provide:

1. **displayName**: A clean, concise name suitable for a shopping list.
   - Remove quantities, units, and measurements
   - Remove preparation instructions (chopped, diced, peeled, sliced, etc.)
   - Remove parenthetical notes, tips, and substitution suggestions
   - Remove weight/size specifications like "(about 7.4 oz)"
   - Keep distinguishing characteristics important for purchase (boneless, skin-on, smoked, extra-firm, etc.)
   - Keep variety/type info (yellow onions, russet potatoes, San Marzano tomatoes, etc.)

   Examples:
   - "2 boneless, skin-on chicken thighs ((about 7.4 oz each))" → "boneless, skin-on chicken thighs"
   - "5 slices ginger ((peeled and thinly cut))" → "ginger"
   - "2 green onions/scallions ((substitute leek))" → "green onions"
   - "1 cup all-purpose flour, sifted" → "all-purpose flour"
   - "14 oz extra-firm tofu, pressed and cubed" → "extra-firm tofu"

2. **terms**: Canonical matching terms for pantry matching.

   Generate progressively more generic forms, but be thoughtful about what to include:

   **DO include in terms:**
   - The ingredient name itself and common variations
   - Distinguishing characteristics that affect what you'd stock (smoked vs unsmoked, dried vs fresh, whole vs ground)
   - Common alternate names (scallions/green onions, cilantro/coriander leaves)
   - Both singular and plural forms

   **DO NOT include in terms:**
   - Preparation instructions (chopped, diced, minced, sifted, melted, sliced, cubed, pressed)
   - Weight or size specifications (7.4 oz, large, medium)
   - Cooking tips or substitution suggestions
   - Parenthetical notes from the original text

   **Use judgment for qualifiers:**
   - Keep qualifiers that affect pantry tracking: "extra-firm tofu" vs "silken tofu" are different items
   - Keep qualifiers that affect purchase: "boneless chicken" vs "bone-in chicken"
   - Remove qualifiers that are just prep: "thinly sliced ginger" → just "ginger"

3. **category**: One of the 13 predefined categories (existing instructions remain)
`;
```

#### 1.6 Update Prompts - Japanese

**File:** `src/prompts/canonicalization/ja.ts`

Add equivalent `displayName` and refined term instructions in Japanese:

```typescript
1. **displayName**: 買い物リスト用の簡潔な表示名
   - 分量、単位、計量を削除
   - 下ごしらえの指示（みじん切り、薄切り、皮をむいた等）を削除
   - 括弧内の注釈、ヒント、代替案を削除
   - 重量・サイズ情報（約210g等）を削除
   - 購入時に重要な特徴は保持（骨なし、皮付き、燻製、木綿等）
   - 品種・種類情報は保持（黄玉ねぎ、メークイン等）

   例：
   - "鶏もも肉 2枚（骨なし、皮付き、約210g）" → "骨なし皮付き鶏もも肉"
   - "生姜 5切れ（皮をむいて薄切り）" → "生姜"
   - "木綿豆腐 1丁（水切りして角切り）" → "木綿豆腐"

2. **terms**: パントリーマッチング用の正規化された用語

   **含めるべきもの：**
   - 食材名とその一般的なバリエーション
   - 在庫管理に影響する特徴（燻製/非燻製、乾燥/生、ホール/粉末）
   - 一般的な別名
   - 漢字、ひらがな、カタカナの表記バリエーション

   **含めないもの：**
   - 下ごしらえの指示（みじん切り、薄切り、角切り等）
   - 重量・サイズ情報
   - 調理のコツや代替案
   - 括弧内の注釈

   **修飾語の判断：**
   - 在庫管理に影響するものは保持：「木綿豆腐」vs「絹ごし豆腐」は別物
   - 購入に影響するものは保持：「骨なし鶏肉」vs「骨付き鶏肉」
   - 単なる下ごしらえは削除：「薄切り生姜」→「生姜」
```

---

### Phase 2: Frontend Model Updates

#### 2.1 Update Ingredient Model

**File:** `lib/database/models/ingredients.dart`

Add `displayName` field to the Ingredient class.

**Current fields (lines 10-35):**
```dart
@JsonSerializable()
class Ingredient {
  final String id;
  final String type;
  final String name;
  // ... measurement fields ...
  final List<IngredientTerm>? terms;
  final bool isCanonicalised;
  final String? category;
  // ...
}
```

**Add new field:**
```dart
@JsonSerializable()
class Ingredient {
  final String id;
  final String type;
  final String name;
  final String? displayName;  // NEW: Clean name for shopping lists
  // ... rest of fields ...
}
```

**Update constructor, fromJson, toJson, and copyWith:**

1. Add `this.displayName` to constructor
2. Update `fromJson` (line 57-83) to parse `displayName`:
   ```dart
   displayName: json['displayName'] as String?,
   ```
3. Generated `toJson` will auto-include it
4. Update `copyWith` to include `displayName` parameter

#### 2.2 Regenerate JSON Serialization

Run build_runner to regenerate `ingredients.g.dart`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Phase 3: Frontend Service Updates

#### 3.1 Update CanonicalizeResult

**File:** `lib/src/services/ingredient_canonicalization_service.dart`

**Current CanonicalizeResult (lines 73-83):**
```dart
class CanonicalizeResult {
  final Map<String, List<IngredientTerm>> terms;
  final Map<String, ConverterData> converters;
  final Map<String, String> categories;
}
```

**Add displayNames:**
```dart
class CanonicalizeResult {
  final Map<String, List<IngredientTerm>> terms;
  final Map<String, ConverterData> converters;
  final Map<String, String> categories;
  final Map<String, String> displayNames;  // NEW: name → displayName

  CanonicalizeResult({
    required this.terms,
    required this.converters,
    required this.categories,
    required this.displayNames,  // NEW
  });
}
```

#### 3.2 Update Response Parsing

**File:** `lib/src/services/ingredient_canonicalization_service.dart`

**Current parsing (lines 112-173):** Extracts terms, converters, categories.

**Add displayName extraction (around line 165):**
```dart
// Extract displayName
final displayNames = <String, String>{};
for (final item in ingredientsList) {
  final originalName = item['original']?['name'] as String?;
  final displayName = item['displayName'] as String?;
  if (originalName != null && displayName != null && displayName.isNotEmpty) {
    displayNames[originalName] = displayName;
  }
}

return CanonicalizeResult(
  terms: terms,
  converters: converters,
  categories: categories,
  displayNames: displayNames,  // NEW
);
```

---

### Phase 4: Queue Manager Updates

#### 4.1 Update Ingredient Term Queue Manager

**File:** `lib/src/managers/ingredient_term_queue_manager.dart`

**Current term merging (lines 340-373):** Updates ingredient with terms, category, isCanonicalised.

**Add displayName to update (around line 369):**
```dart
// Get displayName from results
final displayName = results.displayNames[ingredientName];

updatedIngredient = originalIngredient.copyWith(
  terms: mergedTerms,
  isCanonicalised: true,
  category: category,
  displayName: displayName,  // NEW
);
```

#### 4.2 Update Recipe Save Logic

The queue manager already saves the full updated ingredient to the recipe (lines 427-433). Since `displayName` is now part of the Ingredient model and copyWith, it will be persisted automatically.

---

### Phase 5: Shopping List Integration

#### 5.1 Update Shopping List Add Logic

**File:** `lib/src/features/recipes/widgets/recipe_view/add_recipe_ingredients_to_shopping_list_modal.dart`

**Current logic (lines 292-302):**
```dart
final parseResult = parser.parse(ingredient.name);
final cleanName = parseResult.cleanName.isNotEmpty
    ? parseResult.cleanName
    : ingredient.name;

await shoppingListRepository.addItem(
  shoppingListId: currentListId,
  name: cleanName,  // Uses parsed cleanName
  userId: userId,
  householdId: null,
);
```

**New logic - prefer displayName:**
```dart
// Prefer displayName if available, fall back to parsed cleanName
String itemName;
if (ingredient.displayName != null && ingredient.displayName!.isNotEmpty) {
  itemName = ingredient.displayName!;
} else {
  final parseResult = parser.parse(ingredient.name);
  itemName = parseResult.cleanName.isNotEmpty
      ? parseResult.cleanName
      : ingredient.name;
}

await shoppingListRepository.addItem(
  shoppingListId: currentListId,
  name: itemName,
  userId: userId,
  householdId: null,
);
```

#### 5.2 Alternative Entry Point - Ingredient Matches Bottom Sheet

**File:** `lib/src/features/recipes/widgets/recipe_view/ingredient_matches_bottom_sheet.dart`

If ingredients can be added to shopping list from this modal, apply the same displayName preference logic there.

Search for calls to `shoppingListRepository.addItem` or similar and update.

---

### Phase 6: Migration & Backwards Compatibility

#### 6.1 Backend Cache

**Approach:** Delete the SQLite cache database manually before deploying backend changes. This ensures all ingredients are re-processed with the new prompts that generate `displayName` and use the refined term guidance.

```bash
# On the server, delete the cache DB
rm /path/to/db/ingredients.sqlite
```

The cache will be rebuilt as ingredients are processed.

#### 6.2 Frontend Compatibility

The `displayName` field is nullable (`String?`), so existing data works seamlessly:

1. **Existing recipes:** Will have `displayName: null` until re-canonicalized
2. **Shopping list fallback:** Already implemented in Phase 5.1 - falls back to parsed cleanName
3. **No migration required:** Recipes will get displayName on next canonicalization

#### 6.3 Triggering Re-canonicalization

Existing recipes won't automatically get displayName. This is acceptable because:

1. **On next recipe edit:** When user edits a recipe, ingredients get re-canonicalized automatically
2. **Shopping list works:** Falls back gracefully to parsed cleanName for old recipes
3. **New imports:** All newly imported recipes will have displayName from the start

**No forced migration needed** - lazy update is sufficient.

---

## File Change Summary

### Backend Changes

| File | Change |
|------|--------|
| `src/types/index.ts` | Add `displayName: string` to `AnalyzedIngredient` interface |
| `src/services/openaiService.ts` | Update Zod schema, update cache lookup/save to handle displayName |
| `src/services/dbService.ts` | Add `display_name` column to `terms` table, update get/save functions |
| `src/prompts/canonicalization/en.ts` | Add displayName generation + refined term instructions |
| `src/prompts/canonicalization/ja.ts` | Add displayName generation + refined term instructions (Japanese) |

### Frontend Changes

| File | Change |
|------|--------|
| `lib/database/models/ingredients.dart` | Add `displayName` field, update constructor/copyWith |
| `lib/database/models/ingredients.g.dart` | Regenerated by build_runner |
| `lib/src/services/ingredient_canonicalization_service.dart` | Add `displayNames` to CanonicalizeResult, parse from API |
| `lib/src/managers/ingredient_term_queue_manager.dart` | Apply displayName when updating ingredient |
| `lib/src/features/recipes/widgets/recipe_view/add_recipe_ingredients_to_shopping_list_modal.dart` | Prefer displayName for shopping list item name |

---

## Testing Strategy

### Manual Testing

1. Import a recipe with verbose ingredient text from a website
2. Verify displayName is clean (no prep instructions)
3. Verify terms don't include prep instructions but do include distinguishing qualifiers
4. Add ingredients to shopping list
5. Verify shopping list shows clean displayName, not verbose text
6. Test fallback: edit an old recipe (without displayName) and add to shopping list - should use parsed cleanName

---

## Rollout Plan

1. **Delete backend cache:** Delete `ingredients.sqlite` to start fresh
2. **Deploy backend:** Deploy backend changes (schema, prompts, cache table)
3. **Verify API:** Test that API returns `displayName` correctly
4. **Deploy frontend:** Release app update with new model and logic
5. **Monitor:** Check for any API errors or unexpected displayName values

---

## Appendix: Example Transformations

| Original Surface Form | displayName | terms |
|-----------------------|-------------|-------|
| `2 boneless, skin-on chicken thighs ((about 7.4 oz each))` | `boneless, skin-on chicken thighs` | `["boneless chicken thighs", "chicken thighs", "chicken"]` |
| `2 green onions/scallions ((you can substitute leek))` | `green onions` | `["green onions", "scallions", "green onion"]` |
| `5 slices ginger ((peeled and thinly cut, from 1 knob))` | `ginger` | `["ginger", "fresh ginger"]` |
| `2 tsp neutral oil ((for searing))` | `neutral oil` | `["neutral oil", "vegetable oil", "oil"]` |
| `1 cup all-purpose flour, sifted` | `all-purpose flour` | `["all-purpose flour", "AP flour", "flour"]` |
| `14 oz extra-firm tofu, pressed and cubed` | `extra-firm tofu` | `["extra-firm tofu", "firm tofu", "tofu"]` |
| `1 lb smoked salmon, thinly sliced` | `smoked salmon` | `["smoked salmon", "salmon"]` |

### Key Principles Illustrated

1. **Prep instructions removed from both displayName and terms:**
   - "pressed and cubed" → removed
   - "thinly sliced" → removed
   - "sifted" → removed

2. **Distinguishing qualifiers kept in both:**
   - "extra-firm" (affects what you buy)
   - "smoked" (different product than fresh)
   - "boneless, skin-on" (affects purchase)

3. **Progressive term generification:**
   - Most specific first: "extra-firm tofu"
   - Then broader: "firm tofu", "tofu"
   - Enables flexible pantry matching
