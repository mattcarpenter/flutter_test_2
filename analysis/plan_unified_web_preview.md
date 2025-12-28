# Plan: Unified Web Preview for All Import Paths

## Goal

Make all web extraction paths (excluding Instagram/TikTok/YouTube) show the same preview experience, while only enforcing rate limits on backend API calls.

**Current behavior:**
- JSON-LD: Full recipe → Editor (no preview, free)
- No JSON-LD: Preview → Paywall (limited to 5/day)

**Target behavior:**
- JSON-LD: Preview → Paywall (unlimited previews, no API call)
- No JSON-LD: Preview → Paywall (limited to 5/day API calls)
- Full extraction always requires Plus

---

## Scope

**In scope:**
- Generic web URLs (recipe blogs, etc.)
- JSON-LD and non-JSON-LD paths

**Out of scope:**
- Instagram, TikTok, YouTube (already implemented with their own preview flow)
- Clipping extraction (separate feature, unchanged)

---

## Implementation Plan

### Step 1: Add Helper to Convert ExtractedRecipe → RecipePreview

**File:** `lib/src/features/clippings/models/extracted_recipe.dart`

Add a method to `ExtractedRecipe` class:

```dart
/// Converts this full recipe to a preview (for display before purchase).
RecipePreview toPreview() {
  final description = this.description ?? '';
  return RecipePreview(
    title: title,
    description: description.length > 100
        ? '${description.substring(0, 97)}...'
        : description,
    previewIngredients: ingredients
        .where((ing) => ing.isIngredient)  // Exclude section headers
        .take(4)
        .map((ing) => ing.name)
        .toList(),
  );
}
```

**Requires import:** Add `import 'recipe_preview.dart';` at top of file.

---

### Step 2: Store JSON-LD Recipe for Post-Subscription Use

**File:** `lib/src/features/share/views/share_session_modal.dart`

Currently, `_webExtractionResult` stores the result which includes the full `ExtractedRecipe` from JSON-LD. This is already available - no change needed here.

However, we need to track the image URL for later use. The `_webExtractionResult.imageUrl` already contains this (from JSON-LD or og:image fallback).

---

### Step 3: Modify `_handleGenericWebImport()` to Show Preview for JSON-LD

**File:** `lib/src/features/share/views/share_session_modal.dart`
**Method:** `_handleGenericWebImport()` (lines 667-759)

**Current flow (JSON-LD path):**
```dart
if (result.recipe != null && result.isFromJsonLd) {
  // Download image...
  // Close modal, open recipe editor
  return;
}
```

**New flow (JSON-LD path):**
```dart
if (result.recipe != null && result.isFromJsonLd) {
  AppLogger.info('JSON-LD recipe found - showing preview');

  // Check subscription first
  final hasPlus = ref.read(effectiveHasPlusProvider);

  if (hasPlus) {
    // Plus user - skip preview, go straight to editor
    await _performJsonLdFullExtraction(result);
  } else {
    // Free user - show preview (no usage limit for JSON-LD)
    await _showJsonLdPreview(result);
  }
  return;
}
```

---

### Step 4: Add `_showJsonLdPreview()` Method

**File:** `lib/src/features/share/views/share_session_modal.dart`

Add new method after `_handleGenericWebImport()`:

```dart
/// Shows preview for JSON-LD extracted recipe (no API call, unlimited).
Future<void> _showJsonLdPreview(WebExtractionResult result) async {
  if (result.recipe == null) return;

  // Convert full recipe to preview format
  final preview = result.recipe!.toPreview();

  // Update modal state
  if (mounted) {
    setState(() {
      _modalState = _ModalState.showingRecipePreview;
    });
  }

  // Show preview bottom sheet (same UI as backend previews)
  if (mounted) {
    _showWebPreviewBottomSheet(
      context,
      preview,
      isFromJsonLd: true,  // Flag to use stored recipe on subscribe
    );
  }
}
```

**Note:** No usage counter increment here - JSON-LD previews are unlimited.

---

### Step 5: Add `_performJsonLdFullExtraction()` Method

**File:** `lib/src/features/share/views/share_session_modal.dart`

Add new method (extracted from current JSON-LD handling):

```dart
/// Performs full extraction for JSON-LD recipe (Plus users only).
Future<void> _performJsonLdFullExtraction(WebExtractionResult result) async {
  if (result.recipe == null) return;

  // Download image if available
  RecipeImage? coverImage;
  final imageUrl = result.imageUrl;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    AppLogger.info('Downloading recipe image...');
    coverImage = await _downloadAndSaveImage(imageUrl);
  }

  if (!mounted) return;

  // Close modal and open recipe editor
  widget.onClose();

  if (context.mounted) {
    final recipeEntry = _convertToRecipeEntry(result.recipe!, coverImage: coverImage);
    showRecipeEditorModal(
      context,
      ref: ref,
      recipe: recipeEntry,
      isEditing: false,
    );
  }
}
```

