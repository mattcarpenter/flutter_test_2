import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../widgets/recipe_search_results.dart';
import 'add_folder_modal.dart';
import '../widgets/folder_list.dart';
import '../widgets/recipe_list.dart';
import '../widgets/pinned_recipes_section.dart';
import '../widgets/recently_viewed_section.dart';
import 'add_recipe_modal.dart';

class RecipesTab extends ConsumerWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveSliverPage(
      title: 'Recipes',
      searchEnabled: true,
      searchResultsBuilder: (context, query) => RecipeSearchResults(
        onResultSelected: (recipe) async {
          FocusScope.of(context).unfocus();
          context.push('/recipes/recipe/${recipe.id}', extra: {
            'previousPageTitle': 'Recipes',
          });
        },
      ),
      onSearchChanged: (query) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(recipeSearchNotifierProvider.notifier).search(query);
        });
      },
      // Instead of a body, we pass in slivers.
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Consistent top spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recipe Folders',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                AppCircleButton(
                  icon: AppCircleButtonIcon.plus,
                  onPressed: () {
                    showAddFolderModal(context);
                  },
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: FolderList(currentPageTitle: 'Recipes')
        ),
        // Pinned recipes section
        const SliverToBoxAdapter(
          child: PinnedRecipesSection(),
        ),
        // Recently viewed recipes section  
        const SliverToBoxAdapter(
          child: RecentlyViewedSection(),
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Add Folder', icon: const Icon(CupertinoIcons.folder), onTap: () {
              showAddFolderModal(context);
            }
          ),
          AdaptiveMenuItem(
            title: 'Add Recipe',
            icon: const Icon(CupertinoIcons.book),
            onTap: () {
              // Don't pass folderId for uncategorized folder
              showRecipeEditorModal(context, folderId: null);
            },
          )
        ],
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.ellipsis,
        ),
      ),
      leading: const Icon(CupertinoIcons.person_2),
    );
  }
}


