# Free vs Plus Guide

This document outlines the differences between Free and Plus subscription tiers, including feature access, limits, and the technical implementation.

---

## Table of Contents

1. [Core Model](#core-model)
2. [Recipe Limits](#recipe-limits)
3. [Import Paths](#import-paths)
4. [AI Extraction Rate Limits](#ai-extraction-rate-limits)
5. [Feature Comparison](#feature-comparison)
6. [Technical Implementation](#technical-implementation)
7. [Key Files](#key-files)

---

## Core Model

The app uses a simple two-tier subscription model:

| Tier | Recipe Access | AI Extraction |
|------|---------------|---------------|
| **Free** | First 6 recipes (by creation date) | 5 previews/day per feature |
| **Plus** | Unlimited | Unlimited |

**The primary value proposition of Plus is unlimited recipe storage.** The AI extraction limits are secondary — they exist primarily for cost management on API-backed features.

---

## Recipe Limits

### How It Works

- **Free users:** Can access their **first 6 recipes** (oldest by `createdAt` timestamp)
- **Plus users:** Unlimited recipe access

Recipes beyond the limit are **locked**, not deleted. They remain synced and visible (with reduced opacity + lock icon), but tapping them shows an upgrade prompt.

### User Experience

| Action | Free (< 6 recipes) | Free (≥ 6 recipes) | Plus |
|--------|-------------------|-------------------|------|
| View recipe list | All visible | Locked recipes show lock icon, 70% opacity | All visible |
| Tap unlocked recipe | Opens normally | Opens normally | Opens normally |
| Tap locked recipe | N/A | Shows `LockedRecipePage` with upgrade CTA | N/A |
| Add new recipe | Recipe editor opens | Paywall shown instead | Recipe editor opens |
| Import recipes | All imported, excess locked | All imported, excess locked | All imported |

### Unlocking Logic

The **oldest 6 recipes** (by `createdAt`) are always unlocked. This means:
- If you delete an unlocked recipe, another becomes unlocked
- Newly imported recipes may be locked immediately if you already have 6+

### UI Indicators

**Recipe Tile (locked):**
- 70% opacity
- Lock icon in top-right corner

**Locked Recipe Page:**
- Recipe image teaser (150x150)
- Recipe title
- "Your first 6 recipes are free"
- "Upgrade to save unlimited recipes"
- "Upgrade to Plus" button

---

## Import Paths

All import paths ultimately create recipes, which are subject to the 6-recipe limit for free users.

### Path 1: JSON-LD Schema (Client-Side)

**Source:** Recipe blogs with schema.org structured data

| Aspect | Details |
|--------|---------|
| **Cost** | Free (no API call) |
| **Speed** | Instant (local parsing) |
| **Output** | Full recipe |
| **Limit** | None — but recipe still counts toward 6-recipe limit |

**How it works:**
1. Fetch HTML from URL
2. Parse `<script type="application/ld+json">` for Recipe schema
3. Extract title, ingredients, steps, image, etc.
4. Open recipe editor with pre-filled data

### Path 2: Social Media (Instagram/TikTok/YouTube)

**Source:** Shared posts from social media apps

| Aspect | Details |
|--------|---------|
| **Cost** | API call (OpenAI) |
| **Speed** | 2-5 seconds |
| **Output** | Full recipe (Plus) or preview (Free) |
| **Limit** | Plus: 5/min, 100/day · Free: 5 previews/day |

**How it works:**
1. Fetch page, extract OG meta tags (title, description, image)
2. Send to backend for AI extraction
3. GPT-4.1 structures content into recipe format

### Path 3: Generic Websites (Readability + AI)

**Source:** Recipe blogs without JSON-LD structured data

| Aspect | Details |
|--------|---------|
| **Cost** | API call (Readability + OpenAI) |
| **Speed** | 3-8 seconds |
| **Output** | Full recipe (Plus) or preview (Free) |
| **Limit** | Plus: 5/min, 100/day · Free: 5 previews/day |

**How it works:**
1. Fetch HTML from URL
2. Try JSON-LD parsing first (free path)
3. If no JSON-LD, send HTML to backend
4. Mozilla Readability extracts article content
5. GPT-4.1 structures content into recipe format

### Path 4: Clipping → Recipe

**Source:** Saved clippings in the app

| Aspect | Details |
|--------|---------|
| **Cost** | API call (OpenAI) |
| **Speed** | 2-5 seconds |
| **Output** | Full recipe (Plus) or preview (Free) |
| **Limit** | Plus: 5/min, 100/day · Free: 5 previews/day |

### Path 5: Clipping → Shopping List

**Source:** Saved clippings in the app

| Aspect | Details |
|--------|---------|
| **Cost** | API call (OpenAI) |
| **Speed** | 2-5 seconds |
| **Output** | Full item list (Plus) or preview (Free) |
| **Limit** | Plus: 5/min, 100/day · Free: 5 previews/day |

### Path 6: Save as Clipping

**Source:** Any shared URL

| Aspect | Details |
|--------|---------|
| **Cost** | Free (no API call) |
| **Speed** | Instant |
| **Output** | Clipping with URL, OG metadata, and JSON-LD recipe if available |
| **Limit** | None |

---

## AI Extraction Rate Limits

These limits exist primarily for **cost management** — AI extraction has real per-request costs.

### Free Users: Preview Limits

Free users get **5 previews per day** for each AI-backed feature:

| Feature | Daily Limit | Tracking |
|---------|-------------|----------|
| Share → Recipe | 5/day | `share_recipe_preview_usage_YYYY-MM-DD` |
| Clipping → Recipe | 5/day | `recipe_preview_usage_YYYY-MM-DD` |
| Clipping → Shopping List | 5/day | `shopping_list_preview_usage_YYYY-MM-DD` |

**These are independent quotas.** A free user gets 15 total previews/day across features.

**Preview content:**
- Title and description
- First 4 ingredients only
- Faded/teaser UI with upgrade CTA

**Reset:** Midnight local device time

### Plus Users: Rate Limits

Plus users have generous but finite limits to prevent abuse:

| Limit | Value |
|-------|-------|
| Per minute | 5 requests |
| Per day | 100 requests |

These limits apply per-endpoint and are enforced server-side.

### Backend Endpoints

| Endpoint | Auth | Plus Required | Rate Limit |
|----------|------|---------------|------------|
| `POST /v1/share/extract-recipe` | Yes | Yes | 5/min, 100/day |
| `POST /v1/share/preview-recipe` | Signature | No | 5/day |
| `POST /v1/web/extract-recipe` | Yes | Yes | 5/min, 100/day |
| `POST /v1/web/preview-recipe` | Signature | No | 5/day |
| `POST /v1/clippings/extract-recipe` | Yes | Yes | 5/min, 100/day |
| `POST /v1/clippings/preview-recipe` | Signature | No | 5/day |
| `POST /v1/clippings/extract-shopping-list` | Yes | Yes | 5/min, 100/day |
| `POST /v1/clippings/preview-shopping-list` | Signature | No | 5/day |

---

## Feature Comparison

| Feature | Free | Plus |
|---------|------|------|
| **Recipe Storage** | 6 recipes | Unlimited |
| **JSON-LD Import** | Unlimited | Unlimited |
| **AI Recipe Import** | 5 previews/day | Unlimited |
| **AI Shopping List** | 5 previews/day | Unlimited |
| **Save as Clipping** | Unlimited | Unlimited |
| **Pantry Matching** | Yes | Yes |
| **Shopping List** | Yes | Yes |
| **Recipe Sharing** | Yes | Yes |
| **Household Sharing** | Plus extends to household | Yes |

---

## Technical Implementation

### Subscription Detection

**Provider:** `effectiveHasPlusProvider`

Combines:
1. **Database truth** (`dbHasPlus`) — from `user_subscriptions` table via PowerSync
2. **Optimistic access** (`optimisticHasPlus`) — immediate access after purchase

### Recipe Limit Providers

```dart
const int kFreeRecipeLimit = 6;

// Set of unlocked recipe IDs
final unlockedRecipeIdsProvider = Provider<Set<String>>((ref) {
  final hasPlus = ref.watch(effectiveHasPlusProvider);
  if (hasPlus) return allRecipeIds; // All unlocked

  // First 6 by createdAt
  return recipes
    .sorted((a, b) => a.createdAt.compareTo(b.createdAt))
    .take(kFreeRecipeLimit)
    .map((r) => r.id)
    .toSet();
});

// Check if specific recipe is locked
final isRecipeLockedProvider = Provider.family<bool, String>((ref, recipeId) {
  final unlockedIds = ref.watch(unlockedRecipeIdsProvider);
  return !unlockedIds.contains(recipeId);
});

// Remaining slots for new recipes
final remainingRecipeSlotsProvider = Provider<int>((ref) {
  final hasPlus = ref.watch(effectiveHasPlusProvider);
  if (hasPlus) return -1; // -1 = unlimited

  final count = ref.watch(userRecipeCountProvider);
  return (kFreeRecipeLimit - count).clamp(0, kFreeRecipeLimit);
});
```

### Add Recipe Gate

```dart
Future<void> showRecipeEditorModal(...) async {
  if (recipe == null && ref != null) {
    final remainingSlots = ref.read(remainingRecipeSlotsProvider);

    if (remainingSlots == 0) {
      // No slots → show paywall instead of editor
      await ref.read(subscriptionProvider.notifier).presentPaywall(context);
      return;
    }
  }
  // Show recipe editor...
}
```

### Preview Usage Tracking

```dart
class PreviewUsageService {
  static const int dailyLimit = 5;

  String _todayKey(String prefix) =>
    '$prefix${DateTime.now().toIso8601String().substring(0, 10)}';

  bool hasRecipePreviewsRemaining() {
    final used = _prefs.getInt(_todayKey(_recipeKeyPrefix)) ?? 0;
    return used < dailyLimit;
  }

  Future<void> incrementRecipeUsage() async {
    final key = _todayKey(_recipeKeyPrefix);
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);
  }
}
```

### AI Extraction Flow

```dart
// 1. Check subscription first
final hasPlus = ref.read(effectiveHasPlusProvider);

if (hasPlus) {
  // Full extraction
  await performFullExtraction();
} else {
  // Check preview quota
  final usageService = ref.read(previewUsageServiceProvider);

  if (!usageService.hasPreviewsRemaining()) {
    // Quota exceeded → paywall
    await presentPaywall();
  } else {
    // Show preview
    await performPreviewExtraction();
    await usageService.incrementUsage();
  }
}
```

---

## Key Files

### Recipe Limit

| File | Purpose |
|------|---------|
| `lib/src/providers/recipe_provider.dart` | Limit constants and providers |
| `lib/src/features/recipes/views/add_recipe_modal.dart` | Blocks adding when limit reached |
| `lib/src/features/recipes/views/recipe_page.dart` | Gates to locked page |
| `lib/src/features/recipes/views/locked_recipe_page.dart` | Upgrade prompt UI |
| `lib/src/features/recipes/widgets/recipe_tile.dart` | Lock icon overlay |

### Subscription

| File | Purpose |
|------|---------|
| `lib/src/providers/subscription_provider.dart` | Subscription state and paywall |
| `lib/src/services/subscription_service.dart` | RevenueCat integration |

### AI Extraction

| File | Purpose |
|------|---------|
| `lib/src/services/preview_usage_service.dart` | Client-side preview tracking |
| `lib/src/services/share_extraction_service.dart` | Social media extraction |
| `lib/src/services/web_extraction_service.dart` | Web page extraction |
| `lib/src/services/clipping_extraction_service.dart` | Clipping extraction |

### Import Paths

| File | Purpose |
|------|---------|
| `lib/src/features/share/views/share_session_modal.dart` | Share flow entry point |
| `lib/src/services/content_extraction/json_ld_parser.dart` | JSON-LD parsing |
| `lib/src/services/content_extraction/generic_web_extractor.dart` | Web extraction orchestration |
| `lib/src/features/clippings/views/clipping_extraction_modal.dart` | Clipping conversion |

---

## Summary

**Free tier value:**
- 6 full recipes with all features
- Unlimited clipping storage
- Unlimited JSON-LD imports (subject to 6-recipe limit)
- 5 AI previews/day per feature type

**Plus tier value:**
- Unlimited recipe storage
- Unlimited AI extraction
- Household sharing of Plus benefits

**Design philosophy:**
- Recipe limit is the primary conversion lever
- AI limits are cost management, not monetization
- Free users get full functionality, just limited capacity
- Locked recipes create natural upgrade moments