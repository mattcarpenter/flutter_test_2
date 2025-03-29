import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import './cook_content.dart';

void showCookModal(BuildContext context, {
  required String cookId,
  required String recipeId,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    //modalTypeBuilder: (_) => WoltModalType.bottomSheet,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          leadingNavBarWidget: GestureDetector(
            onTap: () => Navigator.of(modalContext).pop(),
            child: const Icon(Icons.close),
          ),
          child: CookContent(
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
