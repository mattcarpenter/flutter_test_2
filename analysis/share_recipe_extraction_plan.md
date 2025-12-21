# Share Recipe Extraction Feature - Implementation Plan

## Overview

This document outlines the plan for implementing recipe extraction from shared social media content (Instagram, TikTok). When a user shares a post to the app and taps "Import Recipe", we'll send the extracted text content to our backend for AI-powered recipe structuring.

## Current State

### What Exists

**Flutter App:**
- Share extension receives URLs from Instagram/TikTok
- `ContentExtractor` fetches OG content (title, description, image) via HTTP/WebView
- Share session modal shows two buttons: "Import Recipe" and "Save as Clipping"
- `_proceedWithAction()` is a TODO stub that just logs and closes the modal

**Backend:**
- Clipping extraction endpoints at `/v1/clippings/`:
  - `extract-recipe` - Full extraction (Plus required)
  - `preview-recipe` - Preview extraction (5/day limit, no auth)
- `clippingExtractionService.ts` with GPT-4.1 integration for recipe parsing
- API signature verification, auth middleware, rate limiting

### Gap Analysis

1. No dedicated endpoints for share/social media extraction
2. Share modal doesn't call any backend extraction
3. No preview flow for share feature
4. No usage tracking for share previews

---

## Proposed Architecture

### New Backend Route: `/v1/share`

Create a new route file `shareRoutes.ts` with two endpoints:

| Endpoint | Auth | Subscription | Rate Limit | Purpose |
|----------|------|--------------|------------|---------|
| `POST /v1/share/extract-recipe` | Required | Plus Required | 5/min, 100/day | Full recipe extraction |
| `POST /v1/share/preview-recipe` | None | None | 5/day per IP | Preview extraction |

### Request Schema

```typescript
interface ShareExtractionRequest {
  content: string;      // The text content (OG description, post caption)
  title?: string;       // Optional title (OG title or post author)
  sourceUrl?: string;   // Original URL (for metadata/source tracking)
  sourcePlatform?: 'instagram' | 'tiktok' | 'other';  // Platform identifier
}
```

### Response Schemas

**Full Extraction Response:**
```typescript
interface ExtractRecipeResponse {
  success: boolean;
  recipe?: {
    title: string;
    description?: string;
    servings?: number;
    prepTime?: number;
    cookTime?: number;
    ingredients: Array<{ name: string; type: 'ingredient' | 'section' }>;
    steps: Array<{ text: string; type: 'step' | 'section' }>;
    source?: string;  // Original URL
  };
  message?: string;  // Error message if success=false
}
```

**Preview Response:**
```typescript
interface PreviewRecipeResponse {
  success: boolean;
  preview?: {
    title: string;
    description: string;
    previewIngredients: string[];  // First 4 ingredients only
  };
  message?: string;
}
```

---

## Backend Implementation Details

### 1. New Route File: `src/routes/shareRoutes.ts`

**Middleware Chain:**
- Full extraction: `verifyApiSignature → authenticateUser → verifyPlusEntitlement → rateLimiter → validateRequest → controller`
- Preview: `verifyApiSignature → previewRateLimiter → validateRequest → controller`

### 2. New Controller: `src/controllers/shareController.ts`

Two methods:
- `extractRecipeFromShare()` - Calls extraction service, logs metrics
- `previewRecipeFromShare()` - Calls preview service, logs metrics

### 3. Reuse Existing Extraction Service

The `clippingExtractionService.ts` already has:
- `extractRecipeFromText(title, body)` - Returns full `ExtractedRecipe`
- `extractRecipePreview(title, body)` - Returns `RecipePreview`

We can directly reuse these functions. The only difference is the input source (share content vs clipping text).

### 4. Rate Limiting

**Decision: Separate Limits**
- Share previews: 5/day per IP (independent quota)
- Clipping previews: 5/day per IP (separate quota)
- Users get 5 share previews + 5 clipping previews per day
- Requires separate rate limiter in backend

### 5. Validation Schema

```typescript
const ShareExtractionRequestSchema = z.object({
  content: z.string().min(1).max(50000),  // Required, same limit as clippings
  title: z.string().max(200).optional().default(''),
  sourceUrl: z.string().url().optional(),
  sourcePlatform: z.enum(['instagram', 'tiktok', 'other']).optional(),
});
```

---

## Flutter Implementation Details

### 1. New API Service: `share_extraction_service.dart`

Similar to `clipping_extraction_service.dart`:

```dart
class ShareExtractionService {
  Future<ExtractedRecipe?> extractRecipe({
    required String content,
    String? title,
    String? sourceUrl,
    String? sourcePlatform,
  });

  Future<RecipePreview?> previewRecipe({
    required String content,
    String? title,
    String? sourceUrl,
    String? sourcePlatform,
  });
}
```

### 2. Update Share Session Modal

When user taps "Import Recipe":

```dart
void _handleImportRecipe() async {
  final hasPlus = ref.read(effectiveHasPlusProvider);

  if (hasPlus) {
    // Full extraction flow
    await _showFullRecipeExtraction();
  } else {
    // Preview flow with quota check
    final usageService = await ref.read(previewUsageServiceProvider.future);

    if (!usageService.hasRecipePreviewsRemaining()) {
      // Quota exceeded → show paywall
      final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
      if (purchased) {
        await _showFullRecipeExtraction();
      }
    } else {
      // Show preview
      await _showRecipePreviewExtraction();
    }
  }
}
```

### 3. Extraction Flow States

Update the modal state machine:

