import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../models/shopping_list_preview.dart';

/// Displays a shopping list preview with fading items and a subscribe button.
///
/// Used for non-subscribed users to show a teaser of the shopping list.
class ShoppingListPreviewResultContent extends StatelessWidget {
  final ShoppingListPreview preview;
  final VoidCallback onSubscribe;

  const ShoppingListPreviewResultContent({
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
          // Header - generic since we don't know total count
          Text(
            'Shopping Items Found',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Preview items with fade
          ...preview.previewItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

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
                    CupertinoIcons.checkmark_square,
                    size: 18,
                    color: colors.textPrimary.withOpacity(opacity),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary.withOpacity(opacity),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // "More items" teaser (always show if we have 4 items)
          if (preview.previewItems.length >= 4) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              '+ more items...',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          SizedBox(height: AppSpacing.xl),

          // Subscribe button
          AppButton(
            text: 'Unlock All Items',
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
