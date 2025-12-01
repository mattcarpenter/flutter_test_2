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

        SizedBox(height: AppSpacing.lg),

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

/// Parsed ingredient info for slider configuration
class _ParsedIngredientInfo {
  final double amount;
  final String unit;
  final UnitType unitType;

  const _ParsedIngredientInfo({
    required this.amount,
    required this.unit,
    required this.unitType,
  });
}

class _ScaleSliderRow extends ConsumerWidget {
  final String recipeId;
  final ScaleConvertState state;
  final int? recipeServings;

  const _ScaleSliderRow({
    required this.recipeId,
    required this.state,
    this.recipeServings,
  });

  /// Parse the selected ingredient to get amount and unit info
  _ParsedIngredientInfo? _getSelectedIngredientInfo(WidgetRef ref) {
    if (state.scaleType != ScaleType.ingredient ||
        state.selectedIngredientId == null) {
      return null;
    }

    // Get the selected ingredient's name
    final scalableIngredients = ref.read(scalableIngredientsProvider(recipeId));
    final selected = scalableIngredients.firstWhere(
      (i) => i.id == state.selectedIngredientId,
      orElse: () => (id: '', name: '', displayName: ''),
    );

    if (selected.name.isEmpty) return null;

    // Parse the ingredient
    final parser = ref.read(ingredientParserServiceProvider);
    final converter = ref.read(unitConversionServiceProvider);
    final parsed =
        parser.parseEnhanced(selected.name, conversionService: converter);

    if (!parsed.hasQuantities) {
      // Bare ingredient - treat as count with amount 1
      return const _ParsedIngredientInfo(
        amount: 1.0,
        unit: '',
        unitType: UnitType.count,
      );
    }

    final quantity = parsed.primaryQuantity!;
    final unitType = converter.getUnitType(quantity.unit);

    return _ParsedIngredientInfo(
      amount: quantity.value,
      unit: quantity.unit,
      unitType: unitType,
    );
  }

  /// Get slider range based on scale type and ingredient info
  (double min, double max) _getSliderRange(
      _ParsedIngredientInfo? ingredientInfo) {
    switch (state.scaleType) {
      case ScaleType.amount:
        return (0.25, 10.0);
      case ScaleType.servings:
        final originalServings = recipeServings?.toDouble() ?? 4.0;
        return (1.0, originalServings * 4);
      case ScaleType.ingredient:
        if (ingredientInfo == null) {
          // Fall back to multiplier mode
          return (0.25, 10.0);
        }
        // Amount-based range depending on unit type
        final amount = ingredientInfo.amount;
        return switch (ingredientInfo.unitType) {
          UnitType.volume => _isMetricVolumeUnit(ingredientInfo.unit)
              ? (amount * 0.1, amount * 10) // metric: 0.1x to 10x
              : (amount * 0.125, amount * 8), // imperial: 1/8x to 8x
          UnitType.weight => _isMetricWeightUnit(ingredientInfo.unit)
              ? (amount * 0.1, amount * 10) // metric: 0.1x to 10x
              : (amount * 0.125, amount * 8), // imperial: 1/8x to 8x
          UnitType.count || UnitType.unknown => (
              (amount * 0.5).clamp(0.5, double.infinity),
              amount * 10,
            ), // count: 0.5x to 10x, min 0.5
          UnitType.approximate => (0.25, 10.0), // shouldn't happen
        };
    }
  }

  /// Check if unit is metric volume (ml, l, etc.)
  bool _isMetricVolumeUnit(String unit) {
    final lower = unit.toLowerCase();
    return {
      'ml',
      'milliliter',
      'milliliters',
      'l',
      'liter',
      'liters',
      'cl',
      'dl'
    }.contains(lower);
  }

  /// Check if unit is metric weight (g, kg, etc.)
  bool _isMetricWeightUnit(String unit) {
    final lower = unit.toLowerCase();
    return {'g', 'gram', 'grams', 'kg', 'kilogram', 'kilograms', 'mg'}
        .contains(lower);
  }

  /// Get the current slider value
  double _getSliderValue(_ParsedIngredientInfo? ingredientInfo) {
    switch (state.scaleType) {
      case ScaleType.amount:
        return state.scaleFactor;
      case ScaleType.servings:
        final originalServings = recipeServings ?? 4;
        return state.scaleFactor * originalServings;
      case ScaleType.ingredient:
        if (ingredientInfo == null) {
          return state.scaleFactor;
        }
        // Return target amount (original × scale factor)
        return ingredientInfo.amount * state.scaleFactor;
    }
  }

  /// Convert slider value to scale factor
  double _sliderValueToScaleFactor(
    double sliderValue,
    _ParsedIngredientInfo? ingredientInfo,
  ) {
    switch (state.scaleType) {
      case ScaleType.amount:
        return sliderValue;
      case ScaleType.servings:
        final originalServings = recipeServings ?? 4;
        return sliderValue / originalServings;
      case ScaleType.ingredient:
        if (ingredientInfo == null) {
          return sliderValue;
        }
        // Convert target amount back to scale factor
        return sliderValue / ingredientInfo.amount;
    }
  }

