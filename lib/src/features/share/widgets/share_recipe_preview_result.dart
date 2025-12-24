import 'package:flutter/cupertino.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../clippings/models/recipe_preview.dart';

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
        'PLUS',
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
  final IconData? icon;
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
          icon != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    icon,
                    size: 14,
                    color: colors.textPrimary,
                  ),
                )
              : const SizedBox(width: 14),
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

/// Displays a recipe preview for shared content with fading ingredients and a subscribe button.
///
/// Used for non-subscribed users to show a teaser of the extracted recipe from
/// social media shares (Instagram, TikTok).
class ShareRecipePreviewResultContent extends StatefulWidget {
  final RecipePreview preview;
  final VoidCallback onSubscribe;

  const ShareRecipePreviewResultContent({
    super.key,
    required this.preview,
    required this.onSubscribe,
  });

  @override
  State<ShareRecipePreviewResultContent> createState() =>
      _ShareRecipePreviewResultContentState();
}

class _ShareRecipePreviewResultContentState
    extends State<ShareRecipePreviewResultContent> {
  bool _isLoading = false;

  void _handleSubscribeTap() {
    setState(() {
      _isLoading = true;
    });

    // Call the subscribe callback
    widget.onSubscribe();

    // Reset loading state after 3 seconds (paywall should be visible by then)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
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
                Icon(
                  CupertinoIcons.sparkles,
                  size: 20,
                  color: colors.textPrimary,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Import Recipe',
                    style: AppTypography.h4.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const _PlusPill(),
              ],
            ),

            SizedBox(height: AppSpacing.lg),

            // Preview Card with bottom fade
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.white,
                    CupertinoColors.white,
                    CupertinoColors.white.withValues(alpha: 0.7),
                    CupertinoColors.white.withValues(alpha: 0.3),
                    CupertinoColors.white.withValues(alpha: 0),
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
                  bottom: 0,
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
                    const _SectionLabel('Recipe Name'),
                    Text(
                      preview.title,
                      style: AppTypography.h5.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: AppSpacing.md),

                    // Description (if available)
                    if (preview.description.isNotEmpty) ...[
                      const _SectionLabel('Description'),
                      Text(
                        preview.description,
                        style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.md),
                    ],

                    // Ingredients section
                    const _SectionLabel('Ingredients'),
                    ...preview.previewIngredients.take(4).map((ingredient) {
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Extra space at bottom for fade area
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Value Proposition section - overlaps with faded area
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
                          Icon(
                            CupertinoIcons.wand_stars,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              "We'll structure it for you",
                              style: AppTypography.h4.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSpacing.md),

                      // Left-aligned list
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ValuePropItem(
                              icon: CupertinoIcons.check_mark,
                              text: 'Turn posts into real recipes',
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              icon: CupertinoIcons.check_mark,
                              text: 'Auto-extract ingredients and steps',
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              icon: CupertinoIcons.check_mark,
                              text: 'Works with Instagram & TikTok',
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              icon: CupertinoIcons.check_mark,
                              text: 'Save it to your Library',
                              textColor: colors.textPrimary,
                            ),
                            _ValuePropItem(
                              text: '… and much more!',
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

            // CTA Button
            Transform.translate(
              offset: const Offset(0, -64),
              child: AppButton(
                text: 'Unlock with Plus',
                onPressed: _isLoading ? null : _handleSubscribeTap,
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.fill,
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                loading: _isLoading,
                leadingIcon:
                    _isLoading ? null : const Icon(CupertinoIcons.sparkles, size: 18),
              ),
            ),

            // Safe area padding
            SizedBox(
              height: (MediaQuery.of(context).padding.bottom + AppSpacing.sm)
                  .clamp(0, double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
