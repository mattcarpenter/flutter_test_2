# Proposal: Make JSON-LD Recipe Extraction Free for All Users

**Date:** 2025-01-01
**Status:** Implemented
**Author:** Claude Code

---

## Executive Summary

Currently, all web recipe imports (URL, Share Sheet, Discover) require Plus subscription OR consume daily preview quota—even when recipes are extracted locally via JSON-LD schema without any backend API call.

This proposal makes JSON-LD extractions **completely free for all users** while keeping AI-powered backend extractions as a Plus feature. This change:

1. Removes friction for new users importing their first recipes
2. Aligns cost model with actual costs (JSON-LD = $0, AI = real cost)
3. Creates a natural upgrade moment only when AI is actually needed

---

## Background

### Current Two-Tier Extraction System

The app uses a smart two-tier extraction strategy:

| Tier | Method | Cost | Speed |
|------|--------|------|-------|
| **Tier 1: JSON-LD** | Local parsing of `<script type="application/ld+json">` | $0 (no API call) | Instant (<100ms) |
| **Tier 2: Backend AI** | Readability + OpenAI GPT-4.1 | ~$0.01-0.05/request | 3-8 seconds |

**JSON-LD coverage is excellent.** Most major recipe sites include schema.org structured data for SEO:
- AllRecipes, Food Network, Epicurious, Bon Appétit
- Serious Eats, Food52, Simply Recipes, Tasty
- NY Times Cooking, Delish, Yummly, and many more

### Current Gating Behavior

**All three import paths currently gate JSON-LD extractions:**

| Path | Plus User | Non-Plus User |
|------|-----------|---------------|
| Share Session | Opens editor immediately | Shows preview + upgrade CTA |
| URL Import | Opens editor immediately | Shows preview + upgrade CTA |
| Discover | Opens editor immediately | Shows preview + upgrade CTA |

**The problem:** Non-Plus users see an upgrade prompt even when zero API costs are incurred.

---

## Proposed Changes

### New Behavior Matrix

| Extraction Source | Plus User | Non-Plus User |
|-------------------|-----------|---------------|
| **JSON-LD (local)** | Opens editor | **Opens editor** (NEW) |
| **Backend AI** | Full extraction | Preview + upgrade CTA |

### User Experience Changes

#### 1. JSON-LD Recipes (Most Sites)

**Before:**
```
User shares AllRecipes link
  → JSON-LD parsed locally (free)
  → Non-Plus user sees preview
  → "Unlock with Plus" button
  → User frustrated (why pay for local parsing?)
```

**After:**
```
User shares AllRecipes link
  → JSON-LD parsed locally (free)
  → Recipe editor opens immediately
  → User delighted (zero friction!)
```

#### 2. Non-JSON-LD Recipes (Some Sites)

**Before (unchanged):**
```
User shares custom recipe blog without schema
  → No JSON-LD found
  → Non-Plus user sees preview (4 ingredients)
  → "Unlock with Plus" button
  → User understands AI extraction has value
```

**After (improved messaging):**
```
User shares custom recipe blog without schema
  → No JSON-LD found
  → Non-Plus user sees preview (4 ingredients)
  → NEW: "This recipe requires AI extraction"
  → "Unlock with Plus" button
  → User understands WHY this specific recipe needs Plus
```

---

## Technical Implementation

### Files to Modify

| File | Changes |
|------|---------|
| `lib/src/features/share/views/share_session_modal.dart` | Remove Plus gate for JSON-LD path |
| `lib/src/features/recipes/views/url_import_modal.dart` | Remove Plus gate for JSON-LD path |
| `lib/src/features/discover/views/discover_page.dart` | Remove Plus gate for JSON-LD path |
| `lib/src/features/share/widgets/share_recipe_preview_result.dart` | Update messaging for AI-required recipes |

### Detailed Changes

#### 1. Share Session Modal (`share_session_modal.dart`)

**Current code (lines 1182-1196):**
```dart
// Case 1: JSON-LD found
if (result.recipe != null && result.isFromJsonLd) {
  final hasPlus = ref.read(effectiveHasPlusProvider);
  if (hasPlus) {
    await _performJsonLdFullExtraction(result);
  } else {
    // UNLIMITED - JSON-LD is free (comment says this, but still shows preview!)
    await _showJsonLdPreview(result);
  }
}
```

**Proposed change:**
```dart
// Case 1: JSON-LD found - FREE for all users (no API cost)
if (result.recipe != null && result.isFromJsonLd) {
  // JSON-LD extraction is always free - no subscription check needed
  await _performJsonLdFullExtraction(result);
}
```

