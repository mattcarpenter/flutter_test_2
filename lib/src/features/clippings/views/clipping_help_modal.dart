import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../localization/l10n_extension.dart';
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
                context.l10n.clippingsAboutTitle,
                style: AppTypography.h4.copyWith(
                  color: colors.textPrimary,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Section 1: What are clippings
              Text(
                context.l10n.clippingsAboutScratchpadTitle,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.clippingsAboutScratchpadBody,
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Section 2: Convert to Recipe
              Text(
                context.l10n.clippingsAboutConvertTitle,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.clippingsAboutConvertBody,
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
                        context.l10n.clippingsAboutConvertTip,
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
                context.l10n.clippingsAboutShoppingTitle,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.clippingsAboutShoppingBody,
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
