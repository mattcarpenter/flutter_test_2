import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart' as recipe_provider;

class MealPlanRecipeSearchResults extends ConsumerWidget {
  final void Function(RecipeEntry) onResultSelected;

  const MealPlanRecipeSearchResults({
    super.key,
    required this.onResultSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recipe_provider.cookModalRecipeSearchProvider);

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${searchState.error}',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.destructiveRed.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty && searchState.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedFileSearch,
              size: 48,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No recipes found',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoScrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: searchState.results.length,
        itemBuilder: (context, index) {
          final recipe = searchState.results[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _RecipeSearchResultTile(
              recipe: recipe,
              onTap: () => onResultSelected(recipe),
            ),
          );
        },
      ),
    );
  }
}

class _RecipeSearchResultTile extends StatelessWidget {
  final RecipeEntry recipe;
  final VoidCallback onTap;

  const _RecipeSearchResultTile({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Recipe icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedBook01,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Recipe details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (recipe.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      recipe.description!,
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Additional metadata
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (recipe.totalTime != null) ...[
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 12,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTime}m',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: 12,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                      
                      if (recipe.servings != null) ...[
                        if (recipe.totalTime != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 12,
                            color: CupertinoColors.separator.resolveFrom(context),
                          ),
                          const SizedBox(width: 12),
                        ],
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUserGroup,
                          size: 12,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings} servings',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: 12,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                      
                      if (recipe.rating != null) ...[
                        if (recipe.totalTime != null || recipe.servings != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 12,
                            color: CupertinoColors.separator.resolveFrom(context),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          CupertinoIcons.star_fill,
                          size: 12,
                          color: CupertinoColors.systemYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.rating.toString(),
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: 12,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Add button indicator
            const SizedBox(width: 8),
            HugeIcon(
              icon: HugeIcons.strokeRoundedAddCircle,
              size: 24,
              color: CupertinoColors.activeBlue.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}