```dart
enum ShareModalState {
  choosingAction,      // Initial - show buttons
  extractingContent,   // OG extraction in progress (already exists)
  extractingRecipe,    // NEW: AI extraction in progress
  showingRecipePreview,// NEW: Show preview for non-Plus users
  showingRecipeEditor, // NEW: Show full recipe for editing before save
  savingRecipe,        // NEW: Saving to database
  completed,           // Done
  error,               // Error state
}
```

### 4. Preview UI Component

Create `ShareRecipePreviewResult` widget (similar to `RecipePreviewResult`):
- Shows extracted title
- Shows first 4 ingredients with fade effect
- Value prop overlay: "We'll structure this into a real recipe"
- "Unlock with Plus" CTA button

### 5. Full Extraction Flow

After successful extraction:
1. Show recipe in editor modal for review/editing
2. User can modify title, ingredients, steps
3. User confirms → recipe is saved to database
4. Modal closes, user returns to app

### 6. Input Mapping

Map OG content to extraction request:

```dart
final request = ShareExtractionRequest(
  content: extractedContent.description ?? '',  // Main text content
  title: extractedContent.title,                 // Post title/author
  sourceUrl: originalUrl.toString(),             // e.g., instagram.com/p/xxx
  sourcePlatform: _detectPlatform(originalUrl),  // 'instagram' or 'tiktok'
);
```

---

## File Changes Summary

### Backend (recipe_app_server)

| File | Action | Description |
|------|--------|-------------|
| `src/routes/shareRoutes.ts` | Create | New route with extract-recipe and preview-recipe |
| `src/controllers/shareController.ts` | Create | Controller methods for share extraction |
| `src/middleware/validation.ts` | Update | Add ShareExtractionRequestSchema |
| `src/app.ts` or `src/routes/index.ts` | Update | Register new share routes |

### Flutter (flutter_test_2)

| File | Action | Description |
|------|--------|-------------|
| `lib/src/services/share_extraction_service.dart` | Create | API client for share endpoints |
| `lib/src/services/preview_usage_service.dart` | Update | Add share preview tracking (separate from clipping) |
| `lib/src/features/share/views/share_session_modal.dart` | Update | Implement Import Recipe flow |
| `lib/src/features/share/widgets/share_recipe_preview_result.dart` | Create | Preview UI component |
| `lib/src/features/share/views/share_recipe_editor_modal.dart` | Create | Recipe editor for review before save |

---

## Design Decisions (Confirmed)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Preview Limits | **Separate** | 5/day for share + 5/day for clippings (independent quotas) |
| After Extraction | **Show Editor** | Let user review/edit recipe before saving to library |
| Source URL | **Store It** | Save original URL in recipe's `source` field for attribution |
| OG Extraction Failure | **Error + Suggest Clipping** | Show error message, suggest saving as clipping instead |

### Important: Timing of API Calls

**OG Content Extraction (preemptive):**
- Starts automatically when share modal opens
- Runs in background to get "head start"
- Just extracts title/description from the social media post

**Backend Recipe Extraction (on-demand):**
- Only called when user taps "Import Recipe" button
- Uses the preemptively-extracted OG content as input
- Calls our backend to structure it into a recipe with AI

This distinction is important: we don't waste API calls (and AI costs) unless the user actually wants to import a recipe.

---

## Implementation Order

### Phase 1: Backend (Day 1)
1. Create `shareRoutes.ts` with endpoint definitions
2. Create `shareController.ts` with extraction methods
3. Add validation schema
4. Register routes in app
5. Test endpoints manually

### Phase 2: Flutter - Basic Flow (Day 1-2)
1. Create `share_extraction_service.dart`
2. Update share modal to call extraction on "Import Recipe"
3. Implement loading state during extraction
4. Handle extraction success → show recipe editor
5. Handle extraction failure → show error

### Phase 3: Flutter - Preview Flow (Day 2)
1. Add preview extraction method to service
2. Implement subscription check before extraction
3. Create preview UI component with fade effect
4. Integrate with existing preview usage tracking
5. Add paywall presentation for quota exceeded

### Phase 4: Polish & Edge Cases (Day 3)
1. Handle offline/network errors gracefully
2. Add retry mechanism
3. Improve loading animations
4. Test with real Instagram/TikTok content
5. Handle edge cases (empty content, very long content)

---

## Testing Plan

### Backend Tests
- [ ] Extract recipe from valid Instagram caption
- [ ] Extract recipe from valid TikTok description
- [ ] Preview endpoint returns limited data
- [ ] Rate limiting works correctly
- [ ] Auth/subscription checks work correctly
- [ ] Invalid/empty content handled gracefully

### Flutter Tests
- [ ] Plus user gets full extraction
- [ ] Free user with quota gets preview
- [ ] Free user without quota sees paywall
- [ ] After purchase, extraction proceeds
- [ ] Preview usage is tracked correctly
- [ ] Network errors show appropriate message
- [ ] Recipe editor allows modifications
- [ ] Recipe saves correctly to database

---

## Success Metrics

1. **Conversion:** % of share sessions that result in saved recipe
2. **Extraction Quality:** % of extractions that produce valid recipes
3. **Preview-to-Purchase:** % of preview users who subscribe
4. **Error Rate:** % of extraction failures

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Social media content often lacks full recipes | Set clear expectations in UI; suggest clipping for non-recipe content |
| Rate limiting may frustrate users | Clear messaging about limits; encourage subscription |
| AI extraction may produce poor results | Allow editing before save; show preview first |
| Platform changes break extraction | Monitor extraction success rate; update extractors as needed |