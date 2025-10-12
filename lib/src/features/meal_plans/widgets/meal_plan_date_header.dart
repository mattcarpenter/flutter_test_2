import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_circle_button.dart';
import 'meal_plan_context_menu.dart';

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
        color: CupertinoColors.systemBackground.resolveFrom(context),
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
          AppCircleButton(
            icon: AppCircleButtonIcon.plus,
            onPressed: () => _showAddMenu(context, ref),
          ),

          const SizedBox(width: 8),

          // More actions button
          AppCircleButton(
            icon: AppCircleButtonIcon.ellipsis,
            onPressed: () => _showMoreMenu(context, ref),
          ),
        ],
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