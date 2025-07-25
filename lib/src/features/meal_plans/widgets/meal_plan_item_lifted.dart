import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../providers/meal_plan_provider.dart';
import '../models/meal_plan_drag_data.dart';

class MealPlanItemLifted extends ConsumerStatefulWidget {
  final MealPlanItem item;
  final String dateString;
  final int index;

  const MealPlanItemLifted({
    super.key,
    required this.item,
    required this.dateString,
    required this.index,
  });

  @override
  ConsumerState<MealPlanItemLifted> createState() => _MealPlanItemLiftedState();
}

class _MealPlanItemLiftedState extends ConsumerState<MealPlanItemLifted>
    with SingleTickerProviderStateMixin {
  late AnimationController _liftController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isDragging = false;
  
  bool _contextMenuIsAllowed(Offset location) {
    // The drag handle is the rightmost 48px of the widget
    // If we can't determine the widget size, allow context menu everywhere
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      final dragHandleWidth = 48.0;
      // Check if the touch is in the rightmost area (drag handle)
      if (location.dx > size.width - dragHandleWidth) {
        return false; // Don't allow context menu in drag handle area
      }
    }
    return true; // Allow context menu everywhere else
  }

  @override
  void initState() {
    super.initState();
    
    _liftController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _liftController,
      curve: Curves.easeOutCubic,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _liftController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _liftController.dispose();
    super.dispose();
  }

  void _onDragStart() {
    HapticFeedback.mediumImpact();
    setState(() => _isDragging = true);
    _liftController.forward();
  }

  void _onDragEnd() {
    setState(() => _isDragging = false);
    _liftController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: AnimatedBuilder(
        animation: _liftController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isDragging ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: _shadowAnimation.value,
                    offset: Offset(0, _shadowAnimation.value / 2),
                  ),
                ] : null,
              ),
              child: Draggable<MealPlanDragData>(
                data: MealPlanDragData(
                  item: widget.item,
                  sourceDate: widget.dateString,
                  sourceIndex: widget.index,
                ),
                dragAnchorStrategy: childDragAnchorStrategy,
                onDragStarted: _onDragStart,
                onDragEnd: (_) => _onDragEnd(),
                onDraggableCanceled: (_, __) => _onDragEnd(),
                feedback: _buildLiftedTile(context),
                childWhenDragging: _buildGhostTile(context),
                child: _buildNormalTile(context),
              ),
            ),
          );
        },
      ),
    );
  }

  // The normal tile
  Widget _buildNormalTile(BuildContext context) {
    return ContextMenuWidget(
      contextMenuIsAllowed: _contextMenuIsAllowed,
      menuProvider: (_) => _buildContextMenu(),
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
          child: _buildTileContent(context, 1.0),
        ),
      ),
    );
  }

  // The lifted feedback that follows the finger
  Widget _buildLiftedTile(BuildContext context) {
    return Transform.scale(
      scale: 1.05,
      child: Transform.rotate(
        angle: 0.02, // Slight tilt for depth
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          child: Material(
            color: Colors.transparent,
            elevation: 12,
            borderRadius: BorderRadius.circular(8),
            shadowColor: Colors.black.withOpacity(0.3),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                  width: 2,
                ),
              ),
              child: _buildTileContent(context, 1.0),
            ),
          ),
        ),
      ),
    );
  }

  // The ghost left behind
  Widget _buildGhostTile(BuildContext context) {
    return Transform.scale(
      scale: 0.95,
      child: Opacity(
        opacity: 0.15,
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
          child: _buildTileContent(context, 0.5),
        ),
      ),
    );
  }

  // Shared tile content
  Widget _buildTileContent(BuildContext context, double opacity) {
    return Opacity(
      opacity: opacity,
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
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (widget.item.isRecipe && widget.item.recipeId != null) {
      context.push('/recipes/${widget.item.recipeId}');
    } else if (widget.item.isNote) {
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
      date: widget.dateString,
      itemId: widget.item.id,
      userId: null,
      householdId: null,
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