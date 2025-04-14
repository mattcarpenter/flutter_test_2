import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
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
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          // Just use a standard Row with proper spacing for the trailing widgets
          trailingNavBarWidget: Consumer(
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
                  // Finish button (only finishes the current active cook)
                  TextButton(
                    onPressed: () {
                      if (activeCookId != null) {
                        contentKey.currentState?.showFinishDialog();
                      }
                    },
                    child: const Text('Finish'),
                  ),
                ],
              );
            },
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
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}
