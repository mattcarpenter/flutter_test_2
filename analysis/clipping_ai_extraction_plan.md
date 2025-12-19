# Clipping AI Extraction Feature Implementation Plan

## Overview

This feature enables users to extract structured data from clipping text using AI:
1. **Convert to Recipe**: Extracts recipe title, description, ingredients, and steps from clipping content
2. **Add to Shopping List**: Extracts shopping list items from clipping content

Both flows use the existing Wolt modal system and integrate with the established API signing/authentication pattern.

---

## Architecture Summary

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│ CONVERT TO RECIPE                                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ClippingEditorPage                                                      │
│        │                                                                 │
│        ▼                                                                 │
│  [Convert to Recipe Button Tap]                                          │
│        │                                                                 │
│        ▼                                                                 │
│  Show Wolt Modal Dialog (spinner)                                        │
│        │                                                                 │
│        ▼                                                                 │
│  ClippingExtractionService.extractRecipe()                               │
│        │                                                                 │
│        ├── RecipeApiClient.post('/v1/clippings/extract-recipe', {...})   │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   API Server: /v1/clippings/extract-recipe                      │
│        │        │                                                        │
│        │        ├── API Signature Verification                           │
│        │        ├── Rate Limiting (5/min, 100/day per IP)                │
│        │        ├── Request Validation                                   │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   ClippingExtractionService.extractRecipe()                     │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   OpenAI GPT-4.1 (structured output)                            │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   Return structured recipe data                                 │
│        │                                                                 │
│        ▼                                                                 │
│  SUCCESS: Close modal, open RecipeEditorForm with pre-populated data     │
│  FAILURE: Show error message in modal with close button                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ ADD TO SHOPPING LIST                                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ClippingEditorPage                                                      │
│        │                                                                 │
│        ▼                                                                 │
│  [To Shopping List Button Tap]                                           │
│        │                                                                 │
│        ▼                                                                 │
│  Show Wolt Modal Dialog (spinner)                                        │
│        │                                                                 │
│        ▼                                                                 │
│  ClippingExtractionService.extractShoppingList()                         │
│        │                                                                 │
│        ├── RecipeApiClient.post('/v1/clippings/extract-shopping-list')   │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   API Server: /v1/clippings/extract-shopping-list               │
│        │        │                                                        │
│        │        ├── API Signature Verification                           │
│        │        ├── Rate Limiting (5/min, 100/day per IP)                │
│        │        ├── Request Validation                                   │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   ClippingExtractionService.extractShoppingListItems()          │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   OpenAI GPT-4.1 (extract item names only)                      │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   Call existing canonicalizeItems() for each item               │
│        │        │                                                        │
│        │        ▼                                                        │
│        │   Return items with terms and categories                        │
│        │                                                                 │
│        ▼                                                                 │
│  SUCCESS: Show add-to-shopping-list modal with extracted items           │
│  FAILURE: Show error message in modal with close button                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: API Server Implementation

### 1.1 Create Clipping Extraction Service

**File**: `/users/matt/repos/recipe_app_server/src/services/clippingExtractionService.ts`

This service-layer module handles AI extraction logic, reusable for future features.

```typescript
// Extracted Recipe Structure (returned to Flutter)
interface ExtractedRecipe {
  title: string;
  description?: string;
  servings?: number;
  prepTime?: number;      // minutes
  cookTime?: number;      // minutes
  ingredients: Array<{
    name: string;         // Full ingredient text (e.g., "2 cups flour") or section header
    type: 'ingredient' | 'section';
  }>;
  steps: Array<{
    text: string;         // Step instruction or section header
    type: 'step' | 'section';
  }>;
  source?: string;        // URL if detected in text
}

// Extracted Shopping List Item (before canonicalization)
interface ExtractedShoppingItem {
  name: string;           // Item name (e.g., "milk", "bread")
}

// Canonicalized Shopping List Item (returned to Flutter)
interface CanonicaliizedShoppingItem {
  name: string;
  terms: string[];
  category: string;
}
```

**Functions**:
- `extractRecipeFromText(title: string, body: string): Promise<ExtractedRecipe | null>`
  - Uses GPT-4.1 with structured output
  - Returns null if unable to extract valid recipe

- `extractShoppingListFromText(title: string, body: string): Promise<ExtractedShoppingItem[]>`
  - Uses GPT-4.1 to extract item names only
  - Returns empty array if no items found

