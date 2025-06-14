import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/meal_plan_provider.dart';
import 'meal_plan_item_tile.dart';
import 'meal_plan_context_menu.dart';

class MealPlanDateCard extends ConsumerWidget {
  final DateTime date;
  final String dateString;

  const MealPlanDateCard({
    super.key,
    required this.date,
    required this.dateString,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlanAsync = ref.watch(mealPlanByDateStreamProvider(dateString));
    
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and action buttons
          _buildHeader(context, ref),
          
          // Content area
          mealPlanAsync.when(
            data: (mealPlan) => _buildContent(context, ref, mealPlan),
            loading: () => const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading meal plan: $error',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed.resolveFrom(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
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
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _showAddMenu(context, ref),
            child: const Icon(CupertinoIcons.add_circled, size: 24),
          ),
          
          const SizedBox(width: 8),
          
          // More actions button
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _showMoreMenu(context, ref),
            child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic mealPlan) {
    if (mealPlan?.data == null || (mealPlan!.data as List).isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 48,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(height: 16),
              Text(
                'No meals planned',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add recipes or notes',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 14,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = (mealPlan.data as List).cast();
    items.sort((a, b) => a.position.compareTo(b.position));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: items.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: MealPlanItemTile(
              item: item,
              dateString: dateString,
              onReorder: (reorderedItems) {
                ref.read(mealPlanNotifierProvider.notifier).reorderItems(
                  date: dateString,
                  reorderedItems: reorderedItems,
                  userId: null, // TODO: Pass actual user info
                  householdId: null, // TODO: Pass actual household info
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    MealPlanContextMenu.showAddMenu(
      context: context,
      date: dateString,
      ref: ref,
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    MealPlanContextMenu.showMoreMenu(
      context: context,
      date: dateString,
      ref: ref,
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