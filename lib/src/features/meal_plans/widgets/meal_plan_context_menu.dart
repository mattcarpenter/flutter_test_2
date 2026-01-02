import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../localization/l10n_extension.dart';
import '../../../providers/meal_plan_provider.dart';
import '../views/add_recipe_to_meal_plan_modal.dart';
import '../views/add_note_to_meal_plan_modal.dart';
import '../views/add_to_shopping_list_modal.dart';

class MealPlanContextMenu {
  // Show the "+" add menu
  static void showAddMenu({
    required BuildContext context,
    required String date,
    required WidgetRef ref,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(context.l10n.mealPlanAddToMealPlanTitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showAddRecipeModal(context, date, ref);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedBook01, size: 18),
                SizedBox(width: 8),
                Text(context.l10n.mealPlanAddRecipe),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showAddNoteModal(context, date, ref);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedFile01, size: 18),
                SizedBox(width: 8),
                Text(context.l10n.mealPlanAddNote),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(context.l10n.commonCancel),
          onPressed: () => Navigator.pop(sheetContext),
        ),
      ),
    );
  }

  // Show the "..." more actions menu
  static void showMoreMenu({
    required BuildContext context,
    required String date,
    required WidgetRef ref,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(context.l10n.mealPlanActionsTitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showAddToShoppingListModal(context, date, ref);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedShoppingCartAdd01, size: 18),
                SizedBox(width: 8),
                Text(context.l10n.recipeAddToShoppingList),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(sheetContext);
              _confirmClearItems(context, date, ref);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18),
                SizedBox(width: 8),
                Text(context.l10n.mealPlanClearItems),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(context.l10n.commonCancel),
          onPressed: () => Navigator.pop(sheetContext),
        ),
      ),
    );
  }

  static void _showAddRecipeModal(BuildContext context, String date, WidgetRef ref) {
    showAddRecipeToMealPlanModal(context, date);
  }

  static void _showAddNoteModal(BuildContext context, String date, WidgetRef ref) {
    showAddNoteToMealPlanModal(context, date);
  }

  static void _showAddToShoppingListModal(BuildContext context, String date, WidgetRef ref) {
    showAddToShoppingListModal(context, date);
  }

  static void _confirmClearItems(BuildContext context, String date, WidgetRef ref) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.mealPlanClearItems),
        content: Text(context.l10n.mealPlanClearItemsConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.commonCancel),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(mealPlanNotifierProvider.notifier).clearItems(
                date: date,
              );
            },
            child: Text(context.l10n.commonClear),
          ),
        ],
      ),
    );
  }
}