import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../providers/meal_plan_provider.dart';
import '../views/add_recipe_to_meal_plan_modal.dart';
import '../views/add_note_to_meal_plan_modal.dart';
import '../views/check_pantry_modal.dart';
import '../views/add_to_shopping_list_modal.dart';

class MealPlanDateHeader extends StatelessWidget {
  final DateTime date;
  final String dateString;
  final WidgetRef ref;

  const MealPlanDateHeader({
    super.key,
    required this.date,
    required this.dateString,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    final isTomorrow = _isTomorrow(date);

    String displayText;
    if (isToday) {
      displayText = 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (isTomorrow) {
      displayText = 'Tomorrow, ${DateFormat('MMM d').format(date)}';
    } else {
      displayText = DateFormat('EEEE, MMM d').format(date);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isToday || isTomorrow) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE').format(date),
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Add button
          AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Add Recipe',
                icon: const Icon(CupertinoIcons.book),
                onTap: () => _showAddRecipeModal(context, dateString, ref),
              ),
              AdaptiveMenuItem(
                title: 'Add Note',
                icon: const Icon(CupertinoIcons.doc_text),
                onTap: () => _showAddNoteModal(context, dateString, ref),
              ),
            ],
            child: const AppCircleButton(
              icon: AppCircleButtonIcon.plus,
              variant: AppCircleButtonVariant.neutral,
            ),
          ),

          const SizedBox(width: 8),

          // More actions button
          AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Check Pantry',
                icon: const Icon(CupertinoIcons.checkmark_seal),
                onTap: () => _showCheckPantryModal(context, dateString, ref),
              ),
              AdaptiveMenuItem(
                title: 'Add to Shopping List',
                icon: const Icon(CupertinoIcons.cart_badge_plus),
                onTap: () => _showAddToShoppingListModal(context, dateString, ref),
              ),
              AdaptiveMenuItem(
                title: 'Clear Items',
                icon: const Icon(CupertinoIcons.clear),
                onTap: () => _confirmClearItems(context, dateString, ref),
                isDestructive: true,
              ),
            ],
            child: const AppCircleButton(
              icon: AppCircleButtonIcon.ellipsis,
              variant: AppCircleButtonVariant.neutral,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for menu actions
  void _showAddRecipeModal(BuildContext context, String date, WidgetRef ref) {
    showAddRecipeToMealPlanModal(context, date);
  }

  void _showAddNoteModal(BuildContext context, String date, WidgetRef ref) {
    showAddNoteToMealPlanModal(context, date);
  }

  void _showCheckPantryModal(BuildContext context, String date, WidgetRef ref) {
    showCheckPantryModal(context, date);
  }

  void _showAddToShoppingListModal(BuildContext context, String date, WidgetRef ref) {
    showAddToShoppingListModal(context, date);
  }

  void _confirmClearItems(BuildContext context, String date, WidgetRef ref) {
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
                userId: null,
                householdId: null,
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
           date.month == tomorrow.month &&
           date.day == tomorrow.day;
  }
}
