# Proposal: Recipe Creation Menu Bottom Sheet

**Date:** 2025-01-01
**Status:** Draft
**Author:** Claude Code

---

## Overview

Replace the "Create a Recipe" button action in the welcome card with a new multi-page Wolt bottom sheet that presents all recipe creation options in a visually appealing grouped list format.

---

## User Flow

```
┌─────────────────────────────────────────┐
│         Welcome Card                     │
│   [Create a Recipe] button tapped        │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│      Page 1: Creation Options            │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │ Create Manually              ▸      │ │
│  ├─────────────────────────────────────┤ │
│  │ Import from URL              ▸      │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │ Generate with AI       PLUS  ▸      │ │
│  ├─────────────────────────────────────┤ │
│  │ Import from Social     PLUS  ▸      │ │
│  ├─────────────────────────────────────┤ │
│  │ Import from Camera     PLUS  ▸      │ │
│  ├─────────────────────────────────────┤ │
│  │ Import from Photos     PLUS  ▸      │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │ Discover Recipes             ▸      │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    │
          (if "Import from Social" tapped)
                    │
                    ▼
┌─────────────────────────────────────────┐
│      Page 2: Social Import Guide         │
│                                          │
│  ← Back                                  │
│                                          │
│  How to import from social media:        │
│                                          │
│  1. Open Instagram, TikTok, or YouTube   │
│  2. Find a recipe video you like         │
│  3. Tap the Share button                 │
│  4. Select "Stockpot" from the list      │
│                                          │
│  [Got it]                                │
└─────────────────────────────────────────┘
```

---

## Visual Design

### Grouped List Styling

Following the pattern from `ai_recipe_generator_modal.dart` (brainstormed ideas):

```dart
// Use GroupedListStyling for connected card appearance
final borderRadius = GroupedListStyling.getBorderRadius(
  isGrouped: true,
  isFirstInGroup: isFirst,
  isLastInGroup: isLast,
);

final border = GroupedListStyling.getBorder(
  context: context,
  isGrouped: true,
  isFirstInGroup: isFirst,
  isLastInGroup: isLast,
  isDragging: false,
);

Container(
  padding: EdgeInsets.all(AppSpacing.lg),  // 16px
  decoration: BoxDecoration(
    color: colors.groupedListBackground,
    border: border,
    borderRadius: borderRadius,
  ),
  child: Row(
    children: [
      Icon(iconData, size: 22, color: colors.textPrimary),
      SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h5),
            if (subtitle != null)
              Text(subtitle, style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              )),
          ],
        ),
      ),
      if (showPlusBadge) const PlusPill(),
      SizedBox(width: AppSpacing.md),
      Icon(CupertinoIcons.chevron_right, size: 18, color: colors.textSecondary),
    ],
  ),
)
```

### Plus Pill Widget

Reuse the existing pattern from `share_recipe_preview_result.dart`:

```dart
class PlusPill extends StatelessWidget {
  const PlusPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColorSwatches.primary[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'PLUS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColorSwatches.primary[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
```

### Option Groups

Organize options into logical groups with spacing between:

| Group | Options | Plus Badge |
|-------|---------|------------|
| **Basic** | Create Manually, Import from URL | No |
| **AI-Powered** | Generate with AI, Import from Social, Import from Camera, Import from Photos | Yes |
| **Discover** | Discover Recipes | No |

---

## Technical Implementation

> **Reference:** See `analysis/wolt_modal_multi_page_guide.md` for multi-page Wolt modal patterns to avoid visual glitches.

### Key Patterns from Guide
1. **Use `hasTopBarLayer: false`** on all pages to prevent duplicate drag handles
2. **Use `SliverWoltModalSheetPage`** for scrollable content, `WoltModalSheetPage` for simple content
3. **Return Slivers directly** in `mainContentSliversBuilder` - NOT wrapped in `SliverToBoxAdapter`
4. **No async data** in this modal, so no FutureProvider concerns

### File Structure

```
lib/src/features/recipes/views/
├── recipe_creation_menu_modal.dart    # NEW: Main modal + page definitions
└── add_recipe_modal.dart              # Existing: Manual recipe editor
```

### Modal Entry Point

