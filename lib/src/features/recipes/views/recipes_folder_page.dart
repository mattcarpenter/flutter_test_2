import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import './add_folder_modal.dart';
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Folders',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navLargeTitleTextStyle
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SliverToBoxAdapter(
            child: FolderList(
              parentId: parentId,
              currentPageTitle: title,
            ),
        ),
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
        items: [
          AdaptiveMenuItem(
              title: 'Add Folder', icon: const Icon(CupertinoIcons.folder), onTap: () {
            showAddFolderModal(context, parentId: parentId);
          }
          ),
          AdaptiveMenuItem(
              title: 'Add Recipe', icon: const Icon(CupertinoIcons.book), onTap: () {})
        ],
        child: const Icon(CupertinoIcons.add_circled),
      ),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}