- `canonicalizeShoppingItems(items: ExtractedShoppingItem[]): Promise<CanonicaliizedShoppingItem[]>`
  - Reuses existing `analyzeIngredientsWithAI()` from openaiService.ts
  - Applies caching layer for efficiency

### 1.2 OpenAI Prompt Design

**Recipe Extraction Prompt**:
```
You are a culinary assistant that extracts structured recipe data from unformatted text.

Given a title and body text that may contain recipe information, extract:
- Recipe title (use provided title if appropriate, or extract from content)
- Description (brief summary if available)
- Servings (number if mentioned)
- Prep time in minutes (if mentioned)
- Cook time in minutes (if mentioned)
- Ingredients list (preserve quantities and units in the name field)
- Steps list (ordered instructions)
- Source URL (if a URL is present in the text)

Guidelines:
- If the text doesn't contain recipe-like content, return null
- Preserve ingredient quantities exactly as written (e.g., "2 cups all-purpose flour")
- Steps should be individual instructions, not combined
- Extract only what's clearly present; don't invent details
- Handle various formats: bullet points, numbered lists, paragraphs

Sections (for both ingredients and steps):
- Use type="section" SPARINGLY, only when the recipe has clearly distinct components
- Good examples: "Poolish", "Main Dough", "Sauce", "Filling", "Glaze", "For the Crust"
- Do NOT create sections for simple recipes or when grouping isn't meaningful
- When present in the source text, preserve the section structure
- Section items contain the header text in their name/text field
```

**Shopping List Extraction Prompt**:
```
You are an assistant that extracts shopping list items from unformatted text.

Given a title and body text, extract items that appear to be shopping list items,
grocery items, or ingredients that someone might want to purchase.

Guidelines:
- Extract just the item names, not quantities or units
- Include both explicit list items and ingredients mentioned in recipe text
- Normalize item names (e.g., "2 lbs chicken breasts" → "chicken breasts")
- If no items are found, return an empty array
- Don't include cooking equipment or non-purchasable items
```

### 1.3 Create Clipping Routes

**File**: `/users/matt/repos/recipe_app_server/src/routes/clippingRoutes.ts`

```typescript
import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { verifyApiSignature } from '../middleware/apiSignature';
import { extractRecipe, extractShoppingList } from '../controllers/clippingController';
import { validateExtractRequest } from '../middleware/validation';

const router = Router();

// Rate limiters: 5 per minute, 100 per day per IP
// No custom messages - 429 status code is sufficient
const minuteLimiter = rateLimit({
  windowMs: 60 * 1000,           // 1 minute
  max: 5,
  standardHeaders: false,
  legacyHeaders: false,
});

const dailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 100,
  standardHeaders: false,
  legacyHeaders: false,
});

// Both endpoints use same rate limiting and auth
router.post(
  '/extract-recipe',
  verifyApiSignature,
  minuteLimiter,
  dailyLimiter,
  validateExtractRequest,
  extractRecipe
);

router.post(
  '/extract-shopping-list',
  verifyApiSignature,
  minuteLimiter,
  dailyLimiter,
  validateExtractRequest,
  extractShoppingList
);

export default router;
```

### 1.4 Create Clipping Controller

**File**: `/users/matt/repos/recipe_app_server/src/controllers/clippingController.ts`

```typescript
import { Request, Response } from 'express';
import {
  extractRecipeFromText,
  extractShoppingListFromText,
  canonicalizeShoppingItems
} from '../services/clippingExtractionService';
import logger from '../services/logger';

export async function extractRecipe(req: Request, res: Response) {
  const { title, body } = req.body;

  try {
    const recipe = await extractRecipeFromText(title, body);

    if (!recipe) {
      return res.status(200).json({
        success: false,
        message: 'Unable to extract recipe from the provided text.'
      });
    }

    return res.status(200).json({ success: true, recipe });
  } catch (error) {
    logger.error('Recipe extraction failed', { error, title });
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function extractShoppingList(req: Request, res: Response) {
  const { title, body } = req.body;

  try {
    const rawItems = await extractShoppingListFromText(title, body);

    if (rawItems.length === 0) {
      return res.status(200).json({
        success: false,
        message: 'No shopping list items found in the provided text.',
        items: []
      });
    }

    // Canonicalize using existing ingredient service
    const canonicalizedItems = await canonicalizeShoppingItems(rawItems);

    return res.status(200).json({
      success: true,
      items: canonicalizedItems
    });
  } catch (error) {
    logger.error('Shopping list extraction failed', { error, title });
    return res.status(500).json({ error: 'Internal server error' });
  }
}
```

