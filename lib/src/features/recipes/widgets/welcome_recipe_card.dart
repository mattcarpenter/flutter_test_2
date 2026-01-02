import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../views/recipe_creation_menu_modal.dart';

/// A welcome card shown to new users who have no recipes yet.
/// Encourages them to create their first recipe.
class WelcomeRecipeCard extends ConsumerWidget {
  const WelcomeRecipeCard({super.key});

  // Fixed width for the card on larger screens (iPad)
  static const double _maxCardWidth = 400.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeCount = ref.watch(userRecipeCountProvider);

    // Hide if user has any recipes
    if (recipeCount > 0) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.recipeWelcomeGettingStarted,
            style: AppTypography.h2Serif.copyWith(
              color: colors.headingSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? _maxCardWidth : double.infinity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mosaic image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Image.asset(
                    'assets/images/mosaic_en.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // Content pulled up into the white area of the image
                // Align with heightFactor < 1 collapses the extra space from the transform
                Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.75,
                  child: Transform.translate(
                    offset: const Offset(0, -60), // Pull up into white area
                    child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          context.l10n.recipeWelcomeTitle,
                          style: AppTypography.h3.copyWith(
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: AppSpacing.sm),

                        // Subtitle
                        Text(
                          context.l10n.recipeWelcomeSubtitle,
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // CTA Button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl * 2),
                          child: AppButton(
                            text: context.l10n.recipeCreateTitle,
                            onPressed: () {
                              showRecipeCreationMenuModal(
                                context,
                                ref: ref,
                                folderId: null,
                              );
                            },
                            theme: AppButtonTheme.dark,
                            style: AppButtonStyle.fill,
                            size: AppButtonSize.medium,
                            shape: AppButtonShape.round,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}
