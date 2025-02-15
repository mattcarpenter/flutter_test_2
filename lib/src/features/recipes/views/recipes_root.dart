import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/folder_list.dart';
import '../widgets/recipe_list.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: 'Recipes',
      // Instead of a body, we pass in slivers.
      slivers: [
        // Header as a sliver.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recipes',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navLargeTitleTextStyle
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // The recipes grid sliver.
        RecipesList(recipes: dummyRecipes),
      ],
      trailing: AdaptivePullDownButton(
        child: const Icon(CupertinoIcons.add_circled),
        items: [
          AdaptiveMenuItem(
              title: 'Add Folder', icon: const Icon(CupertinoIcons.folder), onTap: () {}),
          AdaptiveMenuItem(
              title: 'Add Recipe', icon: const Icon(CupertinoIcons.book), onTap: () {})
        ],
      ),
      leading: const Icon(CupertinoIcons.person_2),
    );
  }
}


