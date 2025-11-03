import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../../../widgets/app_circle_button.dart';
import '../../../../services/ingredient_parser_service.dart';

void showIngredientsModal(BuildContext context, List<Ingredient> ingredients) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
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
              child: IngredientsSheet(ingredients: ingredients),
            ),
          ],
        ),
      ];
    },
  );
}

class IngredientsSheet extends StatelessWidget {
  final List<Ingredient> ingredients;
  final _parser = IngredientParserService();

  IngredientsSheet({
    super.key,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Ingredients',
            style: AppTypography.h4.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Ingredients list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];

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

              // Regular ingredient
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
                      child: _buildParsedIngredientText(context, ingredient.name),
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

  /// Builds a RichText widget with bold quantities parsed from ingredient text
  Widget _buildParsedIngredientText(BuildContext context, String text) {
    final colors = AppColors.of(context);

    try {
      final parseResult = _parser.parse(text);

      if (parseResult.quantities.isEmpty) {
        // No quantities found, return plain text
        return Text(
          text,
          style: TextStyle(fontSize: 16, color: colors.contentPrimary),
        );
      }

      final children = <InlineSpan>[];
      int currentIndex = 0;

      // Build TextSpan with bold quantities, normal ingredient names
      for (final quantity in parseResult.quantities) {
        // Text before quantity (ingredient name)
        if (quantity.start > currentIndex) {
          children.add(TextSpan(
            text: text.substring(currentIndex, quantity.start),
            style: TextStyle(fontSize: 16, color: colors.contentPrimary),
          ));
        }

        // Quantity with bold formatting
        children.add(TextSpan(
          text: text.substring(quantity.start, quantity.end),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.contentPrimary),
        ));

        currentIndex = quantity.end;
      }

      // Remaining text after last quantity
      if (currentIndex < text.length) {
        children.add(TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(fontSize: 16, color: colors.contentPrimary),
        ));
      }

      return RichText(
        text: TextSpan(children: children),
      );
    } catch (e) {
      // Fallback to plain text if parsing fails
      return Text(
        text,
        style: TextStyle(fontSize: 16, color: colors.contentPrimary),
      );
    }
  }
}
