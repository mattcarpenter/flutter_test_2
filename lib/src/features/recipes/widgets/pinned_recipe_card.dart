import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../utils/duration_formatter.dart';
import '../../../widgets/local_or_network_image.dart';
import '../../../widgets/recipe_placeholder_image.dart';

class PinnedRecipeCard extends StatelessWidget {
  final RecipeEntry recipe;
  final VoidCallback? onTap;
  final bool isLocked;

  const PinnedRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get the cover image
    final coverImage = RecipeImage.getCoverImage(recipe.images);
    final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

    // Format time display
    String timeDisplay = '';
    if (recipe.totalTime != null) {
      timeDisplay = DurationFormatter.formatMinutesLocalized(recipe.totalTime!, context);
    } else if (recipe.prepTime != null && recipe.cookTime != null) {
      final totalTime = (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
      if (totalTime > 0) {
        timeDisplay = DurationFormatter.formatMinutesLocalized(totalTime, context);
      }
    } else if (recipe.prepTime != null && recipe.prepTime! > 0) {
      timeDisplay = DurationFormatter.formatMinutesLocalized(recipe.prepTime!, context);
    } else if (recipe.cookTime != null && recipe.cookTime! > 0) {
      timeDisplay = DurationFormatter.formatMinutesLocalized(recipe.cookTime!, context);
    }

    // Format servings display
    String servingsDisplay = '';
    if (recipe.servings != null && recipe.servings! > 0) {
      servingsDisplay = context.l10n.recipeServingsCount(recipe.servings!);
    }

    // Combine time and servings with bullet separator
    String subtitleText = '';
    if (timeDisplay.isNotEmpty && servingsDisplay.isNotEmpty) {
      subtitleText = '$timeDisplay • $servingsDisplay';
    } else if (timeDisplay.isNotEmpty) {
      subtitleText = timeDisplay;
    } else if (servingsDisplay.isNotEmpty) {
      subtitleText = servingsDisplay;
    }

    // Calculate card dimensions - smaller to fit 2+ on screen
    const double cardWidth = 150.0;
    const double imageHeight = 120.0;
    const double titleHeight = 20.0;
    const double subtitleHeight = 16.0;
    const double spacing = 8.0;
    const double totalHeight = imageHeight + titleHeight + subtitleHeight + spacing * 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: totalHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with optional lock overlay
            SizedBox(
              width: cardWidth,
              height: imageHeight,
              child: Stack(
                children: [
                  FutureBuilder<String>(
                    future: coverImage?.getFullPath() ?? Future.value(''),
                    builder: (context, snapshot) {
                      final coverImageFilePath = snapshot.data ?? '';
                      final hasImage = coverImageFilePath.isNotEmpty || coverImageUrl.isNotEmpty;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasImage
                            ? LocalOrNetworkImage(
                                filePath: coverImageFilePath,
                                url: coverImageUrl,
                                width: cardWidth,
                                height: imageHeight,
                                fit: BoxFit.cover,
                              )
                            : RecipePlaceholderImage(
                                width: cardWidth,
                                height: imageHeight,
                                fit: BoxFit.cover,
                              ),
                      );
                    },
                  ),
                  if (isLocked)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_fill,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: spacing),
            
            // Title
            SizedBox(
              height: titleHeight,
              child: Text(
                recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle with time and servings
            if (subtitleText.isNotEmpty)
              SizedBox(
                height: subtitleHeight,
                child: Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}