**Also update `_handleGenericWebImport()` (lines 1154-1239)** to remove the Plus check for the JSON-LD branch entirely.

#### 2. URL Import Modal (`url_import_modal.dart`)

**Current code (lines 205-220):**
```dart
if (result.recipe != null) {
  // JSON-LD found
  if (hasPlus) {
    await _openRecipeEditor(result.recipe!, result.imageUrl);
  } else {
    await _showPreviewSheet(context, preview!, result);
  }
}
```

**Proposed change:**
```dart
if (result.recipe != null && result.isFromJsonLd) {
  // JSON-LD found - FREE for all users (no API cost)
  await _openRecipeEditor(result.recipe!, result.imageUrl);
}
```

#### 3. Discover Page (`discover_page.dart`)

**Current code (lines 425-437):**
```dart
Future<void> _handleJsonLdRecipe(WebExtractionResult result) async {
  final hasPlus = ref.read(effectiveHasPlusProvider);
  if (hasPlus) {
    // Plus user - open editor directly
    await _openRecipeEditor(result.recipe!, result.imageUrl);
  } else {
    // Free user - show preview
    await _showPreviewSheet(context, result);
  }
}
```

**Proposed change:**
```dart
Future<void> _handleJsonLdRecipe(WebExtractionResult result) async {
  // JSON-LD extraction is always free - no subscription check needed
  await _openRecipeEditor(result.recipe!, result.imageUrl);
}
```

#### 4. Preview Result Widget (`share_recipe_preview_result.dart`)

**Add context-aware messaging for AI-required recipes:**

```dart
// In the preview widget, add a flag or check for extraction source
// When showing preview for backend-required extraction:

Widget _buildAiRequiredMessage() {
  return Container(
    padding: EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.of(context).surfaceSecondary,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(CupertinoIcons.wand_stars, size: 20),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'This recipe needs AI to extract. Upgrade to Plus for unlimited imports.',
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    ),
  );
}
```

---

## Edge Cases & Considerations

### 1. Recipe Limit Still Applies

JSON-LD extraction being free doesn't bypass the 6-recipe limit for non-Plus users. The flow becomes:

```
JSON-LD recipe imported
  → Check recipe limit (existing logic in add_recipe_modal.dart)
  → If < 6 recipes: Save normally
  → If >= 6 recipes: Recipe saved but locked (existing behavior)
```

**No changes needed** - the recipe limit is enforced at save time, not import time.

### 2. Image Download

Image downloading should work identically for JSON-LD extractions regardless of subscription:
- Extract image URL from JSON-LD `image` field
- Fallback to `og:image` meta tag
- Download, compress, save locally

**No changes needed** - `_downloadAndSaveImage()` doesn't check subscription.

### 3. Preemptive Extraction Timing

The share session modal starts extraction preemptively while loading. This behavior should remain unchanged:

```
Modal opens
  → Start JSON-LD extraction in background (free)
  → User sees options
  → User taps "Import Recipe"
  → Extraction already complete, open editor immediately
```

### 4. Error Handling

If JSON-LD parsing fails mid-extraction, the current fallback to backend should still require Plus:

```
JSON-LD parsing starts
  → Parsing fails or returns null
  → Fall back to backend extraction
  → Check subscription (existing behavior)
```

### 5. Analytics/Tracking

Consider adding analytics to track:
- JSON-LD extraction success rate (already extracted locally)
- Conversion from free JSON-LD imports to Plus subscription
- Which sites most commonly lack JSON-LD (candidates for backend optimization)

**Optional enhancement** - not required for this change.

---

## Migration Notes

### No Data Migration Needed

This is a pure client-side behavior change. No database changes, no backend changes, no user data migration.

### Feature Flag Option

If desired, this could be rolled out behind a feature flag:

```dart
final freeJsonLdExtractionEnabled = true; // or remote config

if (result.isFromJsonLd && (hasPlus || freeJsonLdExtractionEnabled)) {
  await _openRecipeEditor(result.recipe!, result.imageUrl);
}
```

**Recommendation:** Ship directly without feature flag since:
1. JSON-LD extraction is already implemented and stable
2. Change only removes a gate, doesn't add new code paths
3. Easy to revert if needed (re-add subscription check)

---

## Testing Plan

### Manual Testing Checklist