### 1.5 Add Validation Schema

**File**: `/users/matt/repos/recipe_app_server/src/types/index.ts` (add to existing)

```typescript
// Clipping extraction request validation
export const ExtractClippingRequestSchema = z.object({
  title: z.string().max(200).optional().default(''),
  body: z.string().min(1).max(50000)  // Max 50KB of text
});

export type ExtractClippingRequest = z.infer<typeof ExtractClippingRequestSchema>;
```

### 1.6 Register Routes

**File**: `/users/matt/repos/recipe_app_server/src/index.ts` (modify)

```typescript
import clippingRoutes from './routes/clippingRoutes';

// Add after existing route registrations
app.use('/v1/clippings', clippingRoutes);
```

---

## Phase 2: Flutter Client Implementation

### 2.1 Create Clipping Extraction Service

**File**: `lib/src/services/clipping_extraction_service.dart`

```dart
class ClippingExtractionService {
  final RecipeApiClient _apiClient;

  ClippingExtractionService(this._apiClient);

  /// Extracts recipe data from clipping text.
  /// Returns null if extraction failed or no recipe found.
  Future<ExtractedRecipe?> extractRecipe({
    required String title,
    required String body,
  }) async {
    final response = await _apiClient.post(
      '/v1/clippings/extract-recipe',
      {'title': title, 'body': body},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to extract recipe: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      return null;
    }

    return ExtractedRecipe.fromJson(data['recipe']);
  }

  /// Extracts shopping list items from clipping text.
  /// Returns empty list if no items found.
  Future<List<ExtractedShoppingItem>> extractShoppingList({
    required String title,
    required String body,
  }) async {
    final response = await _apiClient.post(
      '/v1/clippings/extract-shopping-list',
      {'title': title, 'body': body},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to extract shopping list: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true || data['items'] == null) {
      return [];
    }

    return (data['items'] as List)
        .map((item) => ExtractedShoppingItem.fromJson(item))
        .toList();
  }
}
```

### 2.2 Create Extraction Models

**File**: `lib/src/features/clippings/models/extracted_recipe.dart`

```dart
class ExtractedRecipe {
  final String title;
  final String? description;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final List<ExtractedIngredient> ingredients;
  final List<ExtractedStep> steps;
  final String? source;

  // fromJson constructor
  // toRecipeEntry() method to convert to RecipeEntry for editor form
}

class ExtractedIngredient {
  final String name;  // Ingredient text or section header
  final String type;  // 'ingredient' or 'section'
}

class ExtractedStep {
  final String text;  // Step instruction or section header
  final String type;  // 'step' or 'section'
}
```

**File**: `lib/src/features/clippings/models/extracted_shopping_item.dart`

```dart
class ExtractedShoppingItem {
  final String name;
  final List<String> terms;
  final String category;

  // fromJson constructor
}
```

### 2.3 Create Provider

**File**: `lib/src/features/clippings/providers/clipping_extraction_provider.dart`

```dart
final clippingExtractionServiceProvider = Provider<ClippingExtractionService>((ref) {
  final apiClient = ref.watch(recipeApiClientProvider);
  return ClippingExtractionService(apiClient);
});
```

### 2.4 Create Extraction Modal Widget

**File**: `lib/src/features/clippings/views/clipping_extraction_modal.dart`

This is a Wolt modal presented as a **dialog** (not bottom sheet) with three states:
1. **Loading**: Spinner with "Extracting..." text
2. **Success**: Auto-closes and triggers navigation/display
3. **Error**: Error message with close button

```dart
/// Shows extraction modal and handles the result.
/// For recipe: closes modal and opens recipe editor form
/// For shopping list: closes modal and shows add-to-shopping-list modal
Future<void> showRecipeExtractionModal(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  // Show loading modal
  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: false,
    barrierDismissible: false,
    pageListBuilder: (context) => [
      _buildExtractionPage(context, isLoading: true, type: 'recipe'),
    ],
  );

  try {
    final service = ref.read(clippingExtractionServiceProvider);
    final recipe = await service.extractRecipe(title: title, body: body);

    // Close loading modal
    Navigator.of(context, rootNavigator: true).pop();

    if (recipe == null) {
      // Show error modal
      _showErrorModal(context, 'Unable to extract a recipe from this text.');
      return;
    }

    // Convert to RecipeEntry and open editor
    final recipeEntry = recipe.toRecipeEntry();
    showRecipeEditorModal(context, recipe: recipeEntry);

  } catch (e) {
    Navigator.of(context, rootNavigator: true).pop();
    _showErrorModal(context, 'Failed to process. Please try again.');
  }
}

Future<void> showShoppingListExtractionModal(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  // Similar pattern but shows add-to-shopping-list modal on success
}
```

