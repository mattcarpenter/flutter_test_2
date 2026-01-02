import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../widgets/recipe_search_results.dart';
import '../widgets/welcome_recipe_card.dart';
import 'add_folder_modal.dart';
import 'add_smart_folder_modal.dart';
import '../widgets/folder_list.dart';
import '../widgets/recipe_list.dart';
import '../widgets/pinned_recipes_section.dart';
import '../widgets/recently_viewed_section.dart';
import 'add_recipe_modal.dart';
import 'ai_recipe_generator_modal.dart';
import 'photo_capture_review_modal.dart';
import 'photo_import_modal.dart';
import 'url_import_modal.dart';

class RecipesTab extends ConsumerWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveSliverPage(
      title: context.l10n.recipesTitle,
      searchEnabled: true,
      searchResultsBuilder: (context, query) => RecipeSearchResults(
        onResultSelected: (recipe) async {
          FocusScope.of(context).unfocus();
          context.push('/recipe/${recipe.id}', extra: {
            'previousPageTitle': context.l10n.recipesTitle,
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
                  context.l10n.recipesFolders,
                  style: AppTypography.h2Serif.copyWith(
                    color: AppColors.of(context).headingSecondary,
                  ),
                ),
                AdaptivePullDownButton(
                  items: [
                    AdaptiveMenuItem(
                      title: context.l10n.recipesAddFolder,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedFolder01),
                      onTap: () {
                        showAddFolderModal(context);
                      },
                    ),
                    AdaptiveMenuItem(
                      title: context.l10n.recipesAddSmartFolder,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedAiMagic),
                      onTap: () {
                        showAddSmartFolderModal(context);
                      },
                    ),
                  ],
                  child: const AppCircleButton(
                    icon: AppCircleButtonIcon.plus,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FolderList(currentPageTitle: context.l10n.recipesTitle)
        ),
        // Pinned recipes section
        const SliverToBoxAdapter(
          child: PinnedRecipesSection(),
        ),
        // Recently viewed recipes section
        const SliverToBoxAdapter(
          child: RecentlyViewedSection(),
        ),
        // Welcome card for new users (hidden once they have recipes)
        const SliverToBoxAdapter(
          child: WelcomeRecipeCard(),
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: context.l10n.recipesAddFolder, icon: const HugeIcon(icon: HugeIcons.strokeRoundedFolder01), onTap: () {
              showAddFolderModal(context);
            }
          ),
          AdaptiveMenuItem(
            title: context.l10n.recipesAddSmartFolder,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAiMagic),
            onTap: () {
              showAddSmartFolderModal(context);
            },
          ),
          AdaptiveMenuItem.divider(),
          AdaptiveMenuItem(
            title: context.l10n.recipeEditorNewRecipe,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedBook01),
            onTap: () {
              // Don't pass folderId for uncategorized folder
              showRecipeEditorModal(context, ref: ref, folderId: null);
            },
          ),
          AdaptiveMenuItem(
            title: context.l10n.recipeGenerateWithAi,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01),
            onTap: () {
              showAiRecipeGeneratorModal(context, ref: ref);
            },
          ),
          AdaptiveMenuItem(
            title: context.l10n.recipeImportFromCamera,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01),
            onTap: () {
              showPhotoCaptureReviewModal(context, ref: ref);
            },
          ),
          AdaptiveMenuItem(
            title: context.l10n.recipeImportFromPhotos,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedImage01),
            onTap: () {
              showPhotoImportModal(context, ref: ref, source: ImageSource.gallery);
            },
          ),
          AdaptiveMenuItem(
            title: context.l10n.recipeImportFromUrl,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedLink01),
            onTap: () {
              showUrlImportModal(context, ref: ref);
            },
          ),
        ],
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.ellipsis,
        ),
      ),
      leading: const HugeIcon(icon: HugeIcons.strokeRoundedBook01),
    );
  }
}