  /// Get slider divisions for snapping behavior
  int? _getSliderDivisions(
    double min,
    double max,
    _ParsedIngredientInfo? ingredientInfo,
  ) {
    switch (state.scaleType) {
      case ScaleType.amount:
        // 0.25x steps for fraction-friendly values
        return ((max - min) / 0.25).round();
      case ScaleType.servings:
        // Integer steps for whole servings
        return (max - min).round();
      case ScaleType.ingredient:
        if (ingredientInfo == null) {
          return ((max - min) / 0.25).round();
        }
        // Snapping based on unit type
        return switch (ingredientInfo.unitType) {
          UnitType.volume => _isMetricVolumeUnit(ingredientInfo.unit)
              ? null // metric volume: no snap
              : ((max - min) / 0.125).round().clamp(1, 200), // imperial: 1/8
          UnitType.weight => _isMetricWeightUnit(ingredientInfo.unit)
              ? null // metric weight: no snap
              : ((max - min) / 0.5).round().clamp(1, 200), // imperial: 0.5
          UnitType.count ||
          UnitType.unknown =>
            ((max - min) / 0.5).round().clamp(1, 200), // count: 0.5
          UnitType.approximate => null,
        };
    }
  }

  /// Get the slider label
  String _getSliderLabel(_ParsedIngredientInfo? ingredientInfo) {
    switch (state.scaleType) {
      case ScaleType.amount:
        return 'Amount: ${_formatScale(state.scaleFactor)}x';
      case ScaleType.servings:
        final targetServings =
            (state.scaleFactor * (recipeServings ?? 4)).round();
        return 'Servings: $targetServings';
      case ScaleType.ingredient:
        if (ingredientInfo == null) {
          return 'Amount: ${_formatScale(state.scaleFactor)}x';
        }
        final targetAmount = ingredientInfo.amount * state.scaleFactor;
        final formattedAmount = _formatIngredientAmount(
          targetAmount,
          ingredientInfo.unit,
          ingredientInfo.unitType,
        );
        final unitStr =
            ingredientInfo.unit.isNotEmpty ? ' ${ingredientInfo.unit}' : '';
        return 'Amount: $formattedAmount$unitStr';
    }
  }

  String _formatScale(double scale) {
    if (scale == scale.truncate()) {
      return scale.toInt().toString();
    }
    return scale.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Format ingredient amount based on unit type
  String _formatIngredientAmount(
      double amount, String unit, UnitType unitType) {
    // Use fractions for imperial volume/weight, decimals for metric
    final useDecimal = _isMetricVolumeUnit(unit) || _isMetricWeightUnit(unit);

    if (useDecimal) {
      return _formatDecimal(amount);
    } else {
      return _formatAsFraction(amount);
    }
  }

  String _formatDecimal(double value) {
    if (value == value.truncate()) {
      return value.toInt().toString();
    }
    if (value >= 100) {
      return value.round().toString();
    }
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.truncate()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  String _formatAsFraction(double value) {
    // Check for thirds first
    final whole = value.truncate();
    final fractional = value - whole;

    if ((fractional - 0.333).abs() < 0.02) {
      return whole == 0 ? '1/3' : '$whole 1/3';
    }
    if ((fractional - 0.666).abs() < 0.02 ||
        (fractional - 0.667).abs() < 0.02) {
      return whole == 0 ? '2/3' : '$whole 2/3';
    }

    // Round to nearest 1/8
    const granularity = 0.125;
    double rounded = (value / granularity).round() * granularity;
    if (rounded == 0 && value > 0) rounded = granularity;

    if (rounded == rounded.truncate()) {
      return rounded.toInt().toString();
    }

    final roundedWhole = rounded.truncate();
    final roundedFrac = rounded - roundedWhole;

    final fractionStr = _decimalToFraction(roundedFrac);

    if (roundedWhole == 0) {
      return fractionStr.isNotEmpty ? fractionStr : '0';
    } else if (fractionStr.isEmpty) {
      return roundedWhole.toString();
    }
    return '$roundedWhole $fractionStr';
  }

  String _decimalToFraction(double decimal) {
    if (decimal == 0) return '';
    const fractions = [
      (0.125, '1/8'),
      (0.25, '1/4'),
      (0.333, '1/3'),
      (0.375, '3/8'),
      (0.5, '1/2'),
      (0.625, '5/8'),
      (0.666, '2/3'),
      (0.667, '2/3'),
      (0.75, '3/4'),
      (0.875, '7/8'),
    ];
    for (final (value, fraction) in fractions) {
      if ((decimal - value).abs() < 0.02) {
        return fraction;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    // Get parsed ingredient info for ingredient mode
    final ingredientInfo = _getSelectedIngredientInfo(ref);

    final (min, max) = _getSliderRange(ingredientInfo);
    final sliderValue = _getSliderValue(ingredientInfo).clamp(min, max);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Label with fixed width to prevent slider jumping
          // Wide enough for "Amount: 1 1/2 tbsp" without wrapping
          SizedBox(
            width: 145,
            child: Text(
              _getSliderLabel(ingredientInfo),
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
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: Slider(
                value: sliderValue,
                min: min,
                max: max,
                divisions: _getSliderDivisions(min, max, ingredientInfo),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  final scaleFactor =
                      _sliderValueToScaleFactor(value, ingredientInfo);
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
