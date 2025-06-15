import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../widgets/meal_plan_date_header.dart';
import '../widgets/meal_plan_item_draggable.dart';

class MealPlansRoot extends ConsumerStatefulWidget {
  const MealPlansRoot({super.key});

  @override
  ConsumerState<MealPlansRoot> createState() => _MealPlansRootState();
}

class _MealPlansRootState extends ConsumerState<MealPlansRoot> {
  final ScrollController _scrollController = ScrollController();
  
  // No local state - let drag_and_drop_lists handle everything
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more dates when near the end
      final currentDays = ref.read(loadedDateRangeProvider);
      ref.read(loadedDateRangeProvider.notifier).state = currentDays + 30;
    }
  }

  // Build drag and drop lists from date data
  List<DragAndDropList> _buildDragAndDropLists() {
    final dates = ref.watch(extendedMealPlanDatesProvider);
    final lists = <DragAndDropList>[];
    
    for (int i = 0; i < dates.length; i++) {
      final dateString = dates[i];
      final date = DateTime.parse(dateString);
      
      // Always use provider data - no local state management
      final mealPlan = ref.watch(mealPlanByDateStreamProvider(dateString)).value;
      List<MealPlanItem> items;
      if (mealPlan?.data != null && (mealPlan!.data as List).isNotEmpty) {
        items = (mealPlan.data as List).cast<MealPlanItem>();
        items.sort((a, b) => a.position.compareTo(b.position));
      } else {
        items = [];
      }
      
      lists.add(
        DragAndDropList(
          header: MealPlanDateHeader(
            date: date,
            dateString: dateString,
            ref: ref,
          ),
          children: _buildItemsForDate(items, dateString),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          canDrag: false, // We don't want to reorder dates
        ),
      );
    }
    
    return lists;
  }
  
  // Build items for a specific date
  List<DragAndDropItem> _buildItemsForDate(List<MealPlanItem> items, String dateString) {
    if (items.isEmpty) {
      return [_buildEmptyPlaceholder(dateString)];
    }
    
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return DragAndDropItem(
        child: MealPlanItemDraggable(
          item: item,
          dateString: dateString,
          index: index,
        ),
        canDrag: true,
      );
    }).toList();
  }
  
  // Empty state placeholder with height matching item tiles (padding + container + content)
  DragAndDropItem _buildEmptyPlaceholder(String dateString) {
    return DragAndDropItem(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Match item padding
        child: Container(
          height: 56, // Fixed height: 12 (padding) + 32 (icon height) + 12 (padding) = 56
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              'No meals planned - tap + to add',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ),
      ),
      canDrag: false,
    );
  }
  
  // Handle item reorder - persist changes directly to database
  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) async {
    final dates = ref.read(extendedMealPlanDatesProvider);
    final sourceDate = dates[oldListIndex];
    final targetDate = dates[newListIndex];
    
    // Get current items from providers
    final sourceMealPlan = ref.read(mealPlanByDateStreamProvider(sourceDate)).value;
    final targetMealPlan = ref.read(mealPlanByDateStreamProvider(targetDate)).value;
    
    final sourceItems = sourceMealPlan?.data != null 
        ? List<MealPlanItem>.from(sourceMealPlan!.data as List)
        : <MealPlanItem>[];
    
    if (oldItemIndex >= sourceItems.length) return;
    
    final item = sourceItems[oldItemIndex];
    
    if (sourceDate == targetDate) {
      // Within same date - use reorderItems
      sourceItems.removeAt(oldItemIndex);
      if (oldItemIndex < newItemIndex) {
        newItemIndex -= 1;
      }
      sourceItems.insert(newItemIndex, item);
      
      // Update positions
      for (int i = 0; i < sourceItems.length; i++) {
        sourceItems[i] = sourceItems[i].copyWith(position: i);
      }
      
      await ref.read(mealPlanNotifierProvider.notifier).reorderItems(
        date: sourceDate,
        reorderedItems: sourceItems,
        userId: null,
        householdId: null,
      );
    } else {
      // Between different dates - use moveItemBetweenDates
      await ref.read(mealPlanNotifierProvider.notifier).moveItemBetweenDates(
        sourceDate: sourceDate,
        targetDate: targetDate,
        item: item,
        sourceIndex: oldItemIndex,
        targetIndex: newItemIndex,
        userId: null,
        householdId: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dragLists = _buildDragAndDropLists();
    
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Meal Plans'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DragAndDropLists(
            children: dragLists,
            onItemReorder: _onItemReorder,
            onListReorder: (oldListIndex, newListIndex) {
              // We don't allow list reordering (dates are fixed)
            },
            itemDragHandle: DragHandle(
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                size: 16,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
            listDragOnLongPress: false,
            itemDragOnLongPress: false, // Use drag handle instead
            scrollController: _scrollController,
            listPadding: const EdgeInsets.only(bottom: 16.0),
            listGhost: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                  width: 2,
                ),
              ),
              child: const SizedBox(height: 60),
            ),
            itemGhost: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                  width: 1,
                ),
              ),
              child: const SizedBox(height: 44),
            ),
          ),
        ),
      ),
    );
  }
}