### 2.5 Update Clipping Editor Page

**File**: `lib/src/features/clippings/views/clipping_editor_page.dart`

Update the convert buttons to trigger extraction:

```dart
// In _buildConversionButton for "Convert to Recipe"
onPressed: () {
  final title = _titleController.text;
  final body = extractPlainTextFromQuillJson(
    jsonEncode(_contentController.document.toDelta().toJson())
  );

  showRecipeExtractionModal(
    context,
    ref,
    title: title,
    body: body,
  );
},

// In _buildConversionButton for "To Shopping List"
onPressed: () {
  final title = _titleController.text;
  final body = extractPlainTextFromQuillJson(
    jsonEncode(_contentController.document.toDelta().toJson())
  );

  showShoppingListExtractionModal(
    context,
    ref,
    title: title,
    body: body,
  );
},
```

### 2.6 Create Shopping List Results Modal

**File**: `lib/src/features/clippings/views/clipping_shopping_list_modal.dart`

Reuse the UI pattern from `add_to_shopping_list_modal.dart`:

```dart
/// Shows extracted shopping list items for user to add to their lists.
/// Similar to AddToShoppingListModal but with pre-extracted items.
void showClippingShoppingListModal(
  BuildContext context,
  WidgetRef ref,
  List<ExtractedShoppingItem> items,
) {
  // Multi-page Wolt modal:
  // Page 0: Item list with checkboxes and list selector dropdowns
  // Page 1: Manage lists
  // Page 2: Create new list

  // Reuse patterns from add_to_shopping_list_modal.dart:
  // - Checkbox selection
  // - List dropdown selection
  // - Stock chip display (match with pantry)
  // - Sticky action bar with "Add to Shopping List" button
}
```

Key differences from meal plan modal:
- Items come from extraction API (already have terms/categories)
- No sourceRecipeIds/sourceRecipeTitles
- Otherwise same UI and interaction patterns

### 2.7 Auto-Check Logic for Shopping List Items

Following the pattern from `add_to_shopping_list_modal.dart` (lines 569-593), items should be **auto-checked unless they are in stock**:

```dart
void _initializeState(List<ExtractedShoppingItem> items, String? defaultListId) {
  for (final item in items) {
    final id = item.id;

    // Skip items already in a shopping list
    if (item.existsInShoppingList) continue;

    // Pre-check items based on pantry status:
    // - No pantry match → checked
    // - Out of stock → checked
    // - Low stock → checked
    // - In stock → NOT checked
    if (!controller.checkedState.containsKey(id)) {
      final pantryItem = item.matchingPantryItem;
      final shouldCheck = pantryItem == null ||
          pantryItem.stockStatus == StockStatus.outOfStock ||
          pantryItem.stockStatus == StockStatus.lowStock;
      controller.checkedState[id] = shouldCheck;
    }

    // Default list selection
    if (!controller.selectedListIds.containsKey(id)) {
      controller.selectedListIds[id] = defaultListId;
    }
  }
}
```

This matches the existing meal plan modal behavior exactly.

### 2.8 Button State: Disable When Content Empty

In `clipping_editor_page.dart`, the convert buttons should be disabled when content is empty:

```dart
Widget _buildConversionButtons() {
  // Check if content has meaningful text
  final hasContent = _contentController.document.toPlainText().trim().isNotEmpty;

  return Row(
    children: [
      Expanded(
        child: _buildConversionButton(
          icon: CupertinoIcons.sparkles,
          label: 'Convert to Recipe',
          onPressed: hasContent ? () => _handleConvertToRecipe() : null,
        ),
      ),
      SizedBox(width: AppSpacing.md),
      Expanded(
        child: _buildConversionButton(
          icon: CupertinoIcons.list_bullet,
          label: 'To Shopping List',
          onPressed: hasContent ? () => _handleAddToShoppingList() : null,
        ),
      ),
    ],
  );
}
```

