import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/scale_convert_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../../widgets/app_text_field.dart' show AppTextFieldVariant;
import '../../../../widgets/app_text_field_group.dart';
import '../../models/scale_convert_state.dart';

/// Panel for scaling and converting recipe ingredients.
///
/// Provides controls for:
/// - Scale type (Amount, Servings, Ingredient)
/// - Scale factor via slider
/// - Ingredient selection for ingredient-based scaling
/// - Unit conversion mode (Original, Imperial, Metric)
class ScaleConvertPanel extends ConsumerWidget {
  final String recipeId;
  final int? recipeServings; // null if recipe doesn't have servings defined

  const ScaleConvertPanel({
    super.key,
    required this.recipeId,
    this.recipeServings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scaleConvertProvider(recipeId));
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scale Group
        AppTextFieldGroup(
          variant: AppTextFieldVariant.filled,
          children: [
            // Scale Type Row
            _ScaleTypeRow(
              recipeId: recipeId,
              state: state,
              hasServings: recipeServings != null,
            ),

            // Ingredient Selector Row (animated, only shown for ingredient mode)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: state.scaleType == ScaleType.ingredient
                  ? _IngredientSelectorRow(recipeId: recipeId, state: state)
                  : const SizedBox.shrink(),
            ),

            // Scale Slider Row
            _ScaleSliderRow(
              recipeId: recipeId,
              state: state,
              recipeServings: recipeServings,
            ),
          ],
        ),

        SizedBox(height: AppSpacing.xl),

        // Convert Group
        AppTextFieldGroup(
          variant: AppTextFieldVariant.filled,
          children: [
            _ConvertRow(recipeId: recipeId, state: state),
          ],
        ),

        SizedBox(height: AppSpacing.sm),

