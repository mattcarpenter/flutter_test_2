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

  // Method to handle drag start
  void _onDragStart() {
    setState(() {
      _isDragging = true;
      // Unfocus any text fields to prevent the leader-follower error
      FocusScope.of(context).unfocus();
    });
  }

  // Method to handle drag end
  void _onDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingredients",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (widget.ingredients.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No ingredients added yet."),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            proxyDecorator: defaultProxyDecorator,
            onReorderStart: (_) => _onDragStart(),
            onReorderEnd: (_) => _onDragEnd(),
            itemCount: widget.ingredients.length,
            onReorder: widget.onReorderIngredients,
            itemBuilder: (context, index) {
              final ingredient = widget.ingredients[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                key: ValueKey(ingredient.id),
                child: IngredientListItem(
                  index: index,
                  ingredient: ingredient,
                  autoFocus: widget.autoFocusIngredientId == ingredient.id && !_isDragging,
                  onRemove: () => widget.onRemoveIngredient(ingredient.id),
                  onUpdate: (updatedIngredient) =>
                      widget.onUpdateIngredient(ingredient.id, updatedIngredient),
                  onAddNext: () => widget.onAddIngredient(false),
                  onFocus: (hasFocus) => widget.onFocusChanged(ingredient.id, hasFocus),
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onAddIngredient(false),
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
              ),
              const SizedBox(width: 8),
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
