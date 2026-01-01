import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, Brightness;
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
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

/// Show the recipe creation menu modal with all creation options.
Future<void> showRecipeCreationMenuModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
}) async {
  // Store the root context for use after modal is closed
  final rootContext = context;

  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    useSafeArea: false,
    pageListBuilder: (bottomSheetContext) => [
      _CreationOptionsPage.build(bottomSheetContext, rootContext, ref, folderId),
      _SocialImportGuidePage.build(bottomSheetContext),
    ],
  );
}

// =============================================================================
// Page 1: Creation Options
// =============================================================================

class _CreationOptionsPage {
  static SliverWoltModalSheetPage build(
    BuildContext modalContext,
    BuildContext rootContext,
    WidgetRef ref,
    String? folderId,
  ) {
    return SliverWoltModalSheetPage(
      hasTopBarLayer: false, // Required: prevents duplicate drag handle
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(modalContext).pop(),
        ),
      ),
      // Content must return Slivers directly, NOT wrapped in SliverToBoxAdapter
      mainContentSliversBuilder: (context) => [
        _CreationOptionsContent(
          modalContext: modalContext,
          rootContext: rootContext,
          ref: ref,
          folderId: folderId,
        ),
      ],
    );
  }
}

/// Content widget that returns a Sliver directly
class _CreationOptionsContent extends StatelessWidget {
  final BuildContext modalContext;
  final BuildContext rootContext;
  final WidgetRef ref;
  final String? folderId;

  const _CreationOptionsContent({
    required this.modalContext,
    required this.rootContext,
    required this.ref,
    this.folderId,
  });

  @override
  Widget build(BuildContext context) {
    final optionGroups = _buildOptionGroups();
    final colors = AppColors.of(context);

    // Build list of widgets for all groups
    final List<Widget> children = [];

    // Header
    children.add(
      Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Text(
          'Create a Recipe',
          style: AppTypography.h3.copyWith(color: colors.textPrimary),
        ),
      ),
    );

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
    children.add(
        SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.lg));

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

  List<List<_CreationOption>> _buildOptionGroups() {
    return [
      // Group 1: Basic
      [
        _CreationOption(
          title: 'Create Manually',
          subtitle: 'Start from scratch',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, size: 22),
          onTap: () {
            Navigator.of(modalContext).pop();
            showRecipeEditorModal(rootContext, ref: ref, folderId: folderId);
          },
        ),
        _CreationOption(
          title: 'Import from URL',
          subtitle: 'Paste a recipe link',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 22),
          onTap: () {
            Navigator.of(modalContext).pop();
            showUrlImportModal(rootContext, ref: ref, folderId: folderId);
          },
        ),
      ],
      // Group 2: AI-Powered (Plus features)
      [
        _CreationOption(
          title: 'Generate with AI',
          subtitle: 'Describe what you want',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01, size: 22),
          requiresPlus: true,
          onTap: () {
            Navigator.of(modalContext).pop();
            showAiRecipeGeneratorModal(rootContext, ref: ref, folderId: folderId);
          },
        ),
        _CreationOption(
          title: 'Import from Social',
          subtitle: 'Instagram, TikTok, YouTube',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 22),
          requiresPlus: true,
          onTap: () {
            // Push to page 2 instead of closing
            WoltModalSheet.of(modalContext).showNext();
          },
        ),
        _CreationOption(
          title: 'Import from Camera',
          subtitle: 'Photograph a recipe',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 22),
          requiresPlus: true,
          onTap: () {
            Navigator.of(modalContext).pop();
            showPhotoCaptureReviewModal(rootContext, ref: ref, folderId: folderId);
          },
        ),
        _CreationOption(
          title: 'Import from Photos',
          subtitle: 'Select from your library',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 22),
          requiresPlus: true,
          onTap: () {
            Navigator.of(modalContext).pop();
            showPhotoImportModal(
              rootContext,
              ref: ref,
              source: ImageSource.gallery,
              folderId: folderId,
            );
          },
        ),
      ],
      // Group 3: Discover
      [
        _CreationOption(
          title: 'Discover Recipes',
          subtitle: 'Browse and import from the web',
          icon: HugeIcon(icon: HugeIcons.strokeRoundedGlobal, size: 22),
          onTap: () {
            Navigator.of(modalContext).pop();
            rootContext.push('/discover');
          },
        ),
      ],
    ];
  }
}

// =============================================================================
// Option Data Model
// =============================================================================

class _CreationOption {
  final String title;
  final String? subtitle;
  final Widget icon;
  final bool requiresPlus;
  final VoidCallback onTap;

  const _CreationOption({
    required this.title,
    this.subtitle,
    required this.icon,
    this.requiresPlus = false,
    required this.onTap,
  });
}

// =============================================================================
// Option Row Widget (Grouped List Style)
// =============================================================================

class _OptionRow extends StatelessWidget {
  final _CreationOption option;
  final bool isFirst;
  final bool isLast;

  const _OptionRow({
    required this.option,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        option.onTap();
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: border,
          borderRadius: borderRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon on left
            IconTheme(
              data: IconThemeData(size: 22, color: colors.textPrimary),
              child: option.icon,
            ),
            SizedBox(width: AppSpacing.md),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTypography.h5.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      option.subtitle!,
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Plus badge if required
            if (option.requiresPlus) ...[
              SizedBox(width: AppSpacing.sm),
              const _PlusPill(),
            ],
            // Chevron on right
            SizedBox(width: AppSpacing.md),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Plus Pill Widget
// =============================================================================

/// Small pill badge indicating Plus feature
class _PlusPill extends StatelessWidget {
  const _PlusPill();

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

// =============================================================================
// Page 2: Social Import Guide
// =============================================================================

class _SocialImportGuidePage {
  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      hasTopBarLayer: false, // Required: prevents duplicate drag handle
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
          _StepItem(number: 4, text: "We'll extract the recipe automatically"),
          SizedBox(height: AppSpacing.xl),
          AppButtonVariants.primaryFilled(
            text: 'Got it',
            onPressed: () => WoltModalSheet.of(context).showPrevious(),
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle - matches recipe_steps_view.dart styling
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isLight
                  ? AppColorSwatches.surface[200] // Light sand in light mode
                  : AppColorSwatches.neutral[800]!, // Dark gray in dark mode
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTypography.caption.copyWith(
                color: isLight
                    ? AppColorSwatches.surface[800] // Dark taupe in light mode
                    : AppColorSwatches.neutral[300]!, // Light gray in dark mode
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4), // Align text with circle center
              child: Text(
                text,
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