        // Reset Button
        Center(
          child: TextButton(
            onPressed: state.isTransformActive
                ? () {
                    HapticFeedback.lightImpact();
                    ref.read(scaleConvertProvider(recipeId).notifier).reset();
                  }
                : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
            ),
            child: Text(
              'Reset',
              style: AppTypography.body.copyWith(
                color: state.isTransformActive
                    ? colors.primary
                    : colors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SCALE TYPE ROW
// ============================================================

class _ScaleTypeRow extends ConsumerWidget {
  final String recipeId;
  final ScaleConvertState state;
  final bool hasServings;

  const _ScaleTypeRow({
    required this.recipeId,
    required this.state,
    required this.hasServings,
  });

  String _getScaleTypeLabel(ScaleType type) {
    switch (type) {
      case ScaleType.amount:
        return 'Amount';
      case ScaleType.servings:
        return 'Servings';
      case ScaleType.ingredient:
        return 'Ingredient';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Scale',
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
            ),
          ),
          AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Amount',
                icon: Icon(
                  CupertinoIcons.number,
                  color: state.scaleType == ScaleType.amount
                      ? colors.primary
                      : colors.textPrimary,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(scaleConvertProvider(recipeId).notifier)
                      .setScaleType(ScaleType.amount);
                },
              ),
              if (hasServings)
                AdaptiveMenuItem(
                  title: 'Servings',
                  icon: Icon(
                    CupertinoIcons.person_2,
                    color: state.scaleType == ScaleType.servings
                        ? colors.primary
                        : colors.textPrimary,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(scaleConvertProvider(recipeId).notifier)
                        .setScaleType(ScaleType.servings);
                  },
                ),
              AdaptiveMenuItem(
                title: 'Ingredient',
                icon: Icon(
                  CupertinoIcons.list_bullet,
                  color: state.scaleType == ScaleType.ingredient
                      ? colors.primary
                      : colors.textPrimary,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(scaleConvertProvider(recipeId).notifier)
                      .setScaleType(ScaleType.ingredient);
                },
              ),
            ],
            child: _DropdownButtonChip(
              text: _getScaleTypeLabel(state.scaleType),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INGREDIENT SELECTOR ROW
// ============================================================

class _IngredientSelectorRow extends ConsumerWidget {
  final String recipeId;
  final ScaleConvertState state;

  const _IngredientSelectorRow({
    required this.recipeId,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final scalableIngredients = ref.watch(scalableIngredientsProvider(recipeId));

    // Find currently selected ingredient
    String selectedText = 'Select ingredient';
    if (state.selectedIngredientId != null) {
      final selected = scalableIngredients.firstWhere(
        (i) => i.id == state.selectedIngredientId,
        orElse: () => (id: '', name: '', displayName: 'Select ingredient'),
      );
      selectedText = selected.name.isNotEmpty ? selected.name : 'Select ingredient';
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ingredient',
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
            ),
          ),
          Flexible(
            child: AdaptivePullDownButton(
              items: scalableIngredients.map((ingredient) {
                return AdaptiveMenuItem(
                  title: ingredient.displayName,
                  icon: Icon(
                    state.selectedIngredientId == ingredient.id
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: state.selectedIngredientId == ingredient.id
                        ? colors.primary
                        : colors.textSecondary,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(scaleConvertProvider(recipeId).notifier)
                        .setSelectedIngredient(ingredient.id);
                  },
                );
              }).toList(),
              child: _DropdownButtonChip(
                text: selectedText,
                maxWidth: 180,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCALE SLIDER ROW
// ============================================================

class _ScaleSliderRow extends ConsumerWidget {
  final String recipeId;
  final ScaleConvertState state;
  final int? recipeServings;

  const _ScaleSliderRow({
    required this.recipeId,
    required this.state,
    this.recipeServings,
  });

  (double min, double max) _getSliderRange() {
    switch (state.scaleType) {
      case ScaleType.amount:
        return (0.25, 10.0);
      case ScaleType.servings:
        // Servings slider works in target servings, not scale factor
        // Range: 1 serving to 4x original servings
        final originalServings = recipeServings?.toDouble() ?? 4.0;
        return (1.0, originalServings * 4);
      case ScaleType.ingredient:
        // For ingredient mode, scale factor is computed based on target amount
        // Default range from 0.1x to 5x
        return (0.1, 5.0);
    }
  }

  /// Get the current slider value (may differ from scaleFactor for servings mode)
  double _getSliderValue() {
    switch (state.scaleType) {
      case ScaleType.amount:
      case ScaleType.ingredient:
        return state.scaleFactor;
      case ScaleType.servings:
        // Convert scale factor to target servings for display
        final originalServings = recipeServings ?? 4;
        return state.scaleFactor * originalServings;
    }
  }

  /// Convert slider value to scale factor
  double _sliderValueToScaleFactor(double sliderValue) {
    switch (state.scaleType) {
      case ScaleType.amount:
      case ScaleType.ingredient:
        return sliderValue;
      case ScaleType.servings:
        // Convert target servings to scale factor
        final originalServings = recipeServings ?? 4;
        return sliderValue / originalServings;
    }
  }

  /// Get slider divisions for snapping behavior
  int? _getSliderDivisions(double min, double max) {
    switch (state.scaleType) {
      case ScaleType.amount:
        // 0.25x steps for fraction-friendly values
        return ((max - min) / 0.25).round();
      case ScaleType.servings:
        // Integer steps for whole servings
        return (max - min).round();
      case ScaleType.ingredient:
        // No snapping for ingredient mode (continuous)
        return null;
    }
  }

  String _getSliderLabel() {
    switch (state.scaleType) {
      case ScaleType.amount:
        return 'Amount: ${_formatScale(state.scaleFactor)}x';
      case ScaleType.servings:
        final targetServings =
            (state.scaleFactor * (recipeServings ?? 4)).round();
        return 'Servings: $targetServings';
      case ScaleType.ingredient:
        if (state.targetIngredientAmount != null) {
          return 'Amount: ${_formatAmount(state.targetIngredientAmount!)} ${state.targetIngredientUnit ?? ''}';
        }
        return 'Amount: ${_formatScale(state.scaleFactor)}x';
    }
  }

  String _formatScale(double scale) {
    if (scale == scale.truncate()) {
      return scale.toInt().toString();
    }
    return scale.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncate()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final (min, max) = _getSliderRange();

    // Get slider value (may be different from scaleFactor for servings mode)
    final sliderValue = _getSliderValue().clamp(min, max);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Label with fixed width to prevent slider jumping
          SizedBox(
            width: 110,
            child: Text(
              _getSliderLabel(),
              style: AppTypography.body.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),

          SizedBox(width: AppSpacing.md),

          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colors.primary,
                inactiveTrackColor: colors.border,
                thumbColor: colors.primary,
                overlayColor: colors.primary.withValues(alpha: 0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: Slider(
                value: sliderValue,
                min: min,
                max: max,
                // Use divisions for snapping:
                // - Amount mode: 0.25x steps for nice fraction-friendly values
                // - Servings mode: integer steps for whole servings
                divisions: _getSliderDivisions(min, max),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  final scaleFactor = _sliderValueToScaleFactor(value);
                  ref
                      .read(scaleConvertProvider(recipeId).notifier)
                      .setScaleFactor(scaleFactor);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONVERT ROW
// ============================================================

class _ConvertRow extends ConsumerWidget {
  final String recipeId;
  final ScaleConvertState state;

  const _ConvertRow({
    required this.recipeId,
    required this.state,
  });

  String _getConversionLabel(ConversionMode mode) {
    switch (mode) {
      case ConversionMode.original:
        return 'Original';
      case ConversionMode.imperial:
        return 'Imperial';
      case ConversionMode.metric:
        return 'Metric';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Convert',
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
            ),
          ),
          AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Original',
                icon: Icon(
                  state.conversionMode == ConversionMode.original
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.doc_text,
                  color: state.conversionMode == ConversionMode.original
                      ? colors.primary
                      : colors.textPrimary,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(scaleConvertProvider(recipeId).notifier)
                      .setConversionMode(ConversionMode.original);
                },
              ),
              AdaptiveMenuItem(
                title: 'Imperial',
                icon: Icon(
                  state.conversionMode == ConversionMode.imperial
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.flag,
                  color: state.conversionMode == ConversionMode.imperial
                      ? colors.primary
                      : colors.textPrimary,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(scaleConvertProvider(recipeId).notifier)
                      .setConversionMode(ConversionMode.imperial);
                },
              ),
              AdaptiveMenuItem(
                title: 'Metric',
                icon: Icon(
                  state.conversionMode == ConversionMode.metric
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.globe,
                  color: state.conversionMode == ConversionMode.metric
                      ? colors.primary
                      : colors.textPrimary,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(scaleConvertProvider(recipeId).notifier)
                      .setConversionMode(ConversionMode.metric);
                },
              ),
            ],
            child: _DropdownButtonChip(
              text: _getConversionLabel(state.conversionMode),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SHARED COMPONENTS
// ============================================================

/// Styled chip button for dropdowns
class _DropdownButtonChip extends StatelessWidget {
  final String text;
  final double maxWidth;

  const _DropdownButtonChip({
    required this.text,
    this.maxWidth = 140,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              text,
              style: TextStyle(
                color: colors.chipText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: colors.chipText,
          ),
        ],
      ),
    );
  }
}
