import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import '../models/meal_plan_drag_data.dart';

class MealPlanItemDraggableV2 extends ConsumerWidget {
  final MealPlanItem item;
  final String dateString;
  final int index;

  const MealPlanItemDraggableV2({
    super.key,
    required this.item,
    required this.dateString,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          // Main content with context menu
          Expanded(
            child: ContextMenuWidget(
              menuProvider: (_) => _buildContextMenu(context, ref),
              child: GestureDetector(
                onTap: () => _handleTap(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon based on type
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getItemColor(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _getItemIcon(),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisplayTitle(),
                              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_getDisplaySubtitle() != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getDisplaySubtitle()!,
                                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Separate drag handle
          LongPressDraggable<MealPlanDragData>(
            data: MealPlanDragData(
              item: item,
              sourceDate: dateString,
              sourceIndex: index,
            ),
            feedback: _buildDragFeedback(context),
            childWhenDragging: HugeIcon(
              icon: HugeIcons.strokeRoundedDragDropVertical,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context).withOpacity(0.3),
            ),
            delay: Duration.zero, // Remove delay for testing
            hapticFeedbackOnStart: true,
            onDragStarted: () => print('Drag started for ${item.id}'),
            onDragEnd: (details) => print('Drag ended at ${details.offset}'),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedDragDropVertical,
                size: 16,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the context menu
  Menu _buildContextMenu(BuildContext context, WidgetRef ref) {
    return Menu(
      children: [
        if (item.isRecipe) ...[
          MenuAction(
            title: 'View Recipe',
            image: MenuImage.icon(CupertinoIcons.book),
            callback: () {
              if (item.recipeId != null) {
                context.push('/recipe/${item.recipeId}');
              }
            },
          ),
        ],
        if (item.isNote) ...[
          MenuAction(
            title: 'Edit Note',
            image: MenuImage.icon(CupertinoIcons.pencil),
            callback: () {
              _editNote(context, ref);
            },
          ),
        ],
        MenuAction(
          title: 'Remove',
          image: MenuImage.icon(CupertinoIcons.delete),
          attributes: const MenuActionAttributes(destructive: true),
          callback: () {
            _removeItem(ref);
          },
        ),
      ],
    );
  }
  
  // Build drag feedback widget
  Widget _buildDragFeedback(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.activeBlue.resolveFrom(context),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getItemColor(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _getItemIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getDisplayTitle(),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (item.isRecipe && item.recipeId != null) {
      context.push('/recipe/${item.recipeId}');
    } else if (item.isNote) {
      _editNote(context, ref);
    }
  }

  void _editNote(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Note'),
        content: const Text('Note editing will be implemented'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _removeItem(WidgetRef ref) {
    ref.read(mealPlanNotifierProvider.notifier).removeItem(
      date: dateString,
      itemId: item.id,
    );
  }

  Widget _getItemIcon() {
    switch (item.type) {
      case 'recipe':
        return HugeIcon(
          icon: HugeIcons.strokeRoundedBook01,
          size: 16,
          color: CupertinoColors.white,
        );
      case 'note':
        return HugeIcon(
          icon: HugeIcons.strokeRoundedFile01,
          size: 16,
          color: CupertinoColors.white,
        );
      default:
        return const Icon(
          CupertinoIcons.square,
          size: 16,
          color: CupertinoColors.white,
        );
    }
  }

  Color _getItemColor(BuildContext context) {
    switch (item.type) {
      case 'recipe':
        return CupertinoColors.activeBlue;
      case 'note':
        return CupertinoColors.activeOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _getDisplayTitle() {
    if (item.isRecipe) {
      return item.recipeTitle ?? 'Unknown Recipe';
    } else if (item.isNote) {
      return item.noteText ?? 'Note';
    }
    return 'Unknown Item';
  }

  String? _getDisplaySubtitle() {
    // Notes no longer have subtitles - noteText is displayed as title
    return null;
  }
}