import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import './recipe_list.dart' show Recipe;

class RecipeTile extends StatelessWidget {
  final Recipe recipe;

  const RecipeTile({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge, // Ensures children are clipped to rounded corners.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top image placeholder.
          Image.asset(
            'assets/images/samples/${recipe.imageName}',
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          // Recipe name.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              recipe.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 4),
          // Row with clock icon, time and difficulty chip.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  recipe.time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    recipe.difficulty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
