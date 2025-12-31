import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import '../models/meal_plan_drag_data.dart';

class MealPlanItemDraggable extends ConsumerStatefulWidget {
  final MealPlanItem item;
  final String dateString;
  final int index;

  const MealPlanItemDraggable({
    super.key,
    required this.item,
    required this.dateString,
    required this.index,
  });

  @override
  ConsumerState<MealPlanItemDraggable> createState() => _MealPlanItemDraggableState();
}

class _MealPlanItemDraggableState extends ConsumerState<MealPlanItemDraggable> {

  @override
  Widget build(BuildContext context) {
    return Draggable<MealPlanDragData>(
      data: MealPlanDragData(
        item: widget.item,
        sourceDate: widget.dateString,
        sourceIndex: widget.index,
      ),
      feedback: _buildDragFeedback(context),
      childWhenDragging: _buildChildWhenDragging(context),
      dragAnchorStrategy: pointerDragAnchorStrategy, // Important for mobile
      maxSimultaneousDrags: 1,
      onDragStarted: () => print('Drag started for ${widget.item.id}'),
      onDragEnd: (details) => print('Drag ended at ${details.offset}'),
      onDraggableCanceled: (velocity, offset) => print('Drag canceled at $offset'),
      child: ContextMenuWidget(
        menuProvider: (_) => _buildContextMenu(),
        child: GestureDetector(
          onTap: () => _handleTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                  
                  // Drag handle
                  Icon(
                    CupertinoIcons.line_horizontal_3,
                    size: 16,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                  
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Build the context menu
  Menu _buildContextMenu() {
    return Menu(
      children: [
        if (widget.item.isRecipe) ...[
          MenuAction(
            title: 'View Recipe',
            image: MenuImage.icon(CupertinoIcons.book),
            callback: () {
              if (widget.item.recipeId != null) {
                context.push('/recipe/${widget.item.recipeId}');
              }
            },
          ),
        ],
        if (widget.item.isNote) ...[
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
        width: 280, // Fixed width for feedback
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
              child: Icon(
                _getItemIcon(),
                size: 16,
                color: CupertinoColors.white,
              ),
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
  
  // Build placeholder when dragging
  Widget _buildChildWhenDragging(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getItemColor(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 24), // Space for drag handle
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (widget.item.isRecipe && widget.item.recipeId != null) {
      // Navigate to recipe detail
      context.push('/recipe/${widget.item.recipeId}');
    } else if (widget.item.isNote) {
      // Show edit note modal
      _editNote(context, ref);
    }
  }

  void _editNote(BuildContext context, WidgetRef ref) {
    // This will be implemented when we create the note modal
    // For now, just show a placeholder
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
      date: widget.dateString,
      itemId: widget.item.id,
    );
  }

  IconData _getItemIcon() {
    switch (widget.item.type) {
      case 'recipe':
        return CupertinoIcons.book;
      case 'note':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.square;
    }
  }

  Color _getItemColor(BuildContext context) {
    switch (widget.item.type) {
      case 'recipe':
        return CupertinoColors.activeBlue;
      case 'note':
        return CupertinoColors.activeOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _getDisplayTitle() {
    if (widget.item.isRecipe) {
      return widget.item.recipeTitle ?? 'Unknown Recipe';
    } else if (widget.item.isNote) {
      return widget.item.noteText ?? 'Note';
    }
    return 'Unknown Item';
  }

  String? _getDisplaySubtitle() {
    // Notes no longer have subtitles - noteText is displayed as title
    return null;
  }
}