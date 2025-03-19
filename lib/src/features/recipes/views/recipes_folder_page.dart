import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import './add_folder_modal.dart';
import '../widgets/folder_list.dart';
import '../widgets/recipe_list.dart' show RecipesList, dummyRecipes;
import 'add_recipe_modal.dart';

class RecipesFolderPage extends StatelessWidget {
  final String? folderId;
  final String title;
  final String previousPageTitle;

  const RecipesFolderPage({
    super.key,
    this.folderId,
    required this.title,
    required this.previousPageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      slivers: [
        // The recipes grid sliver.
        RecipesList(recipes: dummyRecipes),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
              title: 'Add Recipe', icon: const Icon(CupertinoIcons.book), onTap: () {
                showRecipeEditorModal(context, folderId: folderId);
          })
        ],
        child: const Icon(CupertinoIcons.add_circled),
      ),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}