---

### Step 6: Create Unified `_showWebPreviewBottomSheet()` Method

**File:** `lib/src/features/share/views/share_session_modal.dart`

Create a new method that handles both JSON-LD and backend previews:

```dart
/// Shows preview bottom sheet for web extractions.
///
/// [isFromJsonLd] - If true, uses stored JSON-LD data on subscribe.
/// If false, calls backend for full extraction on subscribe.
void _showWebPreviewBottomSheet(
  BuildContext context,
  RecipePreview preview, {
  required bool isFromJsonLd,
}) {
  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: false,
    pageListBuilder: (sheetContext) => [
      WoltModalSheetPage(
        navBarHeight: 55,
        backgroundColor: AppColors.of(sheetContext).background,
        surfaceTintColor: Colors.transparent,
        hasTopBarLayer: false,
        isTopBarLayerAlwaysVisible: false,
        trailingNavBarWidget: Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.neutral,
            size: 32,
            onPressed: () {
              Navigator.of(sheetContext, rootNavigator: true).pop();
              widget.onClose();
            },
          ),
        ),
        child: ShareRecipePreviewResultContent(
          preview: preview,
          onSubscribe: () async {
            if (!context.mounted) return;

            final purchased = await ref
                .read(subscriptionProvider.notifier)
                .presentPaywall(context);

            if (purchased && context.mounted) {
              // Close preview sheet and share modal
              if (sheetContext.mounted) {
                Navigator.of(sheetContext, rootNavigator: true).pop();
              }
              widget.onClose();

              // Perform full extraction based on source
              final rootContext = globalRootNavigatorKey.currentContext;
              if (rootContext != null && rootContext.mounted) {
                if (isFromJsonLd) {
                  // Use stored JSON-LD recipe
                  await _performJsonLdFullExtraction(_webExtractionResult!);
                } else {
                  // Call backend for full extraction
                  await _performPostWebSubscriptionExtraction(rootContext);
                }
              }
            }
          },
        ),
      ),
    ],
  );
}
```

---

### Step 7: Add `_performPostWebSubscriptionExtraction()` Method

**File:** `lib/src/features/share/views/share_session_modal.dart`

This handles the backend extraction path after subscription (similar to existing `_performPostSubscriptionExtraction` but for web):

```dart
/// Performs full web extraction after user subscribes from preview.
Future<void> _performPostWebSubscriptionExtraction(BuildContext context) async {
  final webResult = _webExtractionResult;
  if (webResult == null || !webResult.hasHtml) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No content available to extract.')),
      );
    }
    return;
  }

  // Show extraction progress modal
  var isExtracting = true;
  String? errorMessage;

  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (builderContext, setModalState) {
            if (isExtracting && errorMessage == null) {
              Future.microtask(() async {
                try {
                  final service = ref.read(webExtractionServiceProvider);
                  final recipe = await service.extractRecipe(
                    html: webResult.html!,
                    sourceUrl: webResult.sourceUrl,
                  );

                  if (!modalContext.mounted) return;

                  if (recipe == null) {
                    setModalState(() {
                      isExtracting = false;
                      errorMessage = 'No recipe found on this page.';
                    });
                    return;
                  }

                  // Download image
                  RecipeImage? coverImage;
                  final imageUrl = webResult.imageUrl;
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    coverImage = await _downloadAndSaveImage(imageUrl);
                  }

                  if (!modalContext.mounted) return;

                  Navigator.of(modalContext, rootNavigator: true).pop();

                  if (context.mounted) {
                    final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);
                    showRecipeEditorModal(
                      context,
                      ref: ref,
                      recipe: recipeEntry,
                      isEditing: false,
                    );
                  }
                } on WebExtractionException catch (e) {
                  if (modalContext.mounted) {
                    setModalState(() {
                      isExtracting = false;
                      errorMessage = e.message;
                    });
                  }
                } catch (e) {
                  AppLogger.error('Post-subscription web extraction failed', e);
                  if (modalContext.mounted) {
                    setModalState(() {
                      isExtracting = false;
                      errorMessage = 'Failed to extract recipe. Please try again.';
                    });
                  }
                }
              });
            }

            // Build UI (same pattern as _performPostSubscriptionExtraction)
            if (isExtracting && errorMessage == null) {
              return _buildExtractingModalContent(builderContext);
            } else {
              return _buildErrorModalContent(
                builderContext,
                modalContext,
                errorMessage,
              );
            }
          },
        ),
      ),
    ],
  );
}
```

---

### Step 8: Update `_performWebPreviewExtraction()` to Use New Method

