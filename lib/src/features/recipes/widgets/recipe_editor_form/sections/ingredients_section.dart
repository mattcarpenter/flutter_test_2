import 'package:flutter/material.dart';

import '../../../../../../database/models/ingredients.dart';
import '../../../../../widgets/app_button.dart';
import '../items/ingredient_list_item.dart';
import '../utils/context_menu_utils.dart';
import '../../../../../theme/spacing.dart';

class IngredientsSection extends StatefulWidget {
  final List<Ingredient> ingredients;
  final String? autoFocusIngredientId;
  final Function(bool isSection) onAddIngredient;
  final Function(String id) onRemoveIngredient;
  final Function(String id, Ingredient updatedIngredient) onUpdateIngredient;
  final Function(int oldIndex, int newIndex) onReorderIngredients;
  final Function(String id, bool hasFocus) onFocusChanged;

  const IngredientsSection({
    Key? key,
    required this.ingredients,
    required this.autoFocusIngredientId,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onUpdateIngredient,
    required this.onReorderIngredients,
    required this.onFocusChanged,
  }) : super(key: key);

  @override
  _IngredientsSectionState createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {
  bool _isDragging = false;
  int? _draggedIndex;

  // Method to handle drag start
  void _onDragStart(int index) {
    setState(() {
      _isDragging = true;
      _draggedIndex = index;
      // Unfocus any text fields to prevent the leader-follower error
      FocusScope.of(context).unfocus();
    });
  }

  // Method to handle drag end
  void _onDragEnd(int index) {
    // Keep both flags for 250ms to match ReorderableListView's animation timing
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _isDragging = false;
          _draggedIndex = null;
        });
      }
    });
  }

  // Calculate visual index during drag operations
  int? _getVisualIndex(int index) {
    if (!_isDragging || _draggedIndex == null) return null;

    // The dragged item doesn't have a visual position (it's floating)
    if (index == _draggedIndex) return null;

    // Items before the dragged item stay in the same visual position
    if (index < _draggedIndex!) {
      return index;
    }

    // Items after the dragged item shift up by one visual position
    return index - 1;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.ingredients.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text("No ingredients added yet."),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            proxyDecorator: defaultProxyDecorator,
            onReorderStart: (index) => _onDragStart(index),
            onReorderEnd: (index) => _onDragEnd(index),
            itemCount: widget.ingredients.length,
            onReorder: widget.onReorderIngredients,
            itemBuilder: (context, index) {
              final ingredient = widget.ingredients[index];


              return Padding(
                padding: EdgeInsets.zero,
                key: ValueKey(ingredient.id),
                child: IngredientListItem(
                  index: index,
                  ingredient: ingredient,
                  autoFocus: widget.autoFocusIngredientId == ingredient.id && !_isDragging,
                  isDragging: _draggedIndex == index,
                  onRemove: () => widget.onRemoveIngredient(ingredient.id),
                  onUpdate: (updatedIngredient) =>
                      widget.onUpdateIngredient(ingredient.id, updatedIngredient),
                  onAddNext: () => widget.onAddIngredient(false),
                  onFocus: (hasFocus) => widget.onFocusChanged(ingredient.id, hasFocus),
                  allIngredients: widget.ingredients,
                  enableGrouping: true,
                  visualIndex: _getVisualIndex(index),
                  draggedIndex: _draggedIndex,
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                text: 'Add Ingredient',
                onPressed: () => widget.onAddIngredient(false),
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.square,
                size: AppButtonSize.medium,
                leadingIcon: const Icon(Icons.add),
              ),
              AppButton(
                text: 'Add Section',
                onPressed: () => widget.onAddIngredient(true),
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.square,
                size: AppButtonSize.medium,
                leadingIcon: const Icon(Icons.segment),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
