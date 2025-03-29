import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import './cook_content.dart';

void showCookModal(BuildContext context, {
  required String cookId,
  required String recipeId,
}) {
  final GlobalKey<CookContentState> contentKey = GlobalKey<CookContentState>();

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
          trailingNavBarWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ingredients button
              IconButton(
                icon: const Icon(Icons.food_bank_outlined),
                tooltip: 'Ingredients',
                onPressed: () {
                  // Use the key to access the content state
                  contentKey.currentState?.showIngredientsSheet();
                },
              ),
              // Finish button
              TextButton(
                onPressed: () {
                  // Use the key to access the content state
                  contentKey.currentState?.showFinishDialog();
                },
                child: const Text('Finish'),
              ),
            ],
          ),
          child: CookContent(
            key: contentKey, // Use the key to access the state
            cookId: cookId,
            recipeId: recipeId,
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
