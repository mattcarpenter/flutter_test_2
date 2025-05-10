import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'ingredient_match_circle.dart';

/// Shows a bottom sheet displaying ingredient-pantry match details
void showIngredientMatchesBottomSheet(
  BuildContext context, {
  required RecipeIngredientMatches matches,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: Text('Pantry Matches (${matches.matches.where((m) => m.hasMatch).length}/${matches.matches.length})'),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          child: IngredientMatchesBottomSheetContent(matches: matches),
        ),
      ];
    },
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}

class IngredientMatchesBottomSheetContent extends StatelessWidget {
  final RecipeIngredientMatches matches;

  const IngredientMatchesBottomSheetContent({
    Key? key,
    required this.matches,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary text
            Text(
              'Pantry matches: ${matches.matches.where((m) => m.hasMatch).length} of ${matches.matches.length} ingredients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Match details list
            Expanded(
              child: ListView.builder(
                itemCount: matches.matches.length,
                itemBuilder: (context, index) {
                  final match = matches.matches[index];
                  return _buildMatchItem(context, match);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchItem(BuildContext context, IngredientPantryMatch match) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Status indicator
          IngredientMatchCircle(
            match: match,
            onTap: () {}, // No action needed here
            size: 12.0,
          ),
          
          const SizedBox(width: 12),
          
          // Recipe ingredient name
          Expanded(
            flex: 2,
            child: Text(
              match.ingredient.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Pantry item name (if available)
          Expanded(
            flex: 2,
            child: match.hasMatch
              ? Text(
                  match.pantryItem!.name,
                  style: TextStyle(
                    color: match.pantryItem!.inStock ? Colors.green : Colors.red,
                    fontStyle: match.pantryItem!.inStock ? FontStyle.normal : FontStyle.italic,
                  ),
                )
              : const Text(
                  'No match in pantry',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}