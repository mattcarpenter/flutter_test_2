# Recipe Limit Implementation Plan

**Feature:** Limit free users to 6 accessible recipes. Plus subscribers get unlimited.

---

## Overview

Non-subscribed users can have unlimited recipes in their library (via import, past subscription, etc.) but can only **access** the first 6 (by creation date). Recipes beyond the limit show in lists with a lock indicator, and tapping them presents the paywall.

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Limit count | 6 recipes | Enough to try the app, not enough for serious use |
| Which 6 are unlocked | First 6 by `createdAt` | Predictable, fair (keep what you made first) |
| Locked recipe visibility | Show with lock icon overlay | Less hostile than blur, consistent with meal plan display |
| Import behavior | Import ALL, lock extras | No re-import needed after upgrade, increases FOMO/conversion |
| Gating location | Inside `RecipePage` | Async-safe, reactive, handles deep links properly |
| Meal plan locked recipes | No lock icon (row too small) | Just show paywall on tap |
| Counting scope | User's own recipes only | `recipe.userId == currentUser.id` |
| Deleted recipes | Don't count | Soft delete exclusion, users can delete to free slots |
| Household recipes | Don't count against limit | Only YOUR recipes count, household member recipes accessible |

### Why Gate in RecipePage Instead of GoRouter?

GoRouter's `redirect` callback is synchronous, but our recipe data is loaded asynchronously via `recipeNotifierProvider` (returns `AsyncValue`). This creates race conditions:
- If recipes haven't loaded yet, redirect can't determine lock status
- User could see recipe content briefly before redirect fires

By gating inside `RecipePage`:
- Provider handles async naturally with `ref.watch`
- User sees: Loading spinner → Paywall (never sees recipe content)
- Reactive: if subscription changes mid-view, UI updates
- Works correctly for deep links even when app is cold-starting

---

## Data Model

### New Providers (in `recipe_provider.dart`)

```dart
/// Count of user's own non-deleted recipes
final userRecipeCountProvider = Provider<int>((ref) {
  final recipes = ref.watch(recipeNotifierProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id;
  if (currentUserId == null) return 0;

  return recipes.where((r) => r.userId == currentUserId).length;
});

/// Set of recipe IDs that are unlocked (first 6 by createdAt)
final unlockedRecipeIdsProvider = Provider<Set<String>>((ref) {
  final recipes = ref.watch(recipeNotifierProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id;
  final hasPlus = ref.watch(effectiveHasPlusProvider);

  // Plus users: all unlocked
  if (hasPlus) {
    return recipes.map((r) => r.id).toSet();
  }

  // Free users: first 6 of their own recipes by createdAt
  final userRecipes = recipes
      .where((r) => r.userId == currentUserId)
      .toList()
    ..sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));

  return userRecipes.take(6).map((r) => r.id).toSet();
});

/// Check if a specific recipe is locked
final isRecipeLockedProvider = Provider.family<bool, String>((ref, recipeId) {
  final unlockedIds = ref.watch(unlockedRecipeIdsProvider);
  return !unlockedIds.contains(recipeId);
});

/// Count of locked recipes (for paywall messaging)
final lockedRecipeCountProvider = Provider<int>((ref) {
  final totalCount = ref.watch(userRecipeCountProvider);
  final unlockedIds = ref.watch(unlockedRecipeIdsProvider);
  final hasPlus = ref.watch(effectiveHasPlusProvider);

  if (hasPlus) return 0;
  return (totalCount - unlockedIds.length).clamp(0, totalCount);
});

/// Remaining recipe slots for free users
final remainingRecipeSlotsProvider = Provider<int>((ref) {
  final hasPlus = ref.watch(effectiveHasPlusProvider);
  if (hasPlus) return -1; // -1 = unlimited

  final count = ref.watch(userRecipeCountProvider);
  return (6 - count).clamp(0, 6);
});
```

---

## Implementation Tasks

### 1. Add Recipe Limit Providers

**File:** `lib/src/providers/recipe_provider.dart`

