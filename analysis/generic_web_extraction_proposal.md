# Generic Web Recipe Extraction - Implementation Proposal

## Overview

Add support for extracting recipes from **any website** (not just Instagram/TikTok/YouTube) via two input methods:
1. **URL-based**: Provide a URL, system fetches and processes HTML
2. **HTML-based**: Provide raw HTML directly (for embedded browser integration)

## Processing Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INPUT                                        │
│                                                                      │
│    URL Input                              HTML Input                 │
│    (Share flow)                           (Embedded browser)         │
│         │                                       │                    │
│         ▼                                       │                    │
│   ┌───────────┐                                 │                    │
│   │ Fetch HTML │                                │                    │
│   └─────┬─────┘                                 │                    │
│         │                                       │                    │
│         └───────────────┬───────────────────────┘                    │
│                         ▼                                            │
│              ┌─────────────────────┐                                 │
│              │ Parse ld+json Schema │                                │
│              └──────────┬──────────┘                                 │
│                         │                                            │
│           ┌─────────────┴─────────────┐                              │
│           │                           │                              │
│           ▼                           ▼                              │
│   ┌───────────────┐          ┌────────────────┐                      │
│   │ Schema Found  │          │ No Schema      │                      │
│   └───────┬───────┘          └───────┬────────┘                      │
│           │                          │                               │
│           ▼                          ▼                               │
│   ┌───────────────┐          ┌────────────────────────┐              │
│   │ Parse Locally │          │ Send HTML to Backend   │              │
│   │ (No API call) │          │ (Plus required)        │              │
│   └───────┬───────┘          └───────┬────────────────┘              │
│           │                          │                               │
│           │                          ▼                               │
│           │                  ┌────────────────────────┐              │
│           │                  │ Readability extraction │              │
│           │                  │ → OpenAI structuring   │              │
│           │                  └───────┬────────────────┘              │
│           │                          │                               │
│           └──────────┬───────────────┘                               │
│                      ▼                                               │
│              ┌───────────────┐                                       │
│              │ ExtractedRecipe│                                      │
│              └───────────────┘                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. ld+json Schema Parsing Happens Client-Side

**Rationale**:
- Many recipe sites (AllRecipes, Food Network, Serious Eats, etc.) have structured data
- Parsing ld+json is trivial and doesn't require AI
- Saves API costs and reduces latency
- Works offline for cached pages
- **No Plus subscription required** for schema-based extraction

### 2. Readability + OpenAI is Backend-Only

**Rationale**:
- Readability requires DOM parsing (heavy for mobile)
- OpenAI calls must be server-side (API key security)
- Rate limiting and cost control
- **Plus subscription required** for AI-based extraction

### 3. Two Input Modes with Unified Output

**Rationale**:
- Share flow provides URL → fetch HTML
- Embedded browser has HTML → no need to re-fetch
- Both paths produce same `ExtractedRecipe` output

---

## Frontend Implementation

### New Files

#### 1. `lib/src/services/content_extraction/generic_web_extractor.dart`

```dart
/// Extracts recipes from any website using:
/// 1. ld+json recipe schema (parsed locally, no API needed)
/// 2. Fallback to backend Readability + OpenAI (Plus required)
class GenericWebExtractor {
  /// Extract recipe from a URL (fetches HTML first)
  Future<WebExtractionResult> extractFromUrl(Uri url) async;

  /// Extract recipe from raw HTML (for embedded browser)
  Future<WebExtractionResult> extractFromHtml(String html, {String? sourceUrl}) async;

  /// Check if URL is likely a recipe page (for UI hints)
  /// Uses heuristics like path containing 'recipe', 'recipes', etc.
  bool isLikelyRecipePage(Uri url);
}

/// Result of web extraction attempt
class WebExtractionResult {
  final ExtractedRecipe? recipe;
  final RecipePreview? preview;        // For non-Plus preview flow
  final WebExtractionSource source;    // How it was extracted
  final String? error;

  bool get success => recipe != null || preview != null;
}

enum WebExtractionSource {
  jsonLdSchema,      // Parsed from ld+json (free, local)
  backendReadability, // Backend Readability + OpenAI (Plus required)
}
```

