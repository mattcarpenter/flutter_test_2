import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/pantry_item_form.dart';

void showPantryItemEditorModal(
    BuildContext context, {
      PantryItemEntry? pantryItem, // Null for new item, non-null for editing
      bool isEditing = false,
    }) {
  final pageTitle = isEditing ? 'Edit Pantry Item' : 'New Pantry Item';

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      PantryItemEditorModalPage.build(
        context: bottomSheetContext,
        pantryItem: pantryItem,
        pageTitle: pageTitle,
      ),
    ],
  );
}

class PantryItemEditorModalPage {
  PantryItemEditorModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    PantryItemEntry? pantryItem,
    required String pageTitle,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    // GlobalKey to access the PantryItemForm's state.
    final formKey = GlobalKey<PantryItemFormState>();

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
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
        child: Text(pantryItem == null ? 'Create' : 'Save'),
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