Add the providers defined above. These form the foundation for all gating logic.

---

### 2. Gate Inside RecipePage

**File:** `lib/src/features/recipes/views/recipe_page.dart`

Add lock check inside the `recipeAsync.when(data:)` callback, **before** building recipe content:

```dart
data: (recipe) {
  if (recipe == null) {
    return const Center(child: Text('Recipe not found'));
  }

  // Check if this recipe is locked BEFORE building content
  final isLocked = ref.watch(isRecipeLockedProvider(recipe.id));
  if (isLocked) {
    return LockedRecipePage(
      recipe: recipe,
      onUpgrade: () async {
        final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
        // If purchased, isLocked will reactively become false and content will show
      },
    );
  }

  // ... existing recipe content building code
}
```

**Create new widget:** `lib/src/features/recipes/views/locked_recipe_page.dart`

```dart
/// Shown when user taps a recipe they don't have access to.
/// Displays recipe image/title as teaser with upgrade prompt.
class LockedRecipePage extends ConsumerWidget {
  final RecipeEntry recipe;
  final VoidCallback? onUpgrade;

  const LockedRecipePage({
    super.key,
    required this.recipe,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final lockedCount = ref.watch(lockedRecipeCountProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button header
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AppCircleButton(
                    icon: AppCircleButtonIcon.close,
                    variant: AppCircleButtonVariant.neutral,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recipe image teaser (if available)
                      if (recipe.images?.isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 150,
                            width: 150,
                            child: RecipeImageWidget(image: recipe.images!.first),
                          ),
                        ),

                      SizedBox(height: AppSpacing.lg),

                      // Recipe title
                      Text(
                        recipe.title,
                        style: AppTypography.h4.copyWith(color: colors.textPrimary),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: AppSpacing.xl),

                      // Lock icon
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 48,
                        color: colors.textSecondary,
                      ),

                      SizedBox(height: AppSpacing.lg),

                      // Message
                      Text(
                        lockedCount > 1
                          ? 'This recipe and ${lockedCount - 1} others require Stockpot Plus'
                          : 'This recipe requires Stockpot Plus',
                        style: AppTypography.body.copyWith(color: colors.textSecondary),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: AppSpacing.xl),

                      // Upgrade button
                      AppButton(
                        text: 'Upgrade to Plus',
                        variant: AppButtonVariants.primaryFilled,
                        size: AppButtonSize.large,
                        onPressed: onUpgrade,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

This approach:
- Shows recipe title/image as a teaser (not hidden)
- Displays how many recipes are locked total
- Upgrade button presents paywall
- If user upgrades, `isRecipeLockedProvider` reactively updates and shows recipe content

---

### 3. Recipe Tile Lock Indicator

**File:** `lib/src/features/recipes/widgets/recipe_tile.dart`

Add lock icon overlay for locked recipes:

```dart
// In build method
final isLocked = ref.watch(isRecipeLockedProvider(recipe.id));

return Stack(
  children: [
    // Existing tile content
    _buildTileContent(),

    // Lock overlay for locked recipes
    if (isLocked)
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.background.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            CupertinoIcons.lock_fill,
            size: 16,
            color: colors.textSecondary,
          ),
        ),
      ),
  ],
);
```

Optional: Reduce opacity of locked recipe tiles slightly (0.7-0.8) to visually indicate restriction.

---

### 4. Gate Recipe Creation

**File:** `lib/src/features/recipes/views/add_recipe_modal.dart`

Check limit before opening editor:

```dart
Future<void> showRecipeEditorModal(BuildContext context, WidgetRef ref, {Recipe? recipe}) async {
  // Only check limit for NEW recipes (not editing existing)
  if (recipe == null) {
    final remainingSlots = ref.read(remainingRecipeSlotsProvider);

    if (remainingSlots == 0) {
      // Show paywall instead of editor
      await ref.read(subscriptionProvider.notifier).presentPaywall(context);
      return;
    }
  }

  // Proceed with editor...
}
```

---

### 5. Gate Import with Messaging

**File:** `lib/src/features/import_export/views/import_preview_page.dart`

After import completes, show appropriate message:

```dart
// After executeImport() completes
final importedCount = result.successCount;
final hasPlus = ref.read(effectiveHasPlusProvider);
final remainingSlots = ref.read(remainingRecipeSlotsProvider);

