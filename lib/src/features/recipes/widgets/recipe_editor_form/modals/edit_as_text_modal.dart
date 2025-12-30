import 'dart:math' show max;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../../../database/models/ingredients.dart';
import '../../../../../../database/models/steps.dart';
import '../../../../../repositories/recipe_repository.dart';
import '../../../../../theme/colors.dart';
import '../../../../../theme/spacing.dart';
import '../../../../../theme/typography.dart';
import '../utils/text_serialization.dart';

/// Shows a modal for editing ingredients as text.
/// Returns the updated ingredients list, or null if cancelled.
Future<List<Ingredient>?> showEditIngredientsAsTextModal(
  BuildContext context, {
  required List<Ingredient> ingredients,
  required WidgetRef ref,
}) async {
  return WoltModalSheet.show<List<Ingredient>>(
    context: context,
    useRootNavigator: true,
    pageListBuilder: (bottomSheetContext) => [
      _EditIngredientsAsTextPage.build(
        context: bottomSheetContext,
        ingredients: ingredients,
        ref: ref,
      ),
    ],
  );
}

/// Shows a modal for editing steps as text.
/// Returns the updated steps list, or null if cancelled.
Future<List<Step>?> showEditStepsAsTextModal(
  BuildContext context, {
  required List<Step> steps,
}) async {
  return WoltModalSheet.show<List<Step>>(
    context: context,
    useRootNavigator: true,
    pageListBuilder: (bottomSheetContext) => [
      _EditStepsAsTextPage.build(
        context: bottomSheetContext,
        steps: steps,
      ),
    ],
  );
}

// =============================================================================
// Shared Components
// =============================================================================

/// Calculates the height available for the text field based on screen size.
double _calculateTextFieldHeight(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final screenHeight = mediaQuery.size.height;
  final topPadding = mediaQuery.padding.top;
  final bottomPadding = mediaQuery.padding.bottom;
  final keyboardHeight = mediaQuery.viewInsets.bottom;

  // Modal layout constants
  const modalTopMargin = 44.0; // Space above modal
  const dragHandleArea = 16.0; // Drag handle + padding
  const navBarHeight = 55.0;
  const headerHeight = 85.0; // Title + helper text + spacing
  const contentPadding = 32.0; // Top and bottom padding (AppSpacing.lg * 2)

  final available = screenHeight -
      topPadding -
      modalTopMargin -
      dragHandleArea -
      navBarHeight -
      headerHeight -
      contentPadding -
      bottomPadding -
      keyboardHeight;

  // Ensure minimum usable height
  return max(150.0, available);
}

/// Creates a text field with calculated height that fills available space.
/// Uses gradient overlays at top/bottom for smoother visual fade when scrolling.
Widget _buildTextField({
  required BuildContext context,
  required TextEditingController controller,
  required String placeholder,
  required double height,
}) {
  final colors = AppColors.of(context);
  const fadeHeight = 14.0;
  const horizontalPadding = 16.0;
  const verticalPadding = 14.0;

  return SizedBox(
    height: height,
    child: Container(
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // TextField with padding
            Positioned.fill(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.fieldInput.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: AppTypography.fieldLabel.copyWith(
                    color: colors.inputPlaceholder,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            // Top fade overlay - draws over clipped text
            Positioned(
              top: verticalPadding,
              left: horizontalPadding,
              right: horizontalPadding,
              height: fadeHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.input,
                        colors.input.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom fade overlay - draws over clipped text
            Positioned(
              bottom: verticalPadding,
              left: horizontalPadding,
              right: horizontalPadding,
              height: fadeHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        colors.input,
                        colors.input.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// Ingredients Edit as Text Page
// =============================================================================

class _EditIngredientsAsTextPage {
  _EditIngredientsAsTextPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<Ingredient> ingredients,
    required WidgetRef ref,
  }) {
    final textController = TextEditingController();
    final isLoadingNotifier = ValueNotifier<bool>(true);
    final isUpdatingNotifier = ValueNotifier<bool>(false);

    // Initialize text asynchronously
    () async {
      final repository = ref.read(recipeRepositoryProvider);
      final text = await ingredientsToText(ingredients, repository);
      textController.text = text;
      isLoadingNotifier.value = false;
    }();

    Future<void> onUpdate() async {
      if (isUpdatingNotifier.value) return;
      isUpdatingNotifier.value = true;

      final navigator = Navigator.of(context);
      final repository = ref.read(recipeRepositoryProvider);
      final result = await textToIngredients(textController.text, repository);
      navigator.pop(result);
    }

    final colors = AppColors.of(context);

    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: colors.primary,
            fontSize: 17,
          ),
        ),
      ),
      trailingNavBarWidget: ValueListenableBuilder<bool>(
        valueListenable: isUpdatingNotifier,
        builder: (context, isUpdating, _) {
          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isUpdating ? null : onUpdate,
              child: isUpdating
                  ? const CupertinoActivityIndicator()
                  : Text(
                      'Update',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: isLoadingNotifier,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }

          final textFieldHeight = _calculateTextFieldHeight(context);

          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Ingredients',
                  style: AppTypography.h4.copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'One ingredient per line. Use # for sections. Link recipes with [recipe:Name].',
                  style: AppTypography.body.copyWith(color: colors.textSecondary),
                ),
                SizedBox(height: AppSpacing.lg),
                _buildTextField(
                  context: context,
                  controller: textController,
                  placeholder:
                      '# Section\n1 cup flour\n2 cups Chicken Stock [recipe:Chicken Stock]\n...',
                  height: textFieldHeight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Steps Edit as Text Page
// =============================================================================

class _EditStepsAsTextPage {
  _EditStepsAsTextPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<Step> steps,
  }) {
    final textController = TextEditingController(text: stepsToText(steps));

    void onUpdate() {
      final result = textToSteps(textController.text);
      Navigator.of(context).pop(result);
    }

    final colors = AppColors.of(context);

    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: colors.primary,
            fontSize: 17,
          ),
        ),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.md),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onUpdate,
          child: Text(
            'Update',
            style: TextStyle(
              color: colors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          final textFieldHeight = _calculateTextFieldHeight(context);

          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Steps',
                  style: AppTypography.h4.copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Separate steps with blank lines. Use # for sections.',
                  style: AppTypography.body.copyWith(color: colors.textSecondary),
                ),
                SizedBox(height: AppSpacing.lg),
                _buildTextField(
                  context: context,
                  controller: textController,
                  placeholder:
                      '# Preparation\n\nPreheat oven to 350°F.\n\nMix dry ingredients\nuntil combined.\n\n...',
                  height: textFieldHeight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
