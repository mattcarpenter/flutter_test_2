import 'package:flutter/material.dart';

import '../../../../../../database/models/ingredients.dart';
import '../../../../../widgets/app_button.dart';
import '../../../../../widgets/app_overflow_button.dart';
import '../../../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
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
  final VoidCallback? onEditAsText;

  const IngredientsSection({
    Key? key,
    required this.ingredients,
    required this.autoFocusIngredientId,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onUpdateIngredient,
    required this.onReorderIngredients,
    required this.onFocusChanged,
    this.onEditAsText,
  }) : super(key: key);

  @override
  _IngredientsSectionState createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {
  bool _isDragging = false;
  int? _draggedIndex;
  
  // Memoized visual indices to avoid recalculation on every build
  final Map<int, int?> _cachedVisualIndices = {};
  
  // Track which items actually need visual updates (performance optimization)
  final Set<int> _visuallyAffectedItems = {};

  // Method to handle drag start
  void _onDragStart(int index) {
    // Pre-calculate all visual indices once instead of on every build
    _cachedVisualIndices.clear();
    _visuallyAffectedItems.clear();
    
    for (int i = 0; i < widget.ingredients.length; i++) {
      int? visualIndex;
      
      // The dragged item doesn't have a visual position (it's floating)
      if (i == index) {
        visualIndex = null;
        _visuallyAffectedItems.add(i); // Dragged item changes
      }
      // Items before the dragged item stay in the same visual position  
      else if (i < index) {
        visualIndex = i;
        // Only first item before drag might change border (if it becomes last in group)
        if (i == index - 1) _visuallyAffectedItems.add(i);
      }
      // Items after the dragged item shift up by one visual position
      else {
        visualIndex = i - 1;
        _visuallyAffectedItems.add(i); // All items after change position
      }
      
      _cachedVisualIndices[i] = visualIndex;
    }
    
    setState(() {
      _isDragging = true;
      _draggedIndex = index;
      // Unfocus any text fields to prevent the leader-follower error
      FocusScope.of(context).unfocus();
    });
  }

  // Method to handle drag end
  void _onDragEnd(int index) {
    // Keep both flags for 0ms to match StepsSection timing
    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          _isDragging = false;
          _draggedIndex = null;
          _cachedVisualIndices.clear();
          _visuallyAffectedItems.clear();
        });
      }
    });
  }

  // Fast lookup of pre-calculated visual index (performance optimized)
  int? _getVisualIndex(int index) {
    if (!_isDragging || _draggedIndex == null) return null;
    return _cachedVisualIndices[index];
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
          child: Row(
            children: [
              // Add Ingredient button - flex column 1
              Expanded(
                flex: 1,
                child: AppButton(
                  text: 'Add Ingredient',
                  onPressed: () => widget.onAddIngredient(false),
                  theme: AppButtonTheme.secondary,
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  leadingIcon: const Icon(Icons.add),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              
              // Add Section button - flex column 2  
              Expanded(
                flex: 1,
                child: AppButton(
                  text: 'Add Section',
                  onPressed: () => widget.onAddIngredient(true),
                  theme: AppButtonTheme.secondary,
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  leadingIcon: const Icon(Icons.segment),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              
              // Context menu button - compact overflow style
              AppOverflowButton(
                items: [
                  AdaptiveMenuItem(
                    title: 'Edit as Text',
                    icon: const Icon(Icons.edit_note),
                    onTap: () => widget.onEditAsText?.call(),
                  ),
                  AdaptiveMenuItem(
                    title: 'Clear All Ingredients',
                    icon: const Icon(Icons.clear_all),
                    onTap: () {
                      // TODO: Implement clear functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
