import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import '../utils/context_menu_utils.dart';

class MealPlanItemTile extends ConsumerStatefulWidget {
  final int index;
  final MealPlanItem item;
  final String dateString;
  final bool isDragging;

  const MealPlanItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.dateString,
    required this.isDragging,
  });

  @override
  ConsumerState<MealPlanItemTile> createState() => _MealPlanItemTileState();
}

class _MealPlanItemTileState extends ConsumerState<MealPlanItemTile> {
  final GlobalKey _dragHandleKey = GlobalKey();

  bool _contextMenuIsAllowed(Offset location) {
    return isLocationOutsideKey(location, _dragHandleKey);
  }

  @override
  Widget build(BuildContext context) {
    return ContextMenuWidget(
      contextMenuIsAllowed: _contextMenuIsAllowed,
      menuProvider: (_) {
        return Menu(
          children: [
            if (widget.item.isRecipe) ...[
              MenuAction(
                title: 'View Recipe',
                image: MenuImage.icon(CupertinoIcons.book),
                callback: () {
                  if (widget.item.recipeId != null) {
                    context.push('/recipes/${widget.item.recipeId}');
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
      },
      child: GestureDetector(
        onTap: () => _handleTap(context, ref),
        child: Stack(
          children: [
            Container(
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
                  
                  // Space for the drag handle
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Position the drag handle on top so it's clickable
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  key: _dragHandleKey,
                  index: widget.index,
                  child: Icon(
                    CupertinoIcons.line_horizontal_3,
                    size: 16,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (widget.item.isRecipe && widget.item.recipeId != null) {
      // Navigate to recipe detail
      context.push('/recipes/${widget.item.recipeId}');
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
      userId: null, // TODO: Pass actual user info
      householdId: null, // TODO: Pass actual household info
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
      return widget.item.noteTitle ?? widget.item.noteText ?? 'Note';
    }
    return 'Unknown Item';
  }

  String? _getDisplaySubtitle() {
    if (widget.item.isNote && widget.item.noteTitle != null && widget.item.noteText != null) {
      return widget.item.noteText;
    }
    return null;
  }
}