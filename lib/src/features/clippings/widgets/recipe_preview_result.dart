import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../models/recipe_preview.dart';

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
        context.l10n.clippingsPreviewPlusBadge,
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

/// Section label with all-caps styling
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: colors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Value proposition bullet item
class _ValuePropItem extends StatelessWidget {
  final List<List<dynamic>>? icon;
  final String text;
  final Color? textColor;

  const _ValuePropItem({
    required this.text,
    this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon != null ?
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: HugeIcon(
                icon: icon!,
                size: 14,
                color: colors.textPrimary,
              ),
            )
          : SizedBox(width: 14),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: textColor ?? colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: Title + Plus pill
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAiMagic,
                  size: 20,
                  color: colors.textPrimary,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.l10n.clippingsConvertToRecipe,
                    style: AppTypography.h4.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const _PlusPill(),
              ],
            ),

            SizedBox(height: AppSpacing.lg),

            // Preview Card with bottom fade - fades to background color
            // Uses eased stops for non-linear fade (slower at top, faster at bottom)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.white,
                    CupertinoColors.white,
                    CupertinoColors.white.withOpacity(0.7),
                    CupertinoColors.white.withOpacity(0.3),
                    CupertinoColors.white.withOpacity(0),
                  ],
                  stops: const [0.0, 0.25, 0.55, 0.75, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: 0, // No bottom padding - let content fade
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Name section
                    _SectionLabel(context.l10n.clippingsPreviewRecipeName),
                    Text(
                      preview.title,
                      style: AppTypography.h5.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),

                    // Description section (if available)
                    if (preview.description.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.md),
                      _SectionLabel(context.l10n.clippingsPreviewDescription),
                      Text(
                        preview.description,
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: AppSpacing.md),

                    // Ingredients section
                    _SectionLabel(context.l10n.clippingsPreviewIngredients),
                    ...preview.previewIngredients.map((ingredient) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.circle_fill,
                              size: 6,
                              color: colors.textPrimary,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                ingredient,
                                style: AppTypography.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Extra space at bottom for fade area
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Value Proposition section - positioned to start exactly where fade ends
            Transform.translate(
              offset: const Offset(0, -80),
              child: Center(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColorSwatches.primary[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorSwatches.primary[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Centered headline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMagicWand01,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.clippingsPreviewValuePropHeadline,
                              style: AppTypography.h4.copyWith(
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSpacing.md),

                      // Left-aligned list in centered container
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ValuePropItem(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              text: context.l10n.clippingsPreviewValuePropRecipe1,
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              text: context.l10n.clippingsPreviewValuePropRecipe2,
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              text: context.l10n.clippingsPreviewValuePropRecipe3,
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              text: context.l10n.clippingsPreviewValuePropRecipe4,
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              text: context.l10n.clippingsPreviewValuePropMore,
                              textColor: colors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // CTA Button - pull up to reduce gap after value prop
            Transform.translate(
              offset: const Offset(0, -64),
              child: AppButton(
                text: context.l10n.clippingsPreviewUnlockPlus,
                onPressed: onSubscribe,
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.fill,
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                leadingIcon: const HugeIcon(icon: HugeIcons.strokeRoundedAiMagic, size: 18),
              ),
            ),

            // Safe area padding for rounded iPhone screens (adjusted for transform)
            SizedBox(height: (MediaQuery.of(context).padding.bottom + AppSpacing.sm).clamp(0, double.infinity)),
          ],
        ),
      ),
    );
  }
}
