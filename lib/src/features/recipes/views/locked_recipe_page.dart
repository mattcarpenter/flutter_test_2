import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../providers/recipe_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/local_or_network_image.dart';
import '../../../widgets/recipe_placeholder_image.dart';

/// Shown when user taps a recipe they don't have access to.
/// Displays recipe image/title as teaser with upgrade prompt.
class LockedRecipePage extends ConsumerWidget {
  final RecipeEntry recipe;

  const LockedRecipePage({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final lockedCount = ref.watch(lockedRecipeCountProvider);

    // Get the cover image
    final coverImage = RecipeImage.getCoverImage(recipe.images);
    final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button header
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AppCircleButton(
                    icon: AppCircleButtonIcon.close,
                    variant: AppCircleButtonVariant.neutral,
                    size: 36,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recipe image teaser
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 150,
                          width: 150,
                          child: _buildRecipeImage(coverImage, coverImageUrl),
                        ),
                      ),

                      SizedBox(height: AppSpacing.lg),

                      // Recipe title
                      Text(
                        recipe.title,
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: AppSpacing.xl),

                      // Lock icon
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 48,
                        color: colors.textSecondary,
                      ),

                      SizedBox(height: AppSpacing.lg),

                      // Message - explain why it's locked
                      Text(
                        'Your first 6 recipes are free',
                        style: AppTypography.body.copyWith(color: colors.textSecondary),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: AppSpacing.sm),

                      // Value prop
                      Text(
                        'Upgrade to save unlimited recipes',
                        style: AppTypography.body.copyWith(color: colors.textPrimary),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: AppSpacing.xl),

                      // Upgrade button
                      AppButtonVariants.primaryFilled(
                        text: 'Upgrade to Plus',
                        size: AppButtonSize.large,
                        onPressed: () async {
                          await ref.read(subscriptionProvider.notifier).presentPaywall(context);
                          // If purchased, isRecipeLockedProvider will reactively become false
                          // and the parent RecipePage will show the recipe content
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(RecipeImage? coverImage, String coverImageUrl) {
    if (coverImage == null) {
      return const RecipePlaceholderImage(
        height: 150,
        width: 150,
        fit: BoxFit.cover,
      );
    }

    return FutureBuilder<String>(
      future: coverImage.getFullPath(),
      builder: (context, snapshot) {
        final coverImageFilePath = snapshot.data ?? '';
        final hasImage = coverImageFilePath.isNotEmpty || coverImageUrl.isNotEmpty;

        if (!hasImage) {
          return const RecipePlaceholderImage(
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          );
        }

        return LocalOrNetworkImage(
          filePath: coverImageFilePath,
          url: coverImageUrl,
          height: 150,
          width: 150,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
