import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../widgets/app_circle_button.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import './cook_content.dart';

void showCookModal(BuildContext context, {
  required String cookId,
  required String recipeId,
}) {
  final GlobalKey<CookContentState> contentKey = GlobalKey<CookContentState>();
  
  // Set the initial active cook in our provider
  final container = ProviderScope.containerOf(context);
  container.read(activeCookInModalProvider.notifier).state = cookId;

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          navBarHeight: 55,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          leadingNavBarWidget: Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
          ),
          // Just use a standard Row with proper spacing for the trailing widgets
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: Consumer(
              builder: (context, ref, _) {
                final activeCookId = ref.watch(activeCookInModalProvider);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ingredients button
                    IconButton(
                      icon: const Icon(Icons.food_bank_outlined),
                      tooltip: 'Ingredients',
                      onPressed: () {
                        contentKey.currentState?.showIngredientsSheet();
                      },
                    ),
                    // Overflow menu with Add Recipe and Complete Cook options
                    AdaptivePullDownButton(
                      items: [
                        AdaptiveMenuItem(
                          title: 'Add Recipe',
                          icon: const Icon(CupertinoIcons.add),
                          onTap: () {
                            contentKey.currentState?.showAddRecipeSheet();
                          },
                        ),
                        AdaptiveMenuItem(
                          title: 'Complete Cook',
                          icon: const Icon(CupertinoIcons.checkmark_alt_circle),
                          onTap: () {
                            if (activeCookId != null) {
                              contentKey.currentState?.completeCook();
                            }
                          },
                        ),
                      ],
                      child: const AppCircleButton(
                        icon: AppCircleButtonIcon.ellipsis,
                        variant: AppCircleButtonVariant.neutral,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          child: CookContent(
            key: contentKey, // Use the key to access the state
            initialCookId: cookId,
            initialRecipeId: recipeId,
            modalContext: modalContext,
          ),
        ),
      ];
    },
  );
}
