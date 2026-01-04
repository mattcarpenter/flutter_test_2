# Backend AI Localization Analysis

## Executive Summary

The Stockpot app successfully implements UI localization (English/Japanese) with the Flutter l10n system. However, **backend AI operations are fundamentally English-biased** with only partial multilingual awareness. This document inventories all AI-powered backend endpoints, maps the data flows, and identifies gaps that need to be addressed for proper international support.

---

## Table of Contents

1. [AI-Powered Endpoints Inventory](#ai-powered-endpoints-inventory)
2. [Canonicalization System Deep Dive](#canonicalization-system-deep-dive)
3. [Recipe Extraction Flows](#recipe-extraction-flows)
4. [Category/Aisle System](#categoryaisle-system)
5. [FE-BE Interface & Data Models](#fe-be-interface--data-models)
6. [Identified Gaps](#identified-gaps)
7. [Database/Caching Considerations](#databasecaching-considerations)
8. [Recommendations](#recommendations)

---

## AI-Powered Endpoints Inventory

### Backend Technology Stack
- **Framework:** Express.js (Node.js/TypeScript)
- **AI Provider:** OpenAI (GPT-4.1, GPT-4.1-mini, GPT-4o, GPT-4o-mini)
- **Authentication:** HMAC-SHA256 signature + JWT (Supabase) for Plus features
- **Base URL:** `/v1/`

### Complete Endpoint List

| Endpoint | Path | Model | Auth | Plus? | Rate Limit | Purpose |
|----------|------|-------|------|-------|------------|---------|
| Brainstorm | `/ai-recipes/brainstorm` | GPT-4.1 | Optional | No | 10/day free | Generate recipe ideas from prompt |
| Generate | `/ai-recipes/generate` | GPT-4.1 | Required | Yes | 5/min, 100/day | Full recipe from selected idea |
| AI Preview | `/ai-recipes/preview-generate` | GPT-4.1-mini | No | No | 5/day | Recipe preview from idea |
| **Analyze** | `/ingredients/analyze` | GPT-4.1 | Sig only | No | 1500/24h | **Recipe ingredient canonicalization** |
| **Canonicalize** | `/ingredients/canonicalize` | GPT-4.1 | Sig only | No | 250/5min | **Pantry item canonicalization** |
| Clip Extract | `/clippings/extract-recipe` | GPT-4.1 | Required | Yes | 5/min, 100/day | Extract recipe from text |
| Clip Shop List | `/clippings/extract-shopping-list` | GPT-4.1 | Required | Yes | 5/min, 100/day | Extract shopping list from text |
| Clip Preview | `/clippings/preview-recipe` | GPT-4.1-mini | No | No | 5/day | Recipe preview from text |
| Clip Shop Preview | `/clippings/preview-shopping-list` | GPT-4.1-mini | No | No | 5/day | Shopping preview from text |
| Photo Extract | `/photo/extract-recipe` | GPT-4o | Required | Yes | 5/min, 50/day | Extract recipe from photo(s) |
| Photo Preview | `/photo/preview-recipe` | GPT-4o-mini | No | No | 2/day | Recipe preview from photo |
| Web Extract | `/web/extract-recipe` | GPT-4.1 | Required | Yes | 5/min, 100/day | Extract recipe from HTML |
| Web Preview | `/web/preview-recipe` | GPT-4.1-mini | No | No | 5/day | Recipe preview from HTML |
| Share Extract | `/share/extract-recipe` | GPT-4.1 | Required | Yes | 5/min, 100/day | Extract from social media share |
| Share Preview | `/share/preview-recipe` | GPT-4.1-mini | No | No | 5/day | Recipe preview from social share |

### Key Files (Backend)

| File | Purpose |
|------|---------|
| `src/routes/ingredientRoutes.ts` | Route definitions for canonicalization |
| `src/controllers/ingredientController.ts` | Request handlers |
| `src/services/openaiService.ts` | **All AI prompts and logic** |
| `src/services/dbService.ts` | SQLite cache for canonicalization |
| `src/services/clippingExtractionService.ts` | Text/clipping extraction |
| `src/services/photoExtractionService.ts` | Photo/vision extraction |
| `src/services/webExtractionService.ts` | HTML extraction (uses Readability) |
| `src/types/index.ts` | Zod schemas including category enum |
| `src/middleware/validation.ts` | Request validation |

---

## Canonicalization System Deep Dive

Canonicalization is the process of converting user-entered ingredient/item names into standardized "terms" used for matching (e.g., recipe-pantry matching).

### What Gets Canonicalized

| Source | Trigger | Endpoint | Queue Manager (Flutter) |
|--------|---------|----------|-------------------------|
| Recipe Ingredients | Recipe import/creation | `/ingredients/analyze` | `ingredient_term_queue_manager.dart` |
| Pantry Items | User adds item | `/ingredients/canonicalize` | `pantry_item_term_queue_manager.dart` |
| Shopping List Items | Extraction or manual entry | `/ingredients/analyze` | `shopping_list_item_term_queue_manager.dart` |

### Data Flow

```
User Input (e.g., "chopped yellow onion")
    ↓
Flutter Queue Manager (batches up to 50 items)
    ↓
POST /v1/ingredients/analyze (HMAC signed)
    ↓
Backend: Check SQLite cache (by lowercase name)
    ↓ (cache miss)
Backend: Construct OpenAI prompt
    ↓
OpenAI GPT-4.1: Returns terms + category
    ↓
Backend: Cache results in SQLite
    ↓
Response to Flutter
    ↓
Flutter: Merge terms (user term + API terms)
    ↓
Store in local database (ingredients.data JSON / pantry_items.terms)
```

### The Prompt (openaiService.ts lines 179-208)

The prompt instructs GPT-4.1 to:
1. Generate **progressively broader canonical terms** (most specific → generic)
2. Drop **preparation modifiers** ("chopped", "diced", "sifted")
3. Preserve **flavor/variety descriptors** ("balsamic", "dried cranberries")
4. Include **singular AND plural** forms
5. Assign one of **13 predefined categories**
6. Use **pragmatic shopping labels** (what users would actually write)

### Current Multilingual Handling

**Language detection exists but is limited:**

```typescript
// openaiService.ts lines 27-31
const JAPANESE_PATTERN = /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]/;
const KOREAN_PATTERN = /[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]/;
```

**When Japanese/Korean detected, extra instructions added:**

For Japanese:
> "Include ALL common Japanese spellings (kanji AND hiragana/katakana variants), English transliterations (romaji), and common English translations"
> Example: "玉ねぎ" → ["玉ねぎ", "たまねぎ", "タマネギ", "tamanegi", "onion", "onions"]

For Korean:
> Similar pattern with romanization + English translations

### What's Missing

| Gap | Impact |
|-----|--------|
| **No locale parameter** | Backend guesses language from text, can't optimize for user's locale |
| **Chinese not detected** | No special handling for Simplified/Traditional Chinese |
| **European languages not detected** | Spanish, French, German, Italian, etc. rely on GPT's general knowledge |
| **Output always includes English** | Good for matching, but categories are English-only |
| **Cache keyed by input text only** | Same input always returns same terms regardless of user locale |

### SQLite Cache Schema

```sql
-- Located at: recipe_app_server/db/ingredients.sqlite
-- Current size: ~835KB with ~2,851 cached items

CREATE TABLE terms (
  id INTEGER PRIMARY KEY,
  ingredient_name TEXT NOT NULL UNIQUE,  -- lowercase key
  terms TEXT NOT NULL,                    -- JSON array of strings
  created_at TIMESTAMP
);

CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  ingredient_name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL,                 -- One of 13 English categories
  created_at TIMESTAMP
);
```

---

## Recipe Extraction Flows

### Four Extraction Channels

| Channel | Source | Model | Input | Language Handling |
|---------|--------|-------|-------|-------------------|
| **Social Media** | Instagram, TikTok, YouTube | GPT-4.1 | OG tags (title + description) | Translates to English |
| **Web HTML** | Any recipe website | GPT-4.1 | Cleaned HTML (Readability) | Translates to English |
| **Text Clipping** | Copy/paste text | GPT-4.1 | Title + body text | Translates to English |
| **Photo** | Camera/gallery | GPT-4o (vision) | Base64 images | Translates to English |

### Extraction Prompt Pattern

All extraction prompts include similar language handling:

```
"Ingredients, steps, and description should be translated to English if the recipe
is in another language. Title can contain both the original language and English
translation if needed."
```

**This means:**
- Non-English recipes get **translated to English** during extraction
- Original language preserved only in title
- Ingredients are already in English when sent to canonicalization
- Works well for matching (all terms in English)
- **Problem:** User sees English ingredients even if they prefer Japanese UI

### Example Flow: Japanese User Imports Japanese Recipe

```
1. User shares Japanese recipe blog post
2. Backend extracts via GPT-4.1
3. Ingredients translated: "玉ねぎ 1個" → "1 onion"
4. Recipe saved with English ingredients
5. Pantry has: "玉ねぎ" (Japanese)
6. Canonicalization:
   - Recipe ingredient "onion" → terms: ["onion", "onions"]
   - Pantry item "玉ねぎ" → terms: ["玉ねぎ", "たまねぎ", "タマネギ", "tamanegi", "onion", "onions"]
7. Matching works! (intersection on "onion")
8. BUT: Recipe shows "onion" not "玉ねぎ" in UI
```

---

## Category/Aisle System

### Category Definition (Server)

```typescript
// types/index.ts lines 4-18
export const IngredientCategorySchema = z.enum([
  "Produce",
  "Meat & Seafood",
  "Dairy & Eggs",
  "Frozen Foods",
  "Grains, Cereals & Pasta",
  "Legumes, Nuts & Plant Proteins",
  "Baking & Sweeteners",
  "Oils, Fats & Vinegars",
  "Herbs, Spices & Seasonings",
  "Sauces, Condiments & Spreads",
  "Canned & Jarred Goods",
  "Beverages & Snacks",
  "Other"
]);
```

### Problem: Categories Are Hardcoded English

| What Happens | Where |
|--------------|-------|
| GPT-4.1 assigns English category | openaiService.ts prompt |
| Category stored as English string | SQLite cache + Drift database |
| UI displays raw category string | pantry_item_list.dart, shopping_list_items_list.dart |
| Only "Other" has translation | `pantryCategoryOther` in ARB files |

### Example: Japanese User's Shopping List

```
Shopping List Display:
┌─────────────────────────┐
│ Produce          ← English header (should be "野菜類")
│   ・玉ねぎ
│   ・にんじん
├─────────────────────────┤
│ Dairy & Eggs     ← English header (should be "乳製品・卵")
│   ・牛乳
│   ・卵
└─────────────────────────┘
```

### What Needs to Change

1. **Add translations for all 13 categories** to ARB files
2. **Create category mapping** in Flutter (raw category → localized label)
3. **OR:** Server returns localized category based on locale parameter

---

## FE-BE Interface & Data Models

### Request Signing (HMAC-SHA256)

```dart
// Flutter: api_signer.dart
static const String _signingKey = 'rcp_sk_7f3a9b2c4d5e6f8g1h2i3j4k5l6m7n8o';
static const String apiKey = 'rcp_live_flutter_v1';

// Canonical string format:
// METHOD\nPATH\nTIMESTAMP\nBODY_HASH
// For multipart: uses "MULTIPART" instead of body hash
```

### Current Request Schema (No Locale)

```typescript
// Backend: types/index.ts
export const IngredientInputSchema = z.object({
  name: z.string().min(1).max(100),
  quantity: z.number().optional(),
  unit: z.string().optional(),
});

export const AnalyzeIngredientsRequestSchema = z.object({
  ingredients: z.array(IngredientInputSchema).min(1).max(50),
  // ⚠️ NO locale parameter
});
```

### Flutter Data Models

```dart
// Ingredient with terms (recipe context)
class Ingredient {
  final String name;
  final List<IngredientTerm>? terms;  // [{value, source, sort}]
  final String? category;
  final bool isCanonicalised;
}

// Pantry item with terms
class PantryItem {
  final String name;
  final List<PantryItemTerm>? terms;  // [{value, source, sort}]
  final String? category;
  final bool isCanonicalised;
}
```

---

## Identified Gaps

### Gap 1: No Locale Parameter in API Requests

**Current State:**
- Flutter detects device locale for UI: `Localizations.localeOf(context).languageCode`
- API requests contain NO locale information
- Backend guesses language from ingredient text characters

**Impact:**
- Cannot optimize term generation for user's preferred language
- Cannot return localized categories
- Same input always returns same output regardless of user locale

### Gap 2: Recipe Extraction Forces English

**Current State:**
- All extraction prompts instruct: "translate to English"
- Recipes imported in Japanese show English ingredients
- Title can preserve original language (but often doesn't)

**Impact:**
- Japanese user imports Japanese recipe → sees English ingredients
- Disconnect between user's language preference and recipe content

### Gap 3: Categories Not Localized

**Current State:**
- 13 categories hardcoded in English on server
- Stored as raw English strings in database
- UI displays English categories regardless of locale
- Only "Other" fallback has translation

**Impact:**
- Shopping list shows "Produce" instead of "野菜類"
- Pantry shows "Meat & Seafood" instead of "肉・魚介類"
- Inconsistent UX with localized UI but English data

### Gap 4: Limited Language Detection

**Current State:**
- Only Japanese and Korean explicitly detected
- Chinese, Spanish, French, German, etc. not detected
- European languages rely on GPT's general multilingual capability

**Impact:**
- Chinese ingredients may not get proper term variants
- Spanish "cebolla" might not map to English "onion" reliably

### Gap 5: Cache Not Language-Aware

**Current State:**
- Cache key is `ingredient_name.toLowerCase()` only
- No language dimension in cache schema
- Same term always returns same cached result

**Impact:**
- If we add locale-aware canonicalization, cache invalidation is complex
- Could lead to "explosion" of cache entries if we key by (name, locale)

---

## Database/Caching Considerations

### Current Cache Design

```
Key: ingredient_name (lowercase)
Value: { terms: string[], category: string }

Example:
"onion" → { terms: ["onion", "onions"], category: "Produce" }
"玉ねぎ" → { terms: ["玉ねぎ", "たまねぎ", "タマネギ", "tamanegi", "onion", "onions"], category: "Produce" }
```

### Options for Language-Aware Caching

#### Option A: Keep Current Design (Recommended Initially)

**Rationale:**
- Current design already works for matching (includes English terms)
- Japanese/Korean already generate multilingual terms
- Adding locale to cache key creates duplication

**Enhancement:**
- Ensure ALL language inputs generate English term variants
- Translate categories client-side using ARB mapping

#### Option B: Separate Language Caches

```sql
CREATE TABLE terms (
  id INTEGER PRIMARY KEY,
  ingredient_name TEXT NOT NULL,
  locale TEXT NOT NULL,  -- 'en', 'ja', 'ko', etc.
  terms TEXT NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMP,
  UNIQUE(ingredient_name, locale)
);
```

**Pros:** Clean separation, can optimize per-locale
**Cons:** Cache explosion, more API calls

#### Option C: Universal Terms + Localized Display

Current approach with enhancements:
- Terms always include English variants (for matching)
- Terms always include original language variants
- Category translation happens client-side
- Recipe ingredient display localized client-side via term lookup

---

## Recommendations

### Phase 1: Quick Wins (Client-Side)

1. **Localize Categories (Flutter)**
   - Add all 13 category translations to ARB files
   - Create `CategoryLocalizer` utility to map raw category → localized label
   - Update UI widgets to use localized labels

2. **Pass Locale to API (Prepare for Future)**
   - Add `locale` field to canonicalization requests
   - Backend can ignore initially, but schema is ready

### Phase 2: Backend Improvements

3. **Expand Language Detection**
   - Add Chinese (Simplified/Traditional) detection
   - Add common European language detection
   - Adjust prompts per detected language

4. **Accept Locale Parameter**
   - Update Zod schemas to accept optional `locale`
   - Use locale hint to improve prompt construction
   - Don't cache differently by locale (yet)

### Phase 3: Recipe Content Language (Complex)

5. **Preserve Original Language in Recipes**
   - Option A: Store both original + English ingredients
   - Option B: Store original, generate English terms only
   - Option C: Always translate (current behavior, simpler)

**Recommendation:** Keep translating to English for now. The matching system works, and displaying localized terms is a presentation concern that can be solved differently (e.g., term-based display lookup).

### Phase 4: Advanced (If Needed)

6. **Per-Locale Cache (Only If Required)**
   - Monitor cache hit rates by locale
   - If hit rates are low due to language mismatch, consider locale-keyed cache
   - Implement cache migration strategy

---

## Appendix: Key File Locations

### Flutter App
| File | Purpose |
|------|---------|
| `lib/src/services/ingredient_canonicalization_service.dart` | API calls to canonicalization endpoints |
| `lib/src/managers/ingredient_term_queue_manager.dart` | Recipe ingredient queue |
| `lib/src/managers/pantry_item_term_queue_manager.dart` | Pantry item queue |
| `lib/src/managers/shopping_list_item_term_queue_manager.dart` | Shopping list queue |
| `lib/src/clients/recipe_api_client.dart` | HTTP client with signing |
| `lib/src/services/api_signer.dart` | HMAC signing |
| `lib/src/features/pantry/widgets/pantry_item_list.dart` | Pantry category display |
| `lib/src/features/shopping_list/widgets/shopping_list_items_list.dart` | Shopping category display |
| `lib/src/localization/app_en.arb` | English strings |
| `lib/src/localization/app_ja.arb` | Japanese strings |

### Backend Server
| File | Purpose |
|------|---------|
| `src/services/openaiService.ts` | **All AI prompts** |
| `src/services/dbService.ts` | SQLite cache |
| `src/types/index.ts` | Zod schemas, category enum |
| `src/controllers/ingredientController.ts` | Request handlers |
| `src/routes/ingredientRoutes.ts` | Route definitions |
| `src/middleware/validation.ts` | Request validation |
| `db/ingredients.sqlite` | Cache database |

---

## Summary

The app's AI backend is functional but English-centric. The main gaps are:

1. **No locale awareness** in API requests
2. **Categories displayed in English** regardless of user locale
3. **Recipe content always translated to English** (works for matching, awkward for display)
4. **Limited language detection** (Japanese/Korean only)

The recommended approach is to:
1. Localize categories client-side (quick win)
2. Add locale parameter to API (future-proofing)
3. Keep English-based matching (it works)
4. Consider display localization as a separate concern from matching
