import 'package:flutter/material.dart';
import 'package:recipe_app/database/models/ingredients.dart';

void showIngredientsModal(BuildContext context, List<Ingredient> ingredients) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => IngredientsSheet(
        ingredients: ingredients,
        scrollController: scrollController,
      ),
    ),
  );
}

class IngredientsSheet extends StatelessWidget {
  final List<Ingredient> ingredients;
  final ScrollController scrollController;

  const IngredientsSheet({
    Key? key,
    required this.ingredients,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Draggable handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Ingredients list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: ingredients.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];

              if (ingredient.type == 'section') {
                return _buildSectionHeader(ingredient);
              } else {
                return _buildIngredientItem(ingredient);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(Ingredient section) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          section.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientItem(Ingredient ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),

          // Amount (if available)
          if (ingredient.primaryAmount1Value != null &&
              ingredient.primaryAmount1Value!.isNotEmpty) ...[
            SizedBox(
              width: 70,
              child: Text(
                '${ingredient.primaryAmount1Value} ${ingredient.primaryAmount1Unit ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Ingredient name
          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
