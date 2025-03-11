import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../../../widgets/wolt/button/wolt_modal_sheet_close_button.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/recipe_editor_form.dart';

void showRecipeEditorModal(
    BuildContext context, {
      RecipeEntry? recipe, // Null for new recipe, non-null for editing
      bool isEditing = false,
    }) {
  final pageTitle = isEditing ? 'Edit Recipe' : 'New Recipe';

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      RecipeEditorModalPage.build(
        context: context,
        recipe: recipe,
        pageTitle: pageTitle,
      ),
    ],
    // Note: We're not using modalTypeBuilder or maxDialogWidth since they're not supported
  );
}

class RecipeEditorModalPage {
  RecipeEditorModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    RecipeEntry? recipe,
    required String pageTitle,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      trailingNavBarWidget: const WoltModalSheetCloseButton(), // Using trailingNavBarWidget instead of topBarLayerItems
      pageTitle: ModalSheetTitle(pageTitle),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: RecipeEditorForm(
          initialRecipe: recipe,
          autoSave: true,
          onSave: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      stickyActionBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel button closes modal
            Expanded(
              child: WoltElevatedButton(
                theme: WoltElevatedButtonTheme.secondary,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                enabled: true,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            // Done button also closes modal (changes are auto-saved)
            Expanded(
              child: WoltElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                enabled: true,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