if (!hasPlus && importedCount > 6) {
  final accessibleCount = 6; // or remainingSlots if they had some already
  final lockedCount = importedCount - accessibleCount;

  // Show success dialog with upgrade prompt
  showImportCompleteDialog(
    context,
    message: "Successfully imported all $importedCount recipes! "
             "$accessibleCount are ready to use. "
             "Upgrade to Stockpot Plus to access all of them.",
    showUpgradeButton: true,
  );
} else {
  // Normal success message
  showImportCompleteDialog(
    context,
    message: "Successfully imported $importedCount recipes!",
  );
}
```

---

### 6. Meal Plan Locked Recipe Handling

**File:** `lib/src/features/meal_plans/widgets/meal_plan_recipe_row.dart` (or similar)

No lock icon needed (rows too small). The gating happens inside `RecipePage`, so no changes needed to meal plan navigation. When user taps a locked recipe from a meal plan, they'll see the `LockedRecipePage` with upgrade prompt.

---

### 7. Shopping List from Locked Recipes

**No changes needed.** Shopping list pulls ingredients from recipes regardless of lock status. The recipe data is still in the database, just UI access is gated.

---

### 8. Feature Flag Registration

**File:** `lib/src/utils/feature_flags.dart`

The `'unlimited_recipes'` feature already exists. Ensure it's properly wired:

```dart
case 'unlimited_recipes':
  return subscription.hasPlus;
```

---

## Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| Subscribe → add 20 recipes → cancel | First 6 (by createdAt) accessible, 14 locked |
| Import 50 recipes while free | All imported, first 6 accessible, 44 locked |
| Delete recipe #3 | Recipe #7 becomes accessible (slot freed) |
| Join household with Plus member | All recipes accessible (shared entitlement) |
| Household member's recipes | Always accessible (don't count against YOUR limit) |
| Deep link to locked recipe | RecipePage shows LockedRecipePage with upgrade prompt |
| Offline access | Lock status computed locally, works offline |

---

## Testing Checklist

- [ ] Free user can create up to 6 recipes
- [ ] 7th recipe creation shows paywall
- [ ] Recipe tile shows lock icon for recipes 7+
- [ ] Tapping locked recipe shows LockedRecipePage (not recipe detail)
- [ ] Import imports all recipes, shows appropriate message
- [ ] Deleting a recipe frees up a slot
- [ ] Plus user has no limits
- [ ] Cancelling Plus locks recipes 7+
- [ ] Household subscription sharing works correctly
- [ ] Meal plan with locked recipe shows paywall on tap
- [ ] Shopping list includes ingredients from locked recipes
- [ ] Deep link to locked recipe shows LockedRecipePage
- [ ] Upgrading from LockedRecipePage reactively shows recipe content

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/src/providers/recipe_provider.dart` | Add limit providers |
| `lib/src/features/recipes/views/recipe_page.dart` | Add lock check, show LockedRecipePage |
| `lib/src/features/recipes/views/locked_recipe_page.dart` | **NEW** - Locked recipe UI |
| `lib/src/features/recipes/widgets/recipe_tile.dart` | Add lock icon overlay |
| `lib/src/features/recipes/views/add_recipe_modal.dart` | Gate creation |
| `lib/src/features/import_export/views/import_preview_page.dart` | Import messaging |

---

## Open Items / Future Considerations

1. **Analytics:** Track locked recipe taps for conversion funnel analysis
2. **Upgrade prompt banner:** Consider showing "X recipes locked" banner in recipe list for free users
3. **Edit locked recipe:** Should users be able to edit locked recipes? (Current plan: no, they can't access at all)
