import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import 'meal_plan_item_tile.dart';
import 'meal_plan_context_menu.dart';
import '../utils/context_menu_utils.dart';

class MealPlanDateCard extends ConsumerStatefulWidget {
  final DateTime date;
  final String dateString;

  const MealPlanDateCard({
    super.key,
    required this.date,
    required this.dateString,
  });

  @override
  ConsumerState<MealPlanDateCard> createState() => _MealPlanDateCardState();
}

class _MealPlanDateCardState extends ConsumerState<MealPlanDateCard> {
  bool _isDragging = false;
  List<MealPlanItem>? _optimisticItems; // Local state for optimistic updates
  bool _isReordering = false; // Track if we're in the middle of a reorder operation

  // Method to handle drag start
  void _onDragStart() {
    setState(() {
      _isDragging = true;
      // Unfocus any text fields to prevent the leader-follower error
      FocusScope.of(context).unfocus();
    });
  }

  // Method to handle drag end
  void _onDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanAsync = ref.watch(mealPlanByDateStreamProvider(widget.dateString));
    
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
    final isToday = _isToday(widget.date);
    final isTomorrow = _isTomorrow(widget.date);
    
    String displayText;
    if (isToday) {
      displayText = 'Today, ${DateFormat('MMM d').format(widget.date)}';
    } else if (isTomorrow) {
      displayText = 'Tomorrow, ${DateFormat('MMM d').format(widget.date)}';
    } else {
      displayText = DateFormat('EEEE, MMM d').format(widget.date);
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
                    DateFormat('EEEE').format(widget.date),
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
    // Always prefer optimistic items if available, regardless of reordering state
    List<MealPlanItem>? items;
    
    if (_optimisticItems != null) {
      // Use optimistic state when available
      items = _optimisticItems!;
    } else if (mealPlan?.data != null && (mealPlan!.data as List).isNotEmpty) {
      // Use database data when no optimistic state
      items = (mealPlan.data as List).cast<MealPlanItem>();
      items.sort((a, b) => a.position.compareTo(b.position));
    }
    
    if (items == null || items.isEmpty) {
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        proxyDecorator: defaultProxyDecorator,
        onReorderStart: (_) => _onDragStart(),
        onReorderEnd: (_) => _onDragEnd(),
        itemCount: items!.length,
        onReorder: (oldIndex, newIndex) async {
          // Immediately create optimistic state
          final reorderedItems = List<MealPlanItem>.from(items!);
          
          // Handle the index adjustment for moving items down
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          
          // Move the item
          final item = reorderedItems.removeAt(oldIndex);
          reorderedItems.insert(newIndex, item);
          
          // Update positions
          for (int i = 0; i < reorderedItems.length; i++) {
            reorderedItems[i] = reorderedItems[i].copyWith(position: i);
          }
          
          // Set optimistic state immediately
          setState(() {
            _isReordering = true;
            _optimisticItems = reorderedItems;
          });
          
          try {
            // Call the repository to save changes
            await ref.read(mealPlanNotifierProvider.notifier).reorderItems(
              date: widget.dateString,
              reorderedItems: reorderedItems,
              userId: null, // TODO: Pass actual user info
              householdId: null, // TODO: Pass actual household info
            );
            
            // Give the database stream time to update before clearing optimistic state
            await Future.delayed(const Duration(milliseconds: 100));
            
            if (mounted) {
              setState(() {
                _isReordering = false;
                _optimisticItems = null;
              });
            }
          } catch (e) {
            // If the operation fails, clear optimistic state to revert to database data
            if (mounted) {
              setState(() {
                _isReordering = false;
                _optimisticItems = null;
              });
            }
          }
        },
        itemBuilder: (context, index) {
          final item = items![index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            key: ValueKey(item.id),
            child: MealPlanItemTile(
              index: index,
              item: item,
              dateString: widget.dateString,
              isDragging: _isDragging,
            ),
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    MealPlanContextMenu.showAddMenu(
      context: context,
      date: widget.dateString,
      ref: ref,
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    MealPlanContextMenu.showMoreMenu(
      context: context,
      date: widget.dateString,
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