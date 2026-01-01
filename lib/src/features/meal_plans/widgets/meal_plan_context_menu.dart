import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add to Meal Plan'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddRecipeModal(context, date, ref);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedBook01, size: 18),
                SizedBox(width: 8),
                Text('Add Recipe'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddNoteModal(context, date, ref);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedFile01, size: 18),
                SizedBox(width: 8),
                Text('Add Note'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
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
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Meal Plan Actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddToShoppingListModal(context, date, ref);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedShoppingCartAdd01, size: 18),
                SizedBox(width: 8),
                Text('Add to Shopping List'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmClearItems(context, date, ref);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18),
                SizedBox(width: 8),
                Text('Clear Items'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
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
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Clear Items'),
        content: const Text('Are you sure you want to remove all recipes and notes from this day?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(mealPlanNotifierProvider.notifier).clearItems(
                date: date,
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}