```dart
/// Show the recipe creation menu modal
Future<void> showRecipeCreationMenuModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
}) async {
  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    useSafeArea: false,
    pageListBuilder: (bottomSheetContext) => [
      _CreationOptionsPage.build(bottomSheetContext, ref, folderId),
      _SocialImportGuidePage.build(bottomSheetContext),
    ],
  );
}
```

### Page 1: Creation Options

Per `analysis/wolt_modal_multi_page_guide.md`, we use `SliverWoltModalSheetPage` for scrollable content and ensure content returns Slivers directly (not wrapped in `SliverToBoxAdapter`).

```dart
class _CreationOptionsPage {
  static SliverWoltModalSheetPage build(
    BuildContext context,
    WidgetRef ref,
    String? folderId,
  ) {
    return SliverWoltModalSheetPage(
      hasTopBarLayer: false,  // Required: prevents duplicate drag handle
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Content must return Slivers directly, NOT wrapped in SliverToBoxAdapter
      mainContentSliversBuilder: (context) => [
        _CreationOptionsContent(ref: ref, folderId: folderId),
      ],
    );
  }
}

// Content widget returns a Sliver directly
class _CreationOptionsContent extends StatelessWidget {
  final WidgetRef ref;
  final String? folderId;

  const _CreationOptionsContent({required this.ref, this.folderId});

  @override
  Widget build(BuildContext context) {
    final optionGroups = _buildOptionGroups(context, ref, folderId);

    // Build list of widgets for all groups
    final List<Widget> children = [];
    for (int groupIndex = 0; groupIndex < optionGroups.length; groupIndex++) {
      // Add group spacing between groups
      if (groupIndex > 0) {
        children.add(SizedBox(height: AppSpacing.lg));
      }
      // Add options in this group
      final group = optionGroups[groupIndex];
      for (int i = 0; i < group.length; i++) {
        children.add(_OptionRow(
          option: group[i],
          isFirst: i == 0,
          isLast: i == group.length - 1,
        ));
      }
    }
    // Add bottom padding
    children.add(SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg));

    // Return a Sliver directly (NOT wrapped in SliverToBoxAdapter)
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ]),
    );
  }
}
```

### Option Data Model

```dart
class CreationOption {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool requiresPlus;
  final VoidCallback onTap;

  const CreationOption({
    required this.title,
    this.subtitle,
    required this.icon,
    this.requiresPlus = false,
    required this.onTap,
  });
}
```

### Options Definition

```dart
List<List<CreationOption>> _buildOptionGroups(
  BuildContext context,
  WidgetRef ref,
  String? folderId,
) {
  return [
    // Group 1: Basic
    [
      CreationOption(
        title: 'Create Manually',
        subtitle: 'Start from scratch',
        icon: CupertinoIcons.pencil,
        onTap: () {
          Navigator.of(context).pop();
          showRecipeEditorModal(context, ref: ref, folderId: folderId);
        },
      ),
      CreationOption(
        title: 'Import from URL',
        subtitle: 'Paste a recipe link',
        icon: CupertinoIcons.link,
        onTap: () {
          Navigator.of(context).pop();
          showUrlImportModal(context, ref: ref, folderId: folderId);
        },
      ),
    ],
    // Group 2: AI-Powered (Plus features)
    [
      CreationOption(
        title: 'Generate with AI',
        subtitle: 'Describe what you want',
        icon: CupertinoIcons.wand_stars,
        requiresPlus: true,
        onTap: () {
          Navigator.of(context).pop();
          showAiRecipeGeneratorModal(context, ref: ref, folderId: folderId);
        },
      ),
      CreationOption(
        title: 'Import from Social',
        subtitle: 'Instagram, TikTok, YouTube',
        icon: CupertinoIcons.share,
        requiresPlus: true,
        onTap: () {
          // Push to page 2 instead of closing
          WoltModalSheet.of(context).showNext();
        },
      ),
      CreationOption(
        title: 'Import from Camera',
        subtitle: 'Photograph a recipe',
        icon: CupertinoIcons.camera,
        requiresPlus: true,
        onTap: () {
          Navigator.of(context).pop();
          showPhotoCaptureReviewModal(context, ref: ref, folderId: folderId);
        },
      ),
      CreationOption(
        title: 'Import from Photos',
        subtitle: 'Select from your library',
        icon: CupertinoIcons.photo,
        requiresPlus: true,
        onTap: () {
          Navigator.of(context).pop();
          showPhotoImportModal(
            context,
            ref: ref,
            source: ImageSource.gallery,
            folderId: folderId,
          );
        },
      ),
    ],
    // Group 3: Discover
    [
      CreationOption(
        title: 'Discover Recipes',
        subtitle: 'Browse and import from the web',
        icon: CupertinoIcons.globe,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/discover');
        },
      ),
    ],
  ];
}
```

