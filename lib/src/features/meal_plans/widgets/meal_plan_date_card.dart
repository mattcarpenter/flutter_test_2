import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/meal_plan_provider.dart';
import '../models/meal_plan_drag_data.dart';
import 'meal_plan_date_header.dart';
import 'meal_plan_item_lifted.dart';

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

class _MealPlanDateCardState extends ConsumerState<MealPlanDateCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _borderColorAnimation = ColorTween(
      begin: CupertinoColors.separator,
      end: CupertinoColors.activeBlue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragEnter() {
    if (!_isHovering) {
      setState(() => _isHovering = true);
      _animationController.forward();
    }
  }

  void _onDragLeave() {
    if (_isHovering) {
      setState(() => _isHovering = false);
      _animationController.reverse();
    }
  }

  Future<void> _onDragAccept(MealPlanDragData dragData) async {
    // Reset visual state
    _onDragLeave();

    // Don't accept drops from the same date
    if (dragData.sourceDate == widget.dateString) {
      return;
    }

    // Get current items to determine target index
    final mealPlan = ref.read(mealPlanByDateStreamProvider(widget.dateString)).value;
    final currentItems = mealPlan?.items != null
        ? (mealPlan!.items as List).cast<MealPlanItem>()
        : <MealPlanItem>[];

    // Get current user ID for proper database query
    final userId = ref.read(currentUserProvider)?.id;

    // Move item to this date at the end of the list
    await ref.read(mealPlanNotifierProvider.notifier).moveItemBetweenDates(
      sourceDate: dragData.sourceDate,
      targetDate: widget.dateString,
      item: dragData.item,
      sourceIndex: dragData.sourceIndex,
      targetIndex: currentItems.length, // Add at end
      userId: userId,
      householdId: null, // TODO: Add household support if needed
    );
  }

  bool _willAcceptDrag(MealPlanDragData? dragData) {
    // Only accept drops from different dates
    return dragData != null && dragData.sourceDate != widget.dateString;
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanAsync = ref.watch(mealPlanByDateStreamProvider(widget.dateString));
    
    return DragTarget<MealPlanDragData>(
      onWillAcceptWithDetails: (details) => _willAcceptDrag(details.data),
      onAcceptWithDetails: (details) => _onDragAccept(details.data),
      onMove: (details) => _onDragEnter(),
      onLeave: (_) => _onDragLeave(),
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: _isHovering
                      ? Border.all(
                          color: CupertinoDynamicColor.resolve(_borderColorAnimation.value!, context),
                          width: 2.0,
                        )
                      : null,
                  boxShadow: _isHovering
                      ? [
                          BoxShadow(
                            color: CupertinoColors.activeBlue
                                .resolveFrom(context)
                                .withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date header
                    MealPlanDateHeader(
                      date: widget.date,
                      dateString: widget.dateString,
                      ref: ref,
                    ),
                    
                    // Content area
                    mealPlanAsync.when(
                      data: (mealPlan) => _buildContent(mealPlan),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(dynamic mealPlan) {
    List<MealPlanItem> items = [];
    
    if (mealPlan?.items != null && (mealPlan!.items as List).isNotEmpty) {
      items = (mealPlan.items as List).cast<MealPlanItem>();
      items.sort((a, b) => a.position.compareTo(b.position));
    }
    
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return MealPlanItemLifted(
            key: ValueKey(item.id),
            item: item,
            dateString: widget.dateString,
            index: index,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 32,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No meals planned',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add recipes or notes',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 12,
                color: CupertinoColors.quaternaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}