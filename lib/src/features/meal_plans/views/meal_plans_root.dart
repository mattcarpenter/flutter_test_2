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
  
  // Local state to maintain stable drag behavior
  Map<String, List<MealPlanItem>> _localData = {};
  bool _isDragging = false;
  
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
      
      // Use local data during drag, otherwise use provider data
      List<MealPlanItem> items;
      if (_isDragging && _localData.containsKey(dateString)) {
        items = _localData[dateString]!;
      } else {
        final mealPlan = ref.watch(mealPlanByDateStreamProvider(dateString)).value;
        if (mealPlan?.data != null && (mealPlan!.data as List).isNotEmpty) {
          items = (mealPlan.data as List).cast<MealPlanItem>();
          items.sort((a, b) => a.position.compareTo(b.position));
        } else {
          items = [];
        }
        // Update local data
        _localData[dateString] = List.from(items);
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
      // During drag operations, show a minimal placeholder to maintain consistent height
      if (_isDragging) {
        return [_buildDragPlaceholder()];
      } else {
        return [_buildEmptyPlaceholder(dateString)];
      }
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
  
  // Minimal placeholder during drag operations to maintain consistent height
  DragAndDropItem _buildDragPlaceholder() {
    return DragAndDropItem(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: Text(
            'Drop here to add',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ),
      canDrag: false,
    );
  }

  // Empty state placeholder
  DragAndDropItem _buildEmptyPlaceholder(String dateString) {
    return DragAndDropItem(
      child: Padding(
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
      ),
      canDrag: false,
    );
  }
  
  // Handle item reorder - update local state immediately for smooth UX
  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      _isDragging = true;
      
      final dates = ref.read(extendedMealPlanDatesProvider);
      final sourceDate = dates[oldListIndex];
      final targetDate = dates[newListIndex];
      
      // Get items from local data
      final sourceItems = List<MealPlanItem>.from(_localData[sourceDate] ?? []);
      final targetItems = List<MealPlanItem>.from(_localData[targetDate] ?? []);
      
      if (oldItemIndex >= sourceItems.length) return;
      
      // Remove item from source
      final item = sourceItems.removeAt(oldItemIndex);
      
      if (sourceDate == targetDate) {
        // Within same list - adjust index if needed
        if (oldItemIndex < newItemIndex) {
          newItemIndex -= 1;
        }
        sourceItems.insert(newItemIndex, item);
        
        // Update positions
        for (int i = 0; i < sourceItems.length; i++) {
          sourceItems[i] = sourceItems[i].copyWith(position: i);
        }
        
        _localData[sourceDate] = sourceItems;
      } else {
        // Between different lists
        targetItems.insert(newItemIndex, item);
        
        // Update positions in both lists
        for (int i = 0; i < sourceItems.length; i++) {
          sourceItems[i] = sourceItems[i].copyWith(position: i);
        }
        for (int i = 0; i < targetItems.length; i++) {
          targetItems[i] = targetItems[i].copyWith(position: i);
        }
        
        _localData[sourceDate] = sourceItems;
        _localData[targetDate] = targetItems;
      }
    });
    
    // Persist changes to database after a short delay
    Future.delayed(const Duration(milliseconds: 500), () async {
      await _persistChanges();
      if (mounted) {
        setState(() {
          _isDragging = false;
        });
      }
    });
  }
  
  // Persist local changes to database
  Future<void> _persistChanges() async {
    try {
      for (final entry in _localData.entries) {
        final dateString = entry.key;
        final items = entry.value;
        
        if (items.isEmpty) {
          await ref.read(mealPlanNotifierProvider.notifier).clearItems(
            date: dateString,
            userId: null,
            householdId: null,
          );
        } else {
          await ref.read(mealPlanNotifierProvider.notifier).reorderItems(
            date: dateString,
            reorderedItems: items,
            userId: null,
            householdId: null,
          );
        }
      }
    } catch (e) {
      // If persistence fails, clear local data to revert to database state
      _localData.clear();
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