### 2.9 Offline Error Handling

Check connectivity before making API calls and show an error dialog if offline:

```dart
Future<void> _handleConvertToRecipe() async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    _showErrorModal(context, 'No internet connection. Please check your network and try again.');
    return;
  }

  // Proceed with extraction...
  showRecipeExtractionModal(context, ref, title: title, body: body);
}
```

---

## Phase 3: Integration & Testing

### 3.1 Test Cases

**Recipe Extraction**:
1. Well-formatted recipe text → Full recipe extraction
2. Partial recipe (ingredients only) → Partial extraction
3. Non-recipe text → Returns null, shows error modal
4. Empty content → Returns null, shows error modal
5. Rate limit exceeded → Shows appropriate error

**Shopping List Extraction**:
1. Bullet-point shopping list → All items extracted
2. Recipe with ingredients → Ingredients extracted as items
3. Mixed content → Items extracted where found
4. Non-list content → Empty array, shows error modal
5. Rate limit exceeded → Shows appropriate error

### 3.2 Error Handling

| Scenario | API Response | Flutter Behavior |
|----------|--------------|------------------|
| Successful extraction | 200 + data | Close modal, show results |
| No content found | 200 + success:false | Show error message in modal |
| Rate limited | 429 | Show rate limit message |
| Server error | 500 | Show generic error message |
| Network error | - | Show connection error message |

---

## File Summary

### API Server (recipe_app_server)

| File | Action |
|------|--------|
| `src/services/clippingExtractionService.ts` | **CREATE** - AI extraction logic |
| `src/controllers/clippingController.ts` | **CREATE** - Request handlers |
| `src/routes/clippingRoutes.ts` | **CREATE** - Route definitions |
| `src/middleware/validation.ts` | **MODIFY** - Add extraction validation |
| `src/types/index.ts` | **MODIFY** - Add Zod schemas |
| `src/index.ts` | **MODIFY** - Register routes |

### Flutter App (flutter_test_2)

| File | Action |
|------|--------|
| `lib/src/services/clipping_extraction_service.dart` | **CREATE** - API client wrapper |
| `lib/src/features/clippings/models/extracted_recipe.dart` | **CREATE** - Recipe model |
| `lib/src/features/clippings/models/extracted_shopping_item.dart` | **CREATE** - Shopping item model |
| `lib/src/features/clippings/providers/clipping_extraction_provider.dart` | **CREATE** - Service provider |
| `lib/src/features/clippings/views/clipping_extraction_modal.dart` | **CREATE** - Loading/error modal |
| `lib/src/features/clippings/views/clipping_shopping_list_modal.dart` | **CREATE** - Results modal |
| `lib/src/features/clippings/views/clipping_editor_page.dart` | **MODIFY** - Wire up buttons |

---

## Implementation Order

### Backend First
1. Create `clippingExtractionService.ts` with OpenAI prompts
2. Create `clippingController.ts` handlers
3. Add Zod validation schemas to `types/index.ts`
4. Add validation middleware to `validation.ts`
5. Create `clippingRoutes.ts` with rate limiting
6. Register routes in `index.ts`
7. Test endpoints with curl/Postman

### Frontend Second
1. Create extraction models
2. Create `ClippingExtractionService`
3. Create provider
4. Create extraction modal (loading/error states)
5. Create shopping list results modal
6. Wire up buttons in `clipping_editor_page.dart`
7. Test full flow

---

## Security Considerations

1. **API Signing**: Both endpoints use existing HMAC-SHA256 signature verification
2. **Rate Limiting**: 5 requests/minute + 100 requests/day per IP (prevents abuse of OpenAI credits)
3. **Input Validation**: Max 50KB text, title max 200 chars
4. **Prompt Injection**: Reuse existing validation patterns from openaiService.ts
5. **No Auth Required**: Matches existing ingredient endpoints pattern (signature verification only)

---

## HMAC Signing Implementation Details

The clipping extraction endpoints use the same HMAC-SHA256 signing pattern established by the ingredient canonicalization endpoints. This section documents the exact implementation to ensure correct integration.

### Overview

The signing provides lightweight security to prevent casual API abuse. It's not cryptographically secure (the key is embedded in the app binary) but adds friction for attackers.

### Flutter Client Implementation

