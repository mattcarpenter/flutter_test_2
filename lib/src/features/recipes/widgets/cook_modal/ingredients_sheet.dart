import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import '../../../../providers/recipe_provider.dart' show recipeByIdStreamProvider;
import '../../../../providers/scale_convert_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../../../widgets/app_circle_button.dart';
import '../../../../services/ingredient_parser_service.dart';
import '../../models/scale_convert_state.dart';
import '../scale_convert/scale_convert_panel.dart';

void showIngredientsModal(
  BuildContext context,
  List<Ingredient> ingredients, {
  String? recipeId,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) {
      return [
        SliverWoltModalSheetPage(
          navBarHeight: 55,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: false,
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
          ),
          mainContentSliversBuilder: (context) => [
            SliverToBoxAdapter(
              child: IngredientsSheet(
                ingredients: ingredients,
                recipeId: recipeId,
              ),
            ),
          ],
        ),
      ];
    },
  );
}

class IngredientsSheet extends ConsumerStatefulWidget {
  final List<Ingredient> ingredients;
  final String? recipeId;

  const IngredientsSheet({
    super.key,
    required this.ingredients,
    this.recipeId,
  });

  @override
  ConsumerState<IngredientsSheet> createState() => _IngredientsSheetState();
}

class _IngredientsSheetState extends ConsumerState<IngredientsSheet>
    with SingleTickerProviderStateMixin {
  final _parser = IngredientParserService();
  late AnimationController _accordionController;
  late Animation<double> _accordionAnimation;

  @override
  void initState() {
    super.initState();
    _accordionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _accordionAnimation = CurvedAnimation(
      parent: _accordionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _accordionController.dispose();
    super.dispose();
  }

  void _toggleAccordion() {
    if (_accordionController.isCompleted) {
      _accordionController.reverse();
    } else {
      _accordionController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch transformed ingredients if recipeId is provided
    final transformedIngredients = widget.recipeId != null
        ? ref.watch(transformedIngredientsByIdProvider(widget.recipeId!))
        : <String, TransformedIngredient>{};

    // Watch recipe to get servings for scale panel
    final recipeServings = widget.recipeId != null
        ? ref.watch(recipeByIdStreamProvider(widget.recipeId!)).valueOrNull?.servings
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row with "Scale or Convert" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingredients',
                style: AppTypography.h4.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              if (widget.recipeId != null)
                TextButton(
                  onPressed: _toggleAccordion,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: AnimatedBuilder(
                    animation: _accordionController,
                    builder: (context, child) {
                      // Check if any transform is active
                      final isTransformActive =
                          ref.watch(scaleConvertProvider(widget.recipeId!)).isTransformActive;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTransformActive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.of(context).error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Text('Scale or Convert'),
                          const SizedBox(width: 4),
                          Icon(
                            _accordionController.value > 0.5
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),

          // Animated accordion panel for scale/convert
          if (widget.recipeId != null)
            SizeTransition(
              sizeFactor: _accordionAnimation,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _accordionAnimation,
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: ScaleConvertPanel(
                    recipeId: widget.recipeId!,
                    recipeServings: recipeServings,
                  ),
                ),
              ),
            ),

          SizedBox(height: AppSpacing.lg),

          // Ingredients list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = widget.ingredients[index];

              // Section header
              if (ingredient.type == 'section') {
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : AppSpacing.xl,
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    ingredient.name,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                );
              }

              // Regular ingredient with optional transformation
              final transformed = transformedIngredients[ingredient.id];

              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 8.0,
                  bottom: 8.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bullet point
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.0,
                        color: AppColors.of(context).contentSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ingredient name with parsed quantities
                    Expanded(
                      child: _buildIngredientText(
                        context,
                        ingredient: ingredient,
                        transformed: transformed,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds ingredient text with bold quantities, supporting transformed ingredients.
  Widget _buildIngredientText(
    BuildContext context, {
    required Ingredient ingredient,
    TransformedIngredient? transformed,
  }) {
    final colors = AppColors.of(context);
    final baseStyle = TextStyle(fontSize: 16, color: colors.contentPrimary);

    // Determine which text and quantity positions to use
    String text;
    List<({int start, int end})> quantityPositions;

    if (transformed != null && (transformed.wasScaled || transformed.wasConverted)) {
      // Use transformed text and positions
      text = transformed.displayText;
      quantityPositions = transformed.quantities
          .map((q) => (start: q.start, end: q.end))
          .toList();
    } else {
      // Parse original ingredient name
      text = ingredient.name;
      try {
        final parseResult = _parser.parse(text);
        quantityPositions = parseResult.quantities
            .map((q) => (start: q.start, end: q.end))
            .toList();
      } catch (_) {
        quantityPositions = [];
      }
    }

    if (quantityPositions.isEmpty) {
      // No quantities found, return plain text
      return Text(text, style: baseStyle);
    }

    // Build rich text with bold quantities
    final children = <InlineSpan>[];
    int currentIndex = 0;

    for (final quantity in quantityPositions) {
      // Text before quantity
      if (quantity.start > currentIndex) {
        children.add(TextSpan(
          text: text.substring(currentIndex, quantity.start),
          style: baseStyle,
        ));
      }

      // Quantity with bold formatting
      children.add(TextSpan(
        text: text.substring(quantity.start, quantity.end),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = quantity.end;
    }

    // Remaining text after last quantity
    if (currentIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: children),
    );
  }
}
