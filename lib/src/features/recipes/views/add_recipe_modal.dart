import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../widgets/recipe_editor_form/recipe_editor_form.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../theme/colors.dart';

void showRecipeEditorModal(
    BuildContext context, {
      RecipeEntry? recipe, // Null for new recipe, non-null for editing
      bool isEditing = false,
      String? folderId
    }) {
  final pageTitle = isEditing ? 'Edit Recipe' : 'New Recipe';

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      RecipeEditorModalPage.build(
        context: bottomSheetContext, // using bottom sheet context
        recipe: recipe,
        pageTitle: pageTitle,
        folderId: folderId
      ),
    ],
  );
}

class RecipeEditorModalPage {
  RecipeEditorModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    RecipeEntry? recipe,
    required String pageTitle,
    String? folderId,
  }) {
    final colors = AppColors.of(context);

    // GlobalKey to access the RecipeEditorForm's state.
    final formKey = GlobalKey<RecipeEditorFormState>();

    return WoltModalSheetPage(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
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
          await formKey.currentState?.saveRecipe();
          Navigator.of(context).pop();
        },
        child: Text(recipe == null ? 'Create' : 'Update'),
      ),
      pageTitle: ModalSheetTitle(pageTitle),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: RecipeEditorForm(
          key: formKey,
          initialRecipe: recipe,
          folderId: folderId
          // onSave is handled by the nav bar button.
        ),
      ),
    );
  }
}
