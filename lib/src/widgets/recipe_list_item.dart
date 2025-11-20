import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../database/models/recipe_images.dart';
import '../theme/spacing.dart';
import '../theme/colors.dart';
import '../utils/duration_formatter.dart';
import 'local_or_network_image.dart';
import 'recipe_placeholder_image.dart';

class RecipeListItem extends StatelessWidget {
  final RecipeEntry recipe;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RecipeListItem({
    super.key,
    required this.recipe,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Get the cover image
    final coverImage = RecipeImage.getCoverImage(recipe.images);
    final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

    // Format time display (same logic as RecipeTile)
    String timeDisplay = '';
    if (recipe.totalTime != null) {
      timeDisplay = DurationFormatter.formatMinutes(recipe.totalTime!);
    } else if (recipe.prepTime != null && recipe.cookTime != null) {
      final totalTime = (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
      if (totalTime > 0) {
        timeDisplay = DurationFormatter.formatMinutes(totalTime);
      }
    } else if (recipe.prepTime != null && recipe.prepTime! > 0) {
      timeDisplay = DurationFormatter.formatMinutes(recipe.prepTime!);
    } else if (recipe.cookTime != null && recipe.cookTime! > 0) {
      timeDisplay = DurationFormatter.formatMinutes(recipe.cookTime!);
    }

    // Format servings display
    String servingsDisplay = '';
    if (recipe.servings != null && recipe.servings! > 0) {
      servingsDisplay = '${recipe.servings} serving${recipe.servings! > 1 ? 's' : ''}';
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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 60,
              height: 60,
              child: FutureBuilder<String>(
                future: coverImage?.getFullPath() ?? Future.value(''),
                builder: (context, snapshot) {
                  final coverImageFilePath = snapshot.data ?? '';
                  final hasImage = coverImageFilePath.isNotEmpty || coverImageUrl.isNotEmpty;
                  
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasImage
                        ? LocalOrNetworkImage(
                            filePath: coverImageFilePath,
                            url: coverImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : RecipePlaceholderImage(
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  if (subtitleText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Optional trailing widget
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}