import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/folder_list.dart';
import '../widgets/recipe_list.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the "root" content for `/shopping`.
    // No nested Navigator needed—go_router handles sub-routes:
    return AdaptiveSliverPage(
      title: 'Recipes',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Folders',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w400)
              ),
            ),
            FolderList(currentPageTitle: 'Recipes'),
            const SizedBox(height: 16),
            // Subheading for recipes.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recipes',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w400)
              ),
            ),
            // Recipes grid.
            RecipesList(recipes: dummyRecipes),
          ]
        )
      ),
      trailing: Icon(CupertinoIcons.add_circled),
      leading: Icon(CupertinoIcons.person_2),
    );
  }
}