### Page 2: Social Import Guide

Page 2 is simple non-scrolling content, so `WoltModalSheetPage` with `child` is appropriate.

```dart
class _SocialImportGuidePage {
  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      hasTopBarLayer: false,  // Required: prevents duplicate drag handle
      leadingNavBarWidget: Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.back,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () {
            WoltModalSheet.of(context).showPrevious();
          },
        ),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: const _SocialImportGuideContent(),
    );
  }
}
```

### Social Guide Content

```dart
class _SocialImportGuideContent extends StatelessWidget {
  const _SocialImportGuideContent();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Import from Social Media',
            style: AppTypography.h3.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'To import a recipe from Instagram, TikTok, or YouTube:',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.lg),
          _StepItem(number: 1, text: 'Open the app and find a recipe video'),
          _StepItem(number: 2, text: 'Tap the Share button'),
          _StepItem(number: 3, text: 'Select "Stockpot" from the share menu'),
          _StepItem(number: 4, text: 'We\'ll extract the recipe automatically'),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Got it',
            onPressed: () => WoltModalSheet.of(context).showPrevious(),
            theme: AppButtonTheme.dark,
            style: AppButtonStyle.fill,
            size: AppButtonSize.large,
            shape: AppButtonShape.round,
            fullWidth: true,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.caption.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Integration Points

### 1. Welcome Card Update

Update `welcome_recipe_card.dart` to call the new modal:

```dart
// Before
showRecipeEditorModal(context, ref: ref, folderId: null);

// After
showRecipeCreationMenuModal(context, ref: ref, folderId: null);
```

### 2. Required Imports

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import 'add_recipe_modal.dart';
import 'ai_recipe_generator_modal.dart';
import 'photo_capture_review_modal.dart';
import 'photo_import_modal.dart';
import 'url_import_modal.dart';
```

---

## Edge Cases

### 1. Plus Subscription Check

The Plus badge is informational only on this menu. The actual subscription check happens when the user taps an option and the respective modal opens (existing behavior in each modal).

### 2. Folder ID Propagation

Pass `folderId` through to all creation flows so recipes are added to the correct folder context.

### 3. Modal Dismissal

- Close button: `Navigator.of(context).pop()` - closes entire modal
- Option tap (except Social): Close modal, then open target modal
- Social option: Push to page 2 within same modal
- Back on page 2: `WoltModalSheet.of(context).showPrevious()`
- "Got it" on page 2: `WoltModalSheet.of(context).showPrevious()` - returns to page 1

### 4. Safe Area Handling

Include `MediaQuery.of(context).padding.bottom` at bottom of content for devices with home indicators.

---

## Testing Checklist

- [ ] All options display correctly with proper grouping
- [ ] Plus badges appear on correct options
- [ ] Chevrons visible on all options
- [ ] Tapping each option launches correct flow
- [ ] Social option navigates to page 2
- [ ] Back button on page 2 returns to page 1
- [ ] Close button dismisses modal from both pages
- [ ] Dark mode styling correct
- [ ] iPad layout looks good (modal width)
- [ ] Folder ID passed correctly to all flows

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/src/features/recipes/views/recipe_creation_menu_modal.dart` | CREATE |
| `lib/src/features/recipes/widgets/welcome_recipe_card.dart` | MODIFY - update button action |
| `lib/src/widgets/plus_pill.dart` | CREATE (optional - extract reusable widget) |

---

## Decision

**Ready for implementation.** This plan covers:
1. Visual design matching existing patterns
2. Multi-page Wolt modal structure
3. All recipe creation entry points
4. Social media guide page
5. Integration with welcome card