#### Share Session Flow
- [ ] Share AllRecipes link (has JSON-LD) as non-Plus user → Editor opens
- [ ] Share AllRecipes link as Plus user → Editor opens (unchanged)
- [ ] Share custom blog without JSON-LD as non-Plus user → Preview shown
- [ ] Share custom blog without JSON-LD as Plus user → Editor opens
- [ ] Verify recipe limit still enforced after JSON-LD import

#### URL Import Flow
- [ ] Import from URL with JSON-LD as non-Plus user → Editor opens
- [ ] Import from URL with JSON-LD as Plus user → Editor opens (unchanged)
- [ ] Import from URL without JSON-LD as non-Plus user → Preview shown
- [ ] Import from URL without JSON-LD as Plus user → Editor opens

#### Discover Flow
- [ ] Browse to recipe page with JSON-LD, tap Import as non-Plus user → Editor opens
- [ ] Browse to recipe page with JSON-LD, tap Import as Plus user → Editor opens
- [ ] Browse to page without JSON-LD, tap Import as non-Plus user → Preview shown
- [ ] Browse to page without JSON-LD, tap Import as Plus user → Editor opens

#### Edge Cases
- [ ] Import 7th recipe as non-Plus user via JSON-LD → Recipe saved but locked
- [ ] JSON-LD with missing image → Falls back to og:image correctly
- [ ] Malformed JSON-LD → Falls back to backend path (requires Plus)
- [ ] Offline import attempt → Shows offline error (unchanged)

### Sites for Testing

**JSON-LD Present (should now be free):**
- allrecipes.com
- foodnetwork.com
- bonappetit.com
- seriouseats.com
- food52.com

**JSON-LD Absent (should still require Plus):**
- Small personal blogs
- Sites with non-standard recipe formats
- Social media posts (Instagram, TikTok, YouTube - separate path, unchanged)

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users never upgrade because JSON-LD covers most sites | Medium | Medium | Recipe limit (6) is primary conversion lever, not import gating |
| Increased support requests about "why some recipes need Plus" | Low | Low | Improved messaging explains AI requirement |
| JSON-LD parsing has bugs we haven't seen at scale | Low | Medium | Parser is mature, used for Plus users already |

---

## Success Metrics

1. **Activation Rate**: % of new users who import 1+ recipes within first session
   - Hypothesis: Will increase as friction removed

2. **Recipe Import Volume**: Total JSON-LD imports per user
   - Hypothesis: Will increase for non-Plus users

3. **Conversion Rate**: % of users who hit recipe limit and upgrade
   - Hypothesis: Unchanged or improved (users see more value before hitting limit)

4. **Support Tickets**: Questions about import requirements
   - Hypothesis: Decrease with clearer AI-required messaging

---

## Implementation Order

1. **Phase 1: Core Change**
   - Modify `share_session_modal.dart` - Remove Plus check for JSON-LD
   - Modify `url_import_modal.dart` - Remove Plus check for JSON-LD
   - Modify `discover_page.dart` - Remove Plus check for JSON-LD

2. **Phase 2: Messaging**
   - Update preview widget with "AI required" messaging
   - Ensure error messages are clear when backend is needed

3. **Phase 3: Testing**
   - Manual testing per checklist above
   - Regression testing of Plus flows (should be unchanged)

---

## Appendix: Current Code Locations

### Share Session Modal
- File: `lib/src/features/share/views/share_session_modal.dart`
- JSON-LD handling: Lines 1182-1196
- Backend handling: Lines 1198-1239
- Plus check: Line 1186

### URL Import Modal
- File: `lib/src/features/recipes/views/url_import_modal.dart`
- JSON-LD handling: Lines 205-220
- Backend handling: Lines 222-252
- Plus check: Line 184

### Discover Page
- File: `lib/src/features/discover/views/discover_page.dart`
- JSON-LD handling: Lines 425-437
- Backend handling: Lines 440-463
- Plus check: Lines 427, 441

### Generic Web Extractor
- File: `lib/src/services/content_extraction/generic_web_extractor.dart`
- `isFromJsonLd` flag: Line 60
- Two-tier strategy: Lines 135-182

### JSON-LD Parser
- File: `lib/src/services/content_extraction/json_ld_parser.dart`
- Full parsing: Lines 22-35
- Schema detection: Lines 57-87

---

## Decision

**Awaiting approval to proceed with implementation.**

Please review and confirm:
1. Core approach (free JSON-LD, gated backend) is acceptable
2. Messaging changes for AI-required recipes are desired
3. Any additional edge cases to consider
