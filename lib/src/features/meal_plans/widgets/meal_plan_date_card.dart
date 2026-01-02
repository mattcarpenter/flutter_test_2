import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../localization/l10n_extension.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../theme/colors.dart';
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
  final Set<String> _deletingItemIds = {}; // Track items being deleted

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
      end: AppColorSwatches.primary[300],
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

  Color _getGradientColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? AppColorSwatches.neutral[925]! : CupertinoColors.white;
  }

  Color _getHoverColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? AppColorSwatches.neutral[800]! : AppColorSwatches.primary[25]!;
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

    // NOTE: We intentionally do NOT clear the drag state here.
    // The drag state now includes sourceDate, so:
    // - Source location stays invisible (ghost) during the async move operation
    // - Target location shows the item normally (different date, so not ghosted)
    // This prevents the "flash" where the item briefly appears at source before being removed.

    // Get current items to determine target index
    final mealPlan = ref.read(mealPlanByDateStreamProvider(widget.dateString)).value;
    final currentItems = mealPlan?.items != null
        ? (mealPlan!.items as List).cast<MealPlanItem>()
        : <MealPlanItem>[];

    // Move item to this date at the end of the list
    await ref.read(mealPlanNotifierProvider.notifier).moveItemBetweenDates(
      sourceDate: dragData.sourceDate,
      targetDate: widget.dateString,
      item: dragData.item,
      sourceIndex: dragData.sourceIndex,
      targetIndex: currentItems.length, // Add at end
    );

    // Clear drag state after move completes
    // At this point, the item has been removed from source data, so clearing is safe
    ref.read(mealPlanDraggingItemProvider.notifier).state = null;
  }

  bool _willAcceptDrag(MealPlanDragData? dragData) {
    // Only accept drops from different dates
    return dragData != null && dragData.sourceDate != widget.dateString;
  }

  // Handle item deletion with animation
  void _handleItemDeletion(String itemId) {
    // Mark item as deleting (triggers fade out)
    setState(() {
      _deletingItemIds.add(itemId);
    });

    // Wait for fade animation to complete, then actually remove
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _deletingItemIds.contains(itemId)) {
        // Actually remove the item from database
        ref.read(mealPlanNotifierProvider.notifier).removeItem(
          date: widget.dateString,
          itemId: itemId,
        );

        // Clear from deleting set after removal
        setState(() {
          _deletingItemIds.remove(itemId);
        });
      }
    });
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
                  gradient: _isHovering
                      ? null
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getGradientColor(context).withOpacity(0.5),
                            _getGradientColor(context).withOpacity(0.5),
                            _getGradientColor(context).withOpacity(0.0),
                            _getGradientColor(context).withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.15, 0.45, 1.0],
                        ),
                  color: _isHovering
                      ? _getHoverColor(context)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: _isHovering
                      ? Border.all(
                          color: _borderColorAnimation.value!,
                          width: 1.0,
                        )
                      : null,
                  boxShadow: _isHovering
                      ? [
                          BoxShadow(
                            color: AppColorSwatches.primary[500]!
                                .withOpacity(0.15),
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
                          context.l10n.mealPlanErrorLoading(error.toString()),
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
          final isDeleting = _deletingItemIds.contains(item.id);

          return AnimatedSize(
            key: ValueKey('${item.id}_size'),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              key: ValueKey('${item.id}_opacity'),
              opacity: isDeleting ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: MealPlanItemLifted(
                key: ValueKey(item.id),
                item: item,
                dateString: widget.dateString,
                index: index,
                onDelete: () => _handleItemDeletion(item.id),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendarAdd01,
              size: 32,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.mealPlanNoMealsPlanned,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.mealPlanTapToAdd,
              style: TextStyle(
                fontSize: 12,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
