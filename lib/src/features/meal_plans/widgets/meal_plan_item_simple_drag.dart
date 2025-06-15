import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import '../models/meal_plan_drag_data.dart';

class MealPlanItemSimpleDrag extends ConsumerWidget {
  final MealPlanItem item;
  final String dateString;
  final int index;

  const MealPlanItemSimpleDrag({
    super.key,
    required this.item,
    required this.dateString,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the entire tile as draggable
    return Draggable<MealPlanDragData>(
      // Try regular Draggable instead of LongPressDraggable
      data: MealPlanDragData(
        item: item,
        sourceDate: dateString,
        sourceIndex: index,
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Container(
        width: 200,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getDisplayTitle(),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTile(context, ref),
      ),
      child: _buildTile(context, ref),
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref) {
    return GestureDetector(
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
              
              // Drag handle visual indicator
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
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (item.isRecipe && item.recipeId != null) {
      context.push('/recipes/${item.recipeId}');
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
      return item.noteTitle ?? item.noteText ?? 'Note';
    }
    return 'Unknown Item';
  }

  String? _getDisplaySubtitle() {
    if (item.isNote && item.noteTitle != null && item.noteText != null) {
      return item.noteText;
    }
    return null;
  }
}