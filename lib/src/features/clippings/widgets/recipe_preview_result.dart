import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../models/recipe_preview.dart';

/// Displays a recipe preview with fading ingredients and a subscribe button.
///
/// Used for non-subscribed users to show a teaser of the recipe.
class RecipePreviewResultContent extends StatelessWidget {
  final RecipePreview preview;
  final VoidCallback onSubscribe;

  const RecipePreviewResultContent({
    super.key,
    required this.preview,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            preview.title,
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),

          if (preview.description.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              preview.description,
              style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          SizedBox(height: AppSpacing.lg),

          // Preview ingredients with fade effect
          ...preview.previewIngredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;

            // Calculate opacity: 1.0, 0.85, 0.55, 0.25
            final opacity = switch (index) {
              0 => 1.0,
              1 => 0.85,
              2 => 0.55,
              3 => 0.25,
              _ => 0.15,
            };

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.circle_fill,
                    size: 6,
                    color: colors.textPrimary.withOpacity(opacity),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary.withOpacity(opacity),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // "More ingredients" teaser (always show if we have 4 items)
          if (preview.previewIngredients.length >= 4) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              '+ more ingredients...',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          SizedBox(height: AppSpacing.xl),

          // Subscribe button
          AppButton(
            text: 'Unlock Full Recipe',
            onPressed: onSubscribe,
            theme: AppButtonTheme.primary,
            style: AppButtonStyle.fill,
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            leadingIcon: const Icon(CupertinoIcons.sparkles, size: 18),
          ),
        ],
      ),
    );
  }
}
