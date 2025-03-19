import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../widgets/local_or_network_image.dart';

class RecipeTile extends StatelessWidget {
  final RecipeEntry recipe;

  const RecipeTile({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth;
        final tileHeight = constraints.maxHeight; // From GridView.mainAxisExtent

        // Constants for spacing and text height
        const double spacingAboveName = 8.0;
        const double recipeNameHeight = 20.0;
        const double spacingBetweenNameAndDetails = 4.0;
        const double bottomSpacing = 8.0;
        const double detailsHeightSingleRow = 28.0;
        const double detailsHeightDoubleRow = 48.0; // More space if chip wraps

        // Check if we have enough space for the time & difficulty on one row
        final isWideEnoughForOneRow = tileWidth > 140;

        // Determine actual content height based on layout
        final detailsHeight = isWideEnoughForOneRow ? detailsHeightSingleRow : detailsHeightDoubleRow;
        final fixedContentHeight = spacingAboveName + recipeNameHeight + spacingBetweenNameAndDetails + detailsHeight + bottomSpacing;

        // Compute the dynamic image height
        final imageHeight = tileHeight - fixedContentHeight;

        // Format time display
        String timeDisplay = 'N/A';
        if (recipe.totalTime != null) {
          timeDisplay = '${recipe.totalTime} mins';
        } else if (recipe.prepTime != null && recipe.cookTime != null) {
          timeDisplay = '${(recipe.prepTime ?? 0) + (recipe.cookTime ?? 0)} mins';
        } else if (recipe.prepTime != null) {
          timeDisplay = '${recipe.prepTime} mins';
        } else if (recipe.cookTime != null) {
          timeDisplay = '${recipe.cookTime} mins';
        }

        // Determine difficulty
        String difficulty = 'Medium';
        if (recipe.rating != null) {
          if (recipe.rating! <= 2) difficulty = 'Easy';
          else if (recipe.rating! >= 4) difficulty = 'Hard';
        }

        // Get the cover image
        final coverImage = RecipeImage.getCoverImage(recipe.images);
        final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use FutureBuilder to wait for the file path
              FutureBuilder<String>(
                future: coverImage?.getFullPath() ?? Future.value(''),
                builder: (context, snapshot) {
                  final coverImageFilePath = snapshot.data ?? '';
                  return LocalOrNetworkImage(
                    filePath: coverImageFilePath,
                    url: coverImageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
              const SizedBox(height: spacingAboveName),
              // Recipe name (fixed height)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: recipeNameHeight,
                  child: Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              const SizedBox(height: spacingBetweenNameAndDetails),
              // Details area (time + difficulty chip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: isWideEnoughForOneRow
                    ? Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(timeDisplay, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(difficulty, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(timeDisplay, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(difficulty, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: bottomSpacing),
            ],
          ),
        );
      },
    );
  }
}