#### 1. ApiSigner (`lib/src/services/api_signer.dart`)

The `ApiSigner` class provides static methods for signing requests:

```dart
class ApiSigner {
  // Signing key - embedded in app binary (same key on backend via env var)
  static const String _signingKey = 'rcp_sk_7f3a9b2c4d5e6f8g1h2i3j4k5l6m7n8o';

  // Public API key - identifies the app (not secret)
  static const String apiKey = 'rcp_live_flutter_v1';

  static Map<String, String> sign(String method, String path, String bodyString) {
    // Get current timestamp in Unix seconds
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Hash the body (SHA256, lowercase hex)
    final bodyHash = sha256.convert(utf8.encode(bodyString)).toString();

    // Build canonical string: METHOD\nPATH\nTIMESTAMP\nBODY_HASH
    final canonical = '$method\n$path\n$timestamp\n$bodyHash';

    // Compute HMAC-SHA256
    final hmacSha256 = Hmac(sha256, utf8.encode(_signingKey));
    final signature = hmacSha256.convert(utf8.encode(canonical)).toString();

    return {
      'X-Api-Key': apiKey,
      'X-Timestamp': timestamp.toString(),
      'X-Signature': signature,
    };
  }
}
```

#### 2. RecipeApiClient (`lib/src/clients/recipe_api_client.dart`)

**CRITICAL**: The body string must be created ONCE and used for both signing and sending. This ensures the exact bytes signed match the bytes sent:

```dart
Future<http.Response> post(String path, Map<String, dynamic> body) async {
  // Create body string ONCE - used for both signing and sending
  // This ensures the exact bytes signed match the bytes sent
  final bodyString = json.encode(body);

  // Sign the request
  final signatureHeaders = ApiSigner.sign('POST', path, bodyString);

  return await http.post(
    Uri.parse('$baseUrl$path'),
    headers: {
      'Content-Type': 'application/json',
      ...signatureHeaders,
    },
    body: bodyString,  // Same string used for signing
  );
}
```

**Warning**: Do NOT call `json.encode()` twice - different calls could produce different byte orderings.

#### 3. Usage in ClippingExtractionService

The service layer simply uses RecipeApiClient which handles all signing:

```dart
class ClippingExtractionService {
  final RecipeApiClient _apiClient;

  Future<ExtractedRecipe?> extractRecipe({
    required String title,
    required String body,
  }) async {
    // RecipeApiClient.post() handles HMAC signing automatically
    final response = await _apiClient.post(
      '/v1/clippings/extract-recipe',
      {'title': title, 'body': body},
    );
    // ...
  }
}
```

### Backend Server Implementation

#### 1. Raw Body Capture (`src/index.ts`)

**CRITICAL**: The raw request body must be captured BEFORE JSON parsing. Express.json's `verify` callback is used:

```typescript
app.use(express.json({
  limit: '100kb',
  // Capture raw body for signature verification
  // This runs before JSON parsing, storing the exact bytes received
  verify: (req, res, buf) => {
    (req as any).rawBody = buf;
  }
}));
```

**Warning**: Without this, the parsed JSON would be re-serialized, potentially with different byte ordering than the original request.

#### 2. Signature Verification Middleware (`src/middleware/apiSignature.ts`)

```typescript
export function verifyApiSignature(req: Request, res: Response, next: NextFunction): void {
  const SIGNING_KEY = process.env.API_SIGNING_KEY;
  const TIMESTAMP_TOLERANCE_SECONDS = 60;

  // Extract required headers
  const apiKey = req.header('X-Api-Key');
  const timestampStr = req.header('X-Timestamp');
  const signature = req.header('X-Signature');

  // Validate all required headers are present
  if (!apiKey || !timestampStr || !signature) {
    res.status(401).json({ error: 'Missing required authentication headers' });
    return;
  }

  // Check timestamp is within acceptable window (±60 seconds)
  const timestamp = parseInt(timestampStr, 10);
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > TIMESTAMP_TOLERANCE_SECONDS) {
    res.status(401).json({ error: 'Request expired' });
    return;
  }

  // Get raw body captured by express.json verify function
  const rawBody = req.rawBody;
  if (!rawBody) {
    res.status(500).json({ error: 'Server configuration error' });
    return;
  }

  // Compute body hash (SHA256, lowercase hex)
  const bodyHash = crypto.createHash('sha256').update(rawBody).digest('hex');

  // Build canonical string: METHOD\nPATH\nTIMESTAMP\nBODY_HASH
  // Use req.originalUrl to get the full path (req.path is relative to router mount)
  const fullPath = req.originalUrl.split('?')[0];
  const canonical = `${req.method}\n${fullPath}\n${timestamp}\n${bodyHash}`;

  // Compute expected signature
  const expectedSignature = crypto
    .createHmac('sha256', SIGNING_KEY)
    .update(canonical)
    .digest('hex');

  // Constant-time comparison to prevent timing attacks
  const signatureBuffer = Buffer.from(signature, 'hex');
  const expectedBuffer = Buffer.from(expectedSignature, 'hex');

  if (signatureBuffer.length !== expectedBuffer.length ||
      !crypto.timingSafeEqual(signatureBuffer, expectedBuffer)) {
    res.status(401).json({ error: 'Invalid signature' });
    return;
  }

  next();
}
```

#### 3. Apply Middleware to Routes

The middleware is applied to routes that require signature verification:

```typescript
// clippingRoutes.ts
router.post(
  '/extract-recipe',
  verifyApiSignature,  // HMAC verification first
  minuteLimiter,
  dailyLimiter,
  validateExtractRequest,
  extractRecipe
);
```

### Potential Pitfalls & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "Invalid signature" | Body bytes don't match | Use same `bodyString` for signing AND sending |
| "Invalid signature" | Path mismatch | Flutter must sign with exact path including `/v1/` prefix |
| "Request expired" | Clock skew > 60s | Ensure device time is synced; timestamp tolerance is ±60s |
| "Server configuration error" | rawBody not captured | Ensure `express.json` has `verify` callback configured |
| "Invalid signature" | Wrong signing key | Ensure `API_SIGNING_KEY` env var matches Flutter's embedded key |

### Canonical String Format

The HMAC signature is computed over a canonical string with this exact format:

```
{METHOD}\n{PATH}\n{TIMESTAMP}\n{BODY_HASH}
```

Example:
```
POST
/v1/clippings/extract-recipe
1703123456
a5b9d7e2f3c1...  (SHA256 hash of request body)
```

### Environment Variable

The backend requires the signing key in an environment variable:

```bash
API_SIGNING_KEY=rcp_sk_7f3a9b2c4d5e6f8g1h2i3j4k5l6m7n8o
```

This must match the `_signingKey` constant in Flutter's `ApiSigner` class

---

## Logging Strategy

Use Winston logging in the backend for monitoring and debugging. No external analytics service (New Relic to be added in a later phase).

### Backend Logging (Winston)

```typescript
// In clippingController.ts

// Success logging
logger.info('Recipe extracted successfully', {
  event: 'RECIPE_EXTRACTION_SUCCESS',
  ingredientCount: recipe.ingredients.length,
  stepCount: recipe.steps.length,
  ip: req.ip
});

logger.info('Shopping list extracted successfully', {
  event: 'SHOPPING_LIST_EXTRACTION_SUCCESS',
  itemCount: items.length,
  ip: req.ip
});

// No content found
logger.info('No recipe content found in text', {
  event: 'RECIPE_EXTRACTION_NO_CONTENT',
  textLength: body.length,
  ip: req.ip
});

logger.info('No shopping list items found in text', {
  event: 'SHOPPING_LIST_EXTRACTION_NO_CONTENT',
  textLength: body.length,
  ip: req.ip
});

// Error logging
logger.error('Recipe extraction failed', {
  event: 'RECIPE_EXTRACTION_ERROR',
  error: error.message,
  stack: error.stack,
  ip: req.ip
});

logger.error('Shopping list extraction failed', {
  event: 'SHOPPING_LIST_EXTRACTION_ERROR',
  error: error.message,
  stack: error.stack,
  ip: req.ip
});
```

---

## Design Decisions (Confirmed)

| Question | Decision |
|----------|----------|
| Recipe Editor Pre-population | Open in **new recipe state (unsaved)** - user must explicitly save |
| Shopping List Auto-Check | Match existing modal: auto-check items **unless they are in stock** (out of stock, low stock, or not in pantry = checked; in stock = unchecked) |
| Empty Content Handling | **Disable buttons** when clipping content is empty/whitespace only |
| Offline Handling | **Show error dialog** indicating network connection required |
| Analytics/Monitoring | Use **Winston logging** in backend for now; New Relic in later phase |
