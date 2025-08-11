import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/spacing.dart';
import 'pinned_recipe_card.dart';

class PinnedRecipesSection extends ConsumerWidget {
  const PinnedRecipesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedRecipesAsync = ref.watch(pinnedRecipesProvider);

    return pinnedRecipesAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (pinnedRecipes) {
        if (pinnedRecipes.isEmpty) {
          return const SizedBox.shrink(); // Don't show section if no pinned recipes
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with title and "View All" button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pinned Recipes',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navLargeTitleTextStyle
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/recipes/pinned');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Horizontal scrolling list
            SizedBox(
              height: 200, // Fixed height for the horizontal scroll area
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: pinnedRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = pinnedRecipes[index];
                  final isFirst = index == 0;
                  final isLast = index == pinnedRecipes.length - 1;
                  
                  return Container(
                    margin: EdgeInsets.only(
                      left: isFirst ? 16.0 : 0.0,  // First card aligns with headers
                      right: isLast ? 16.0 : 12.0, // Last card has padding, others have spacing
                    ),
                    child: PinnedRecipeCard(
                      recipe: recipe,
                      onTap: () {
                        context.push('/recipes/recipe/${recipe.id}', extra: {
                          'previousPageTitle': 'Recipes',
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}