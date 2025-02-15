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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheading for recipes.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recipes',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navLargeTitleTextStyle
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          // Recipes grid.
          RecipesList(recipes: dummyRecipes),
        ],
      ),
      trailing: AdaptivePullDownButton(
        child: Icon(CupertinoIcons.add_circled),
        items: [
          AdaptiveMenuItem(
              title: 'Add Folder',
              icon: Icon(CupertinoIcons.folder),
              onTap: () {}),
          AdaptiveMenuItem(
              title: 'Add Recipe',
              icon: Icon(CupertinoIcons.book),
              onTap: () {})
        ],
      ),
      leading: Icon(CupertinoIcons.person_2),
    );
  }
}

