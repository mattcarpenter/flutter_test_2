import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/folder_list.dart';
import '../widgets/recipe_list.dart' show RecipesList, dummyRecipes;

class RecipesFolderPage extends StatelessWidget {
  final String? parentId;
  final String title;
  final String previousPageTitle;

  const RecipesFolderPage({
    Key? key,
    this.parentId,
    required this.title,
    required this.previousPageTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Folders',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w400)
              ),
            ),
            // Folders list at the top.
            FolderList(
              parentId: parentId,
              currentPageTitle: title,
            ),
            const SizedBox(height: 16),
            // Subheading for recipes.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recipes',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 8),
            // Recipes grid.
            RecipesList(recipes: dummyRecipes),
          ],
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}
