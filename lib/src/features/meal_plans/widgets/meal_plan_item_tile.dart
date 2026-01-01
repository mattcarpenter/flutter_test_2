import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';

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
  bool _contextMenuIsAllowed(Offset location) {
    // The drag handle is the rightmost 40px of the widget
    // If we can't determine the widget size, allow context menu everywhere
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      final dragHandleWidth = 40.0;
      // Check if the touch is in the rightmost area (drag handle)
      if (location.dx > size.width - dragHandleWidth) {
        return false; // Don't allow context menu in drag handle area
      }
    }
    return true; // Allow context menu everywhere else
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
                  index: widget.index,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDragDropVertical,
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

  Widget _getItemIcon() {
    switch (widget.item.type) {
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