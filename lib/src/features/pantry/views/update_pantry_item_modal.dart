import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../theme/colors.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/pantry_item_form.dart';

void showUpdatePantryItemModal(
    BuildContext context, {
      required PantryItemEntry pantryItem,
    }) {
  const pageTitle = 'Edit Pantry Item';

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      UpdatePantryItemModalPage.build(
        context: bottomSheetContext,
        pantryItem: pantryItem,
        pageTitle: pageTitle,
      ),
    ],
  );
}

class UpdatePantryItemModalPage {
  UpdatePantryItemModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required PantryItemEntry pantryItem,
    required String pageTitle,
  }) {
    // GlobalKey to access the PantryItemForm's state.
    final formKey = GlobalKey<PantryItemFormState>();

    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      // Leading (left) nav bar widget: Cancel button with horizontal padding.
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      // Trailing (right) nav bar widget: Create/Update button with horizontal padding.
      trailingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () async {
          await formKey.currentState?.savePantryItem();
          Navigator.of(context).pop();
        },
        child: const Text('Save'),
      ),
      pageTitle: ModalSheetTitle(pageTitle),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: PantryItemForm(
          key: formKey,
          initialPantryItem: pantryItem,
        ),
      ),
    );
  }
}