**File:** `lib/src/features/share/views/share_session_modal.dart`
**Method:** `_performWebPreviewExtraction()` (lines 832-891)

Change the preview display call to use the new unified method:

```dart
// Old:
_showPreviewBottomSheet(context, preview);

// New:
_showWebPreviewBottomSheet(context, preview, isFromJsonLd: false);
```

---

### Step 9: Extract Modal Content Builders (Optional Refactor)

To avoid code duplication in the post-subscription modal, extract these helper methods:

```dart
Widget _buildExtractingModalContent(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Importing Recipe',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxl),
        const CupertinoActivityIndicator(radius: 16),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Extracting recipe...',
          style: AppTypography.body.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    ),
  );
}

Widget _buildErrorModalContent(
  BuildContext builderContext,
  BuildContext modalContext,
  String? errorMessage,
) {
  return Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Extraction Failed',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(builderContext).textPrimary,
              ),
            ),
            AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () => Navigator.of(modalContext, rootNavigator: true).pop(),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          errorMessage ?? 'An error occurred.',
          style: AppTypography.body.copyWith(
            color: AppColors.of(builderContext).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    ),
  );
}
```

---

## Flow Diagrams

### Before (Current)

```
Share URL from Safari
    │
    ├─→ JSON-LD found?
    │       │
    │       ├─ Yes → Download image → Open recipe editor (FREE)
    │       │
    │       └─ No → Check Plus subscription
    │               │
    │               ├─ Plus → Backend extraction → Editor
    │               │
    │               └─ Free → Check preview limit
    │                       │
    │                       ├─ Limit OK → Backend preview → Preview sheet
    │                       │
    │                       └─ Limit exceeded → Paywall
```

### After (Target)

```
Share URL from Safari
    │
    ├─→ JSON-LD found?
    │       │
    │       ├─ Yes → Check Plus subscription
    │       │       │
    │       │       ├─ Plus → Download image → Open recipe editor
    │       │       │
    │       │       └─ Free → Create preview locally → Preview sheet (UNLIMITED)
    │       │                                              │
    │       │                                              └─→ Subscribe → Use stored recipe
    │       │
    │       └─ No → Check Plus subscription
    │               │
    │               ├─ Plus → Backend extraction → Editor
    │               │
    │               └─ Free → Check preview limit
    │                       │
    │                       ├─ Limit OK → Backend preview → Preview sheet (LIMITED)
    │                       │                                   │
    │                       │                                   └─→ Subscribe → Backend extraction
    │                       │
    │                       └─ Limit exceeded → Paywall
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/src/features/clippings/models/extracted_recipe.dart` | Add `toPreview()` method |
| `lib/src/features/share/views/share_session_modal.dart` | Refactor JSON-LD flow, add new methods |

---

## Testing Checklist

1. **JSON-LD site (free user):**
   - [ ] Shows preview instantly (no loading spinner for extraction)
   - [ ] No usage counter increment
   - [ ] "Unlock with Plus" button works
   - [ ] After subscribing, uses stored JSON-LD data (no backend call)

2. **JSON-LD site (Plus user):**
   - [ ] Goes straight to recipe editor (no preview)
   - [ ] Image downloaded correctly

3. **Non-JSON-LD site (free user, quota available):**
   - [ ] Shows loading spinner
   - [ ] Shows preview after backend call
   - [ ] Usage counter incremented
   - [ ] "Unlock with Plus" button works
   - [ ] After subscribing, calls backend for full extraction

4. **Non-JSON-LD site (free user, quota exceeded):**
   - [ ] Goes straight to paywall (no preview)
   - [ ] After subscribing, calls backend for full extraction

5. **Non-JSON-LD site (Plus user):**
   - [ ] Goes straight to backend extraction
   - [ ] Opens recipe editor with full recipe

6. **Instagram/TikTok/YouTube:**
   - [ ] Unchanged behavior (uses existing social media flow)

---

## Risks & Considerations

1. **Preview UI consistency:** The preview shown for JSON-LD should look identical to backend previews. Both use `ShareRecipePreviewResultContent` with `RecipePreview` data.

2. **Error handling:** JSON-LD path has fewer error cases (no network call for preview), but image download can still fail. Handle gracefully.

3. **State management:** `_webExtractionResult` must remain available until after subscription. Current implementation stores it as instance variable, which is fine.

4. **Modal context lifecycle:** The post-subscription extraction uses `globalRootNavigatorKey.currentContext` because the original modal is closed. This pattern already exists and works.

---

## Estimated Changes

- **extracted_recipe.dart:** ~15 lines (new method)
- **share_session_modal.dart:** ~150 lines (new methods, refactored flow)
- **Total:** ~165 lines of new/modified code