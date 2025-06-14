import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';

class MealPlanItemTile extends ConsumerWidget {
  final MealPlanItem item;
  final String dateString;
  final Function(List<MealPlanItem>) onReorder;

  const MealPlanItemTile({
    super.key,
    required this.item,
    required this.dateString,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      onLongPress: () => _showItemOptions(context, ref),
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
            
            // Drag handle (for reordering)
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.line_horizontal_3,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (item.isRecipe && item.recipeId != null) {
      // Navigate to recipe detail
      context.push('/recipes/${item.recipeId}');
    } else if (item.isNote) {
      // Show edit note modal
      _editNote(context, ref);
    }
  }

  void _showItemOptions(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(_getDisplayTitle()),
        actions: [
          if (item.isRecipe) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                if (item.recipeId != null) {
                  context.push('/recipes/${item.recipeId}');
                }
              },
              child: const Text('View Recipe'),
            ),
          ],
          if (item.isNote) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editNote(context, ref);
              },
              child: const Text('Edit Note'),
            ),
          ],
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _removeItem(ref);
            },
            child: const Text('Remove'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
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
      date: dateString,
      itemId: item.id,
      userId: null, // TODO: Pass actual user info
      householdId: null, // TODO: Pass actual household info
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