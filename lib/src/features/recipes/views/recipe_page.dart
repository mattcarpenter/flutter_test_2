import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/recipe_view/recipe_view.dart';

class RecipePage extends StatelessWidget {
  final String recipeId;
  final String previousPageTitle;

  const RecipePage({super.key, required this.recipeId, required this.previousPageTitle});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: 'Recipe',
      // Instead of a body, we pass in slivers.
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RecipeView(
              recipeId: recipeId,
              // Force rebuild by using a unique key that includes timestamp
              key: ValueKey('RecipeView-$recipeId-${DateTime.now().millisecondsSinceEpoch}'),
            ),
          ),
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
              title: 'Edit Recipe', icon: const Icon(CupertinoIcons.folder), onTap: () {
                // Todo
          }
          ),
        ],
        child: const Icon(CupertinoIcons.pencil_circle),
      ),
      automaticallyImplyLeading: true,
      previousPageTitle: previousPageTitle,
      searchEnabled: false,
    );
  }
}


