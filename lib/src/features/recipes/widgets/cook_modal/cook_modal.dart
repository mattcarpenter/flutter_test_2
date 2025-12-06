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
  final container = ProviderScope.containerOf(context);

  // Check if modal is already open - just switch to the new cook
  if (container.read(isCookModalOpenProvider)) {
    container.read(activeCookInModalProvider.notifier).state = cookId;
    return;
  }

  final GlobalKey<CookContentState> contentKey = GlobalKey<CookContentState>();

  // Mark modal as open and set the active cook
  container.read(isCookModalOpenProvider.notifier).state = true;
  container.read(activeCookInModalProvider.notifier).state = cookId;

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
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
              size: 32,
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
                    AppCircleButton(
                      icon: AppCircleButtonIcon.list,
                      variant: AppCircleButtonVariant.neutral,
                      size: 32,
                      onPressed: () {
                        contentKey.currentState?.showIngredientsSheet();
                      },
                    ),
                    SizedBox(width: AppSpacing.sm),
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
                        size: 32,
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
  ).whenComplete(() {
    // Reset state when modal closes (covers all dismissal methods)
    container.read(isCookModalOpenProvider.notifier).state = false;
    container.read(activeCookInModalProvider.notifier).state = null;
  });
}
