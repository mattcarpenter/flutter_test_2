import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import '../models/meal_plan_drag_data.dart';

class MealPlanItemWithHandle extends ConsumerWidget {
  final MealPlanItem item;
  final String dateString;
  final int index;

  const MealPlanItemWithHandle({
    super.key,
    required this.item,
    required this.dateString,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
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
            // Main content area with context menu
            Expanded(
              child: ContextMenuWidget(
                menuProvider: (_) => _buildContextMenu(context, ref),
                child: GestureDetector(
                  onTap: () => _handleTap(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.transparent,
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
                          child: Icon(
                            _getItemIcon(),
                            size: 16,
                            color: CupertinoColors.white,
                          ),
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
            
            // Draggable handle area
            Draggable<MealPlanDragData>(
              data: MealPlanDragData(
                item: item,
                sourceDate: dateString,
                sourceIndex: index,
              ),
              dragAnchorStrategy: childDragAnchorStrategy,
              feedback: _buildDragFeedback(context),
              childWhenDragging: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context).withOpacity(0.3),
                ),
              ),
              onDragStarted: () {},
              onDragEnd: (details) {},
              onDraggableCanceled: (velocity, offset) {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.transparent, // Important for hit testing
                child: Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
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
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.activeBlue.resolveFrom(context),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getItemColor(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getItemIcon(),
                size: 16,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
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

  IconData _getItemIcon() {
    switch (item.type) {
      case 'recipe':
        return CupertinoIcons.book;
      case 'note':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.square;
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