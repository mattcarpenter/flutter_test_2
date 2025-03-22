import 'package:flutter/material.dart';

import '../../../../../database/models/ingredients.dart';

class RecipeIngredientsView extends StatelessWidget {
  final List<Ingredient> ingredients;

  const RecipeIngredientsView({Key? key, required this.ingredients}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_basket, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),

        if (ingredients.isEmpty)
          const Text('No ingredients listed.'),

        // Ingredients list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = ingredients[index];

            // Section header
            if (ingredient.type == 'section') {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            // Regular ingredient
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bullet point
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Amount
                  if (ingredient.primaryAmount1Value != null &&
                      ingredient.primaryAmount1Value!.isNotEmpty) ...[
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${ingredient.primaryAmount1Value} ${ingredient.primaryAmount1Unit ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  // Ingredient name
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // Note (if available)
                  if (ingredient.note != null && ingredient.note!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '(${ingredient.note})',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
