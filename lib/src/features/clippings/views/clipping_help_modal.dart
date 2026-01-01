import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';

/// Shows a help modal explaining what Clippings are and how to use the AI features.
void showClippingHelpModal(BuildContext context) {
  final colors = AppColors.of(context);

  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 55,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        hasTopBarLayer: false,
        trailingNavBarWidget: Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.neutral,
            size: 32,
            onPressed: () =>
                Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'About Clippings',
                style: AppTypography.h4.copyWith(
                  color: colors.textPrimary,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Section 1: What are clippings
              Text(
                'Your recipe scratchpad',
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Capture recipe ideas from anywhere — websites, messages, photos, or just your own thoughts. No need to format anything perfectly.',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Section 2: Convert to Recipe
              Text(
                'Convert to Recipe',
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Turn your notes into a complete recipe. We\'ll extract ingredients, steps, cooking times, and more.',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),

              SizedBox(height: AppSpacing.md),

              // Tip box
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColorSwatches.primary[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColorSwatches.primary[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedIdea01,
                      size: 16,
                      color: AppColorSwatches.primary[600],
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Have a partial recipe? Add "Complete this recipe" to your notes and we\'ll fill in the missing details.',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Section 3: To Shopping List
              Text(
                'To Shopping List',
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Pull out the items you need to buy. We\'ll organize them by aisle automatically.',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
