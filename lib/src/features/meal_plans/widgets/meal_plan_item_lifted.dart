import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/local_or_network_image.dart';
import '../../../widgets/recipe_placeholder_image.dart';
import '../models/meal_plan_drag_data.dart';

class MealPlanItemLifted extends ConsumerStatefulWidget {
  final MealPlanItem item;
  final String dateString;
  final int index;
  final VoidCallback? onDelete;

  const MealPlanItemLifted({
    super.key,
    required this.item,
    required this.dateString,
    required this.index,
    this.onDelete,
  });

  @override
  ConsumerState<MealPlanItemLifted> createState() => _MealPlanItemLiftedState();
}

class _MealPlanItemLiftedState extends ConsumerState<MealPlanItemLifted>
    with SingleTickerProviderStateMixin {
  late AnimationController _liftController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  
  bool _contextMenuIsAllowed(Offset location) {
    // Context menu allowed everywhere since drag handle is now isolated
    return true;
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
    // Set global drag state with both item ID and source date
    ref.read(mealPlanDraggingItemProvider.notifier).state = MealPlanDragState(
      itemId: widget.item.id,
      sourceDate: widget.dateString,
    );
    _liftController.forward();
  }

  void _onDragEnd() {
    // Always clear global drag state first, before any other operations
    ref.read(mealPlanDraggingItemProvider.notifier).state = null;

    // Only animate if the widget is still mounted and controller is valid
    if (mounted) {
      _liftController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if THIS specific item is being dragged FROM THIS DATE using global state
    // We check both itemId AND sourceDate so that:
    // - Source location shows ghost (invisible placeholder)
    // - Target location (after drop) shows normal tile immediately
    final dragState = ref.watch(mealPlanDraggingItemProvider);
    final isDragging = dragState != null &&
        dragState.itemId == widget.item.id &&
        dragState.sourceDate == widget.dateString;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: AnimatedBuilder(
        animation: _liftController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: isDragging ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: _shadowAnimation.value,
                    offset: Offset(0, _shadowAnimation.value / 2),
                  ),
                ] : null,
              ),
              child: isDragging ? _buildGhostTile(context) : _buildNormalTile(context),
            ),
          );
        },
      ),
    );
  }

  // The normal tile
  Widget _buildNormalTile(BuildContext context) {
    final colors = AppColors.of(context);
    return ContextMenuWidget(
      contextMenuIsAllowed: _contextMenuIsAllowed,
      menuProvider: (_) => _buildContextMenu(),
      child: GestureDetector(
        onTap: () => _handleTap(context, ref),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.groupedListBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.groupedListBorder,
              width: 0.5,
            ),
          ),
          child: _buildTileContent(context, 1.0, isDraggableHandle: true),
        ),
      ),
    );
  }

  // The lifted feedback that follows the finger
  Widget _buildLiftedTile(BuildContext context) {
    final colors = AppColors.of(context);
    return Transform.scale(
      scale: 1.05,
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          shadowColor: Colors.black.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.groupedListBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildTileContent(context, 1.0),
          ),
        ),
      ),
    );
  }

  // The ghost left behind - invisible but maintains space for shadow
  Widget _buildGhostTile(BuildContext context) {
    final colors = AppColors.of(context);
    return Opacity(
      opacity: 0.0, // Completely invisible - only shadow will be visible from parent
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.groupedListBorder,
            width: 0.5,
          ),
        ),
        child: _buildTileContent(context, 1.0),
      ),
    );
  }

  // Shared tile content
  Widget _buildTileContent(BuildContext context, double opacity, {bool isDraggableHandle = false}) {
    final colors = AppColors.of(context);
    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          // Thumbnail for recipes, icon for notes
          widget.item.isRecipe && widget.item.recipeId != null
              ? _buildRecipeThumbnail(context)
              : Container(
                  width: 36,
                  height: 36,
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

          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_getDisplaySubtitle() != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getDisplaySubtitle()!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Drag handle - only make it draggable when requested
          isDraggableHandle
              ? Draggable<MealPlanDragData>(
                  data: MealPlanDragData(
                    item: widget.item,
                    sourceDate: widget.dateString,
                    sourceIndex: widget.index,
                  ),
                  dragAnchorStrategy: (draggable, context, position) {
                    // Get the render box to calculate proper offset
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final itemWidth = MediaQuery.of(context).size.width - 32; // Account for horizontal padding
                    // Position feedback so item appears under finger, accounting for handle being on right
                    return Offset(itemWidth - 40, renderBox.size.height / 2);
                  },
                  onDragStarted: _onDragStart,
                  onDragEnd: (_) => _onDragEnd(),
                  onDraggableCanceled: (_, __) => _onDragEnd(),
                  feedback: _buildLiftedTile(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Icon(
                      CupertinoIcons.line_horizontal_3,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ),
                )
              : Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 16,
                  color: colors.textTertiary,
                ),

          if (!isDraggableHandle) const SizedBox(width: 8),
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

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (widget.item.isRecipe && widget.item.recipeId != null) {
      context.push('/recipe/${widget.item.recipeId}');
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
    // Use the onDelete callback if provided (allows parent to coordinate animation)
    if (widget.onDelete != null) {
      widget.onDelete!();
    } else {
      // Fallback to direct removal if no callback provided
      ref.read(mealPlanNotifierProvider.notifier).removeItem(
        date: widget.dateString,
        itemId: widget.item.id,
      );
    }
  }

  Widget _buildRecipeThumbnail(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdStreamProvider(widget.item.recipeId!));

    return recipeAsync.when(
      data: (recipe) {
        if (recipe == null) {
          return _buildFallbackThumbnail(context);
        }

        final coverImage = RecipeImage.getCoverImage(recipe.images);
        final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

        return SizedBox(
          width: 36,
          height: 36,
          child: FutureBuilder<String>(
            future: coverImage?.getFullPath() ?? Future.value(''),
            builder: (context, snapshot) {
              final coverImageFilePath = snapshot.data ?? '';
              final hasImage = coverImageFilePath.isNotEmpty || coverImageUrl.isNotEmpty;

              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: hasImage
                    ? LocalOrNetworkImage(
                        filePath: coverImageFilePath,
                        url: coverImageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      )
                    : _buildFallbackThumbnail(context),
              );
            },
          ),
        );
      },
      loading: () => _buildFallbackThumbnail(context),
      error: (_, __) => _buildFallbackThumbnail(context),
    );
  }

  Widget _buildFallbackThumbnail(BuildContext context) {
    return RecipePlaceholderImage(
      width: 36,
      height: 36,
      borderRadius: BorderRadius.circular(6),
      fit: BoxFit.cover,
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