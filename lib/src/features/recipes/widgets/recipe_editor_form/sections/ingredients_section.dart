import 'package:flutter/material.dart';

import '../../../../../../database/models/ingredients.dart';
import '../items/ingredient_list_item.dart';
import '../utils/context_menu_utils.dart';

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
    setState(() {
      _isDragging = false;
      _draggedIndex = null;
    });
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
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onAddIngredient(false),
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onAddIngredient(true),
                icon: const Icon(Icons.segment),
                label: const Text('Add Section'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
