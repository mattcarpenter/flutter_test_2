import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../widgets/local_or_network_image.dart';

class PinnedRecipeCard extends StatelessWidget {
  final RecipeEntry recipe;
  final VoidCallback? onTap;

  const PinnedRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the cover image
    final coverImage = RecipeImage.getCoverImage(recipe.images);
    final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

    // Format time display
    String timeDisplay = '';
    if (recipe.totalTime != null) {
      timeDisplay = '${recipe.totalTime} min';
    } else if (recipe.prepTime != null && recipe.cookTime != null) {
      final totalTime = (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
      if (totalTime > 0) {
        timeDisplay = '$totalTime min';
      }
    } else if (recipe.prepTime != null && recipe.prepTime! > 0) {
      timeDisplay = '${recipe.prepTime} min';
    } else if (recipe.cookTime != null && recipe.cookTime! > 0) {
      timeDisplay = '${recipe.cookTime} min';
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
            // Image
            SizedBox(
              width: cardWidth,
              height: imageHeight,
              child: FutureBuilder<String>(
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
                        : Container(
                            width: cardWidth,
                            height: imageHeight,
                            color: Colors.grey[100],
                            child: Center(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                  );
                },
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
                style: Theme.of(context).textTheme.titleSmall,
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
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}