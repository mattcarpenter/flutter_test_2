import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../database/models/meal_plan_items.dart';
import '../../../localization/l10n_extension.dart';
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
            _getDisplayTitle(context),
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
                child: _getItemIcon(),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayTitle(context),
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedDragDropVertical,
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
      context.push('/recipe/${item.recipeId}');
    } else if (item.isNote) {
      _editNote(context, ref);
    }
  }

  void _editNote(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.mealPlanEditNote),
        content: Text(context.l10n.mealPlanEditNotePlaceholder),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.commonOk),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
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

  String _getDisplayTitle(BuildContext context) {
    if (item.isRecipe) {
      return item.recipeTitle ?? context.l10n.mealPlanUnknownRecipe;
    } else if (item.isNote) {
      return item.noteText ?? context.l10n.mealPlanNoteDefault;
    }
    return context.l10n.mealPlanUnknownItem;
  }

  String? _getDisplaySubtitle() {
    // Notes no longer have subtitles - noteText is displayed as title
    return null;
  }
}