#### 2. `lib/src/services/content_extraction/json_ld_parser.dart`

```dart
/// Parses Recipe schema.org structured data from HTML
class JsonLdRecipeParser {
  /// Parse ld+json scripts from HTML and extract Recipe schema
  ExtractedRecipe? parse(String html);

  /// Parse just enough for preview (title + first 4 ingredients)
  RecipePreview? parsePreview(String html);
}
```

**Schema.org Recipe properties to extract:**
- `name` → title
- `description` → description
- `recipeIngredient[]` → ingredients
- `recipeInstructions[]` → steps (handles both string[] and HowToStep[])
- `prepTime` → prepTime (ISO 8601 duration: "PT15M")
- `cookTime` → cookTime
- `recipeYield` → servings
- `image` → imageUrl (for OG image download)
- `author` / `publisher` → source attribution

#### 3. `lib/src/services/web_extraction_service.dart`

```dart
/// Calls backend for Readability + OpenAI extraction
/// Mirrors ShareExtractionService pattern
class WebExtractionService {
  /// Full extraction (Plus required)
  Future<ExtractedRecipe?> extractRecipe({
    required String html,
    String? sourceUrl,
  });

  /// Preview extraction (free, rate-limited)
  Future<RecipePreview?> previewRecipe({
    required String html,
    String? sourceUrl,
  });
}
```

### Modified Files

#### `lib/src/services/content_extraction/content_extractor.dart`

Add `GenericWebExtractor` as final fallback in the chain:

```dart
class ContentExtractor {
  final _extractors = <SiteExtractor>[
    YouTubeExtractor(),
    TikTokExtractor(),
    InstagramExtractor(),
  ];

  final _genericExtractor = GenericWebExtractor();
  final _webViewExtractor = WebViewOGExtractor(); // Existing fallback

  /// Check if URL is supported (now includes all HTTP/HTTPS URLs)
  bool isSupported(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// Extract with fallback chain
  Future<OGExtractedContent?> extract(Uri uri) async {
    // Try platform-specific extractors first (for OG metadata)
    for (final extractor in _extractors) {
      if (extractor.canHandle(uri)) {
        final result = await extractor.extract(uri);
        if (result != null) return result;
      }
    }

    // Fallback to WebView for OG tags
    return _webViewExtractor.extract(uri);
  }

  /// NEW: Extract recipe directly (for generic sites)
  /// Returns recipe if ld+json found, null otherwise
  Future<ExtractedRecipe?> extractRecipeFromUrl(Uri uri) async {
    return _genericExtractor.extractFromUrl(uri);
  }
}
```

#### `lib/src/features/share/views/share_session_modal.dart`

Update extraction flow to try ld+json first:

```dart
Future<void> _performFullRecipeExtraction() async {
  // ... existing validation ...

  // NEW: Try ld+json extraction first (free, no API call)
  final extractableUrl = _findExtractableUrl();
  if (extractableUrl != null) {
    final jsonLdRecipe = await _tryJsonLdExtraction(extractableUrl);
    if (jsonLdRecipe != null) {
      // Success! No backend call needed
      _openRecipeEditor(jsonLdRecipe);
      return;
    }
  }

  // Check if this is a supported platform (Instagram/TikTok/YouTube)
  final isKnownPlatform = _isKnownPlatform(extractableUrl);

  if (isKnownPlatform && _extractedContent != null) {
    // Use existing OG-based extraction for known platforms
    await _extractViaOgMetadata();
  } else if (extractableUrl != null) {
    // NEW: Use Readability extraction for unknown sites
    await _extractViaReadability(extractableUrl);
  } else {
    // No URL - show error
    _showExtractionError(_ExtractionErrorType.noContentExtracted);
  }
}

Future<void> _extractViaReadability(Uri url) async {
  // Fetch HTML
  final html = await _fetchHtml(url);
  if (html == null) {
    _showExtractionError(_ExtractionErrorType.noContentExtracted);
    return;
  }

  // Call backend
  final service = ref.read(webExtractionServiceProvider);
  final recipe = await service.extractRecipe(
    html: html,
    sourceUrl: url.toString(),
  );

  if (recipe != null) {
    _openRecipeEditor(recipe);
  } else {
    _showExtractionError(_ExtractionErrorType.noRecipeDetected);
  }
}
```

---

## Backend Implementation

### New Files

#### 1. `src/routes/webRoutes.ts`

```typescript
import express from 'express';
import { WebController } from '../controllers/webController';
import { verifyApiSignature } from '../middleware/apiSignature';
import { authenticateUser } from '../middleware/auth';
import { verifyPlusEntitlement } from '../middleware/entitlement';
import { validateWebExtractionRequest } from '../middleware/validation';
import rateLimit from 'express-rate-limit';

const router = express.Router();
const webController = new WebController();

// Rate limiters (same pattern as clipping/share routes)
const minuteLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: { error: 'Rate limit exceeded', code: 'MINUTE_LIMIT_EXCEEDED' },
});

const dailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 100,
  message: { error: 'Daily limit exceeded', code: 'DAILY_LIMIT_EXCEEDED' },
});

const previewDailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 5,
  message: { error: 'Preview limit exceeded', code: 'PREVIEW_LIMIT_EXCEEDED' },
});

// Full extraction - Plus required
router.post(
  '/extract-recipe',
  verifyApiSignature,
  authenticateUser,
  verifyPlusEntitlement,
  minuteLimiter,
  dailyLimiter,
  validateWebExtractionRequest,
  webController.extractRecipe.bind(webController)
);

// Preview - No auth required, heavily rate-limited
router.post(
  '/preview-recipe',
  verifyApiSignature,
  previewDailyLimiter,
  validateWebExtractionRequest,
  webController.previewRecipe.bind(webController)
);

export default router;
```

#### 2. `src/controllers/webController.ts`

```typescript
import { Request, Response } from 'express';
import { WebExtractionService } from '../services/webExtractionService';
import logger from '../services/logger';

export class WebController {
  private webExtractionService: WebExtractionService;

  constructor() {
    this.webExtractionService = new WebExtractionService();
  }

  async extractRecipe(req: Request, res: Response): Promise<void> {
    try {
      const { html, sourceUrl } = req.body;

      const recipe = await this.webExtractionService.extractRecipe(html, sourceUrl);

      if (recipe) {
        logger.info('Web recipe extraction successful', {
          event: 'WEB_RECIPE_EXTRACTION_SUCCESS',
          ingredientCount: recipe.ingredients?.length ?? 0,
          stepCount: recipe.steps?.length ?? 0,
          sourceUrl,
          userId: req.user?.id,
          ip: req.ip,
        });

        res.json({ success: true, recipe });
      } else {
        logger.info('Web extraction found no recipe', {
          event: 'WEB_RECIPE_EXTRACTION_NO_CONTENT',
          sourceUrl,
          userId: req.user?.id,
          ip: req.ip,
        });

        res.json({
          success: false,
          message: 'Unable to extract a recipe from this page.',
        });
      }
    } catch (error) {
      logger.error('Web recipe extraction error', {
        event: 'WEB_RECIPE_EXTRACTION_ERROR',
        error: error instanceof Error ? error.message : String(error),
        userId: req.user?.id,
        ip: req.ip,
      });

      res.status(500).json({ error: 'Internal server error' });
    }
  }

  async previewRecipe(req: Request, res: Response): Promise<void> {
    try {
      const { html, sourceUrl } = req.body;

      const preview = await this.webExtractionService.previewRecipe(html, sourceUrl);

      if (preview) {
        logger.info('Web preview extraction successful', {
          event: 'WEB_PREVIEW_SUCCESS',
          sourceUrl,
          ip: req.ip,
        });

        res.json({ success: true, preview });
      } else {
        res.json({
          success: false,
          message: 'Unable to find recipe content on this page.',
        });
      }
    } catch (error) {
      logger.error('Web preview extraction error', {
        event: 'WEB_PREVIEW_ERROR',
        error: error instanceof Error ? error.message : String(error),
        ip: req.ip,
      });

      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
```

#### 3. `src/services/webExtractionService.ts`

```typescript
import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';
import { OpenAIService } from './openaiService';
import logger from './logger';

interface ExtractedArticle {
  title: string;
  content: string;      // HTML content
  textContent: string;  // Plain text (what we send to OpenAI)
  excerpt: string;
  byline: string | null;
  length: number;
}

export class WebExtractionService {
  private openaiService: OpenAIService;

  constructor() {
    this.openaiService = new OpenAIService();
  }

  /**
   * Extract recipe from HTML using Readability + OpenAI
   */
  async extractRecipe(html: string, sourceUrl?: string): Promise<Recipe | null> {
    // Step 1: Use Readability to extract article content
    const article = this.extractArticle(html, sourceUrl);

    if (!article || article.textContent.length < 100) {
      logger.debug('Readability extraction produced no content', {
        hasArticle: !!article,
        length: article?.textContent.length ?? 0,
      });
      return null;
    }

    logger.debug('Readability extraction successful', {
      title: article.title,
      textLength: article.textContent.length,
    });

    // Step 2: Build prompt with extracted text
    const inputText = this.buildExtractionInput(article, sourceUrl);

    // Step 3: Call OpenAI for recipe structuring
    // Uses same prompt pattern as clipping extraction
    const recipe = await this.openaiService.extractRecipeFromText(
      article.title,
      inputText
    );

    return recipe;
  }

  /**
   * Preview extraction (cheaper model, first 4 ingredients only)
   */
  async previewRecipe(html: string, sourceUrl?: string): Promise<RecipePreview | null> {
    const article = this.extractArticle(html, sourceUrl);

    if (!article || article.textContent.length < 100) {
      return null;
    }

    const inputText = this.buildExtractionInput(article, sourceUrl);

    const preview = await this.openaiService.extractRecipePreview(
      article.title,
      inputText
    );

    return preview;
  }

  /**
   * Use Readability to extract main article content from HTML
   */
  private extractArticle(html: string, sourceUrl?: string): ExtractedArticle | null {
    try {
      const dom = new JSDOM(html, {
        url: sourceUrl || 'https://example.com',
      });

      const reader = new Readability(dom.window.document, {
        // Don't let Readability parse ld+json - we handle that client-side
        disableJSONLD: true,
      });

      const article = reader.parse();

      if (!article) {
        return null;
      }

      return {
        title: article.title,
        content: article.content,
        textContent: article.textContent,
        excerpt: article.excerpt,
        byline: article.byline,
        length: article.length,
      };
    } catch (error) {
      logger.error('Readability parsing failed', {
        error: error instanceof Error ? error.message : String(error),
      });
      return null;
    }
  }

  /**
   * Build the input text for OpenAI from extracted article
   */
  private buildExtractionInput(article: ExtractedArticle, sourceUrl?: string): string {
    let input = '';

    if (sourceUrl) {
      input += `Source URL: ${sourceUrl}\n\n`;
    }

    if (article.byline) {
      input += `Author: ${article.byline}\n\n`;
    }

    input += article.textContent;

    // Truncate if too long (same limit as other extraction)
    const MAX_LENGTH = 50000;
    if (input.length > MAX_LENGTH) {
      input = input.substring(0, MAX_LENGTH) + '\n\n[Content truncated]';
    }

    return input;
  }
}
```

#### 4. `src/middleware/validation.ts` (addition)

```typescript
import { z } from 'zod';

export const webExtractionSchema = z.object({
  html: z.string()
    .min(100, 'HTML content too short')
    .max(500000, 'HTML content too large (max 500KB)'),
  sourceUrl: z.string()
    .url('Invalid URL format')
    .max(2000, 'URL too long')
    .optional(),
});

export function validateWebExtractionRequest(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  try {
    webExtractionSchema.parse(req.body);
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      const firstError = error.errors[0];
      res.status(400).json({
        error: `Invalid ${firstError.path.join('.')}: ${firstError.message}`,
      });
      return;
    }
    res.status(400).json({ error: 'Invalid request' });
  }
}
```

### Modified Files

#### `src/app.ts`

```typescript
import webRoutes from './routes/webRoutes';

// ... existing routes ...

app.use('/v1/web', webRoutes);
```

#### `package.json`

```json
{
  "dependencies": {
    "@mozilla/readability": "^0.5.0",
    "jsdom": "^24.0.0"
  },
  "devDependencies": {
    "@types/jsdom": "^21.1.6"
  }
}
```

---

## API Specification

### POST `/v1/web/extract-recipe`

**Authentication**: Required (Bearer token + Plus entitlement)

**Rate Limits**: 5/min, 100/day per IP

**Request**:
```json
{
  "html": "<html>...</html>",
  "sourceUrl": "https://example.com/recipe/123"
}
```

**Response (success)**:
```json
{
  "success": true,
  "recipe": {
    "title": "Classic Chocolate Chip Cookies",
    "description": "Soft and chewy cookies...",
    "servings": 24,
    "prepTime": 15,
    "cookTime": 12,
    "ingredients": [
      { "name": "2 cups all-purpose flour", "type": "ingredient" },
      { "name": "1 tsp baking soda", "type": "ingredient" }
    ],
    "steps": [
      { "text": "Preheat oven to 375°F.", "type": "step" },
      { "text": "Mix dry ingredients.", "type": "step" }
    ],
    "source": "https://example.com/recipe/123"
  }
}
```

**Response (no recipe found)**:
```json
{
  "success": false,
  "message": "Unable to extract a recipe from this page."
}
```

### POST `/v1/web/preview-recipe`

**Authentication**: Not required (API signature only)

**Rate Limits**: 5/day per IP

**Request**: Same as extract-recipe

**Response (success)**:
```json
{
  "success": true,
  "preview": {
    "title": "Classic Chocolate Chip Cookies",
    "description": "Soft and chewy homemade cookies with chocolate chips.",
    "previewIngredients": [
      "2 cups all-purpose flour",
      "1 tsp baking soda",
      "1 cup butter, softened",
      "3/4 cup sugar"
    ]
  }
}
```

---

## ld+json Recipe Schema Parsing

### Supported Schema Formats

```html
<!-- Format 1: Direct Recipe type -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Chocolate Chip Cookies",
  "recipeIngredient": ["2 cups flour", "1 cup sugar"],
  "recipeInstructions": ["Mix ingredients", "Bake at 350°F"]
}
</script>

<!-- Format 2: Nested in @graph -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    { "@type": "WebPage", ... },
    { "@type": "Recipe", "name": "..." }
  ]
}
</script>

<!-- Format 3: Array of types -->
<script type="application/ld+json">
[
  { "@type": "Organization", ... },
  { "@type": "Recipe", "name": "..." }
]
</script>
```

### Instruction Formats to Handle

```javascript
// Format 1: Simple string array
"recipeInstructions": [
  "Preheat oven to 350°F",
  "Mix ingredients"
]

// Format 2: HowToStep objects
"recipeInstructions": [
  { "@type": "HowToStep", "text": "Preheat oven to 350°F" },
  { "@type": "HowToStep", "text": "Mix ingredients" }
]

// Format 3: HowToSection with steps
"recipeInstructions": [
  {
    "@type": "HowToSection",
    "name": "Prepare Dough",
    "itemListElement": [
      { "@type": "HowToStep", "text": "Mix flour and sugar" }
    ]
  }
]
```

### Duration Parsing (ISO 8601)

```javascript
// Input: "PT1H30M" (1 hour 30 minutes)
// Output: 90 (minutes)

function parseDuration(iso: string): number | null {
  const match = iso.match(/PT(?:(\d+)H)?(?:(\d+)M)?/);
  if (!match) return null;

  const hours = parseInt(match[1] || '0', 10);
  const minutes = parseInt(match[2] || '0', 10);
  return hours * 60 + minutes;
}
```

---

## Subscription & Cost Considerations

| Extraction Method | Plus Required? | API Cost |
|-------------------|----------------|----------|
| ld+json schema parsing | No | Free (local) |
| Backend Readability + OpenAI (full) | Yes | ~$0.01-0.05 |
| Backend Readability + OpenAI (preview) | No | ~$0.002 |

**Cost Optimization**:
- ld+json parsing is completely free and handles majority of recipe sites
- Preview uses cheaper model (gpt-4.1-mini)
- Same rate limits as existing extraction endpoints

---

## Error Handling

### Frontend Error Types

| Scenario | Error Type | Message |
|----------|------------|---------|
| Network error fetching HTML | `noContentExtracted` | "We couldn't read this page." |
| Empty/too-short HTML | `noContentExtracted` | "The page didn't contain enough content." |
| No ld+json + backend returns null | `noRecipeDetected` | "This page doesn't appear to contain a recipe." |
| Backend error | `generic` | "Something went wrong while importing." |
| Offline | `noConnectivity` | "You're offline..." |

### Backend Error Responses

| Scenario | Status | Response |
|----------|--------|----------|
| HTML too short | 400 | `{ error: "HTML content too short" }` |
| HTML too large | 400 | `{ error: "HTML content too large" }` |
| Invalid URL | 400 | `{ error: "Invalid sourceUrl" }` |
| Rate limited | 429 | `{ error: "Rate limit exceeded" }` |
| No Plus (full extraction) | 403 | `{ error: "Plus subscription required" }` |
| OpenAI error | 500 | `{ error: "Internal server error" }` |

---

## Future: Embedded Browser Integration

This architecture supports the planned embedded browser feature:

```dart
class EmbeddedBrowserPage extends StatefulWidget {
  // ... WebView with "Extract Recipe" button

  Future<void> _onExtractTap() async {
    // Get HTML directly from WebView (no re-fetch needed)
    final html = await _webViewController.evaluateJavascript(
      'document.documentElement.outerHTML'
    );

    final currentUrl = await _webViewController.getUrl();

    // Use same extraction pipeline
    final extractor = GenericWebExtractor();
    final result = await extractor.extractFromHtml(
      html,
      sourceUrl: currentUrl,
    );

    if (result.success) {
      _openRecipeEditor(result.recipe!);
    } else {
      _showError(result.error);
    }
  }
}
```

---

## Testing Strategy

### Unit Tests

1. **JsonLdRecipeParser**
   - Parse various schema formats (direct, @graph, array)
   - Handle missing optional fields
   - Parse ISO 8601 durations
   - Handle malformed JSON gracefully

2. **WebExtractionService**
   - Mock Readability output → verify OpenAI input
   - Content truncation at 50KB
   - Empty content handling

### Integration Tests

1. **Full extraction flow**: URL → HTML → ld+json → Recipe
2. **Fallback flow**: URL → HTML → no schema → Backend → Recipe
3. **Preview flow**: Same paths with preview endpoints
4. **Error cases**: Invalid HTML, rate limits, auth failures

### Manual Test Sites

| Site | Has ld+json | Notes |
|------|-------------|-------|
| allrecipes.com | Yes | Full Recipe schema |
| seriouseats.com | Yes | Recipe + Article schema |
| bonappetit.com | Yes | Recipe schema |
| food.com | Yes | Recipe schema |
| nytimes.com/cooking | Yes | Paywalled, but schema in HTML |
| Random food blogs | Varies | Test Readability fallback |

---

## Implementation Order

### Phase 1: Backend (1-2 days)
1. Install @mozilla/readability and jsdom
2. Create webExtractionService.ts
3. Create webController.ts
4. Create webRoutes.ts with middleware
5. Add validation schema
6. Register routes in app.ts
7. Deploy and test endpoints

### Phase 2: Frontend - ld+json Parser (1 day)
1. Create json_ld_parser.dart
2. Unit tests for various schema formats
3. Duration parsing utility

### Phase 3: Frontend - Integration (1-2 days)
1. Create generic_web_extractor.dart
2. Create web_extraction_service.dart
3. Modify content_extractor.dart
4. Update share_session_modal.dart extraction flow
5. Test with real sites

### Phase 4: Polish (1 day)
1. Error message refinement
2. Logging and analytics
3. Edge case handling

---

## Design Decisions (Confirmed)

1. **HTML size limit**: 500KB max
2. **Timeout for HTML fetch**: 10 seconds
3. **ld+json extraction for non-Plus users**: Yes (free, local parsing)
4. **Cache Readability results?** Not for v1 - can add later if needed

---

## References

- [Schema.org Recipe](https://schema.org/Recipe)
- [Google Recipe Structured Data](https://developers.google.com/search/docs/appearance/structured-data/recipe)
- [@mozilla/readability GitHub](https://github.com/mozilla/readability)
- [JSON-LD Recipe Examples](https://jsonld.com/recipe/)
