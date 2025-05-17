import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' show recipeIngredientMatchesProvider, recipeRepositoryProvider;
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:disclosure/disclosure.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/recipe_view/ingredient_match_circle.dart';

class IngredientMatchesPage extends ConsumerStatefulWidget {
  final RecipeIngredientMatches matches;
  final String previousPageTitle;

  const IngredientMatchesPage({
    Key? key, 
    required this.matches,
    required this.previousPageTitle,
  }) : super(key: key);

  @override
  ConsumerState<IngredientMatchesPage> createState() => _IngredientMatchesPageState();
}

class _IngredientMatchesPageState extends ConsumerState<IngredientMatchesPage> {
  // Track the modified ingredients to save on completion
  final Map<String, Ingredient> _modifiedIngredients = {};

  // Track expanded state for each ingredient
  final Set<String> _expandedIngredientIds = {};
  // Map to store working copies of ingredient terms
  final Map<String, List<IngredientTerm>> _ingredientTermsMap = {};

  @override
  void initState() {
    super.initState();
    // Initialize working copies of terms for each ingredient
    for (final match in widget.matches.matches) {
      final ingredient = match.ingredient;
      _ingredientTermsMap[ingredient.id] = List<IngredientTerm>.from(ingredient.terms ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: 'Pantry Matches',
      trailing: IconButton(
        icon: const Icon(Icons.save),
        onPressed: () async {
          await _saveChanges();
          if (context.mounted) {
            // Invalidate the matches provider to refresh data
            ref.invalidate(recipeIngredientMatchesProvider(widget.matches.recipeId));
            // Go back to previous screen
            Navigator.of(context).pop();
          }
        },
      ),
      automaticallyImplyLeading: true,
      previousPageTitle: widget.previousPageTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary text
                Text(
                  'Pantry matches: ${widget.matches.matches.where((m) => m.hasMatch).length} of ${widget.matches.matches.length} ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 16),

                // Match details list with accordion sections
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.matches.matches.length,
                  itemBuilder: (context, index) {
                    final match = widget.matches.matches[index];
                    return _buildIngredientAccordion(context, match);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientAccordion(BuildContext context, IngredientPantryMatch match) {
    final ingredient = match.ingredient;
    final isExpanded = _expandedIngredientIds.contains(ingredient.id);

    // Get the working copy of terms for this ingredient
    final terms = _ingredientTermsMap[ingredient.id] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Disclosure(
        closed: !isExpanded,
        onOpen: () {
          setState(() {
            _expandedIngredientIds.add(ingredient.id);
          });
        },
        onClose: () {
          setState(() {
            _expandedIngredientIds.remove(ingredient.id);
          });
        },
        header: DisclosureButton(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Status indicator with icon
                  _buildStatusIcon(match),

                  const SizedBox(width: 16),

                  // Ingredient information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),

                        if (match.hasMatch)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Matched with: ${match.pantryItem!.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: match.pantryItem!.inStock ? Colors.green : Colors.red,
                                fontStyle: match.pantryItem!.inStock
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Disclosure arrow
                  const DisclosureIcon(),
                ],
              ),
            ),
          ),
        ),
        child: DisclosureView(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 16),
          child: _buildTermsEditor(context, ingredient, terms),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(IngredientPantryMatch match) {
    final color = match.hasMatch ? Colors.green : Colors.grey;
    final icon = match.hasMatch ? Icons.check : Icons.help_outline;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildTermsEditor(BuildContext context, Ingredient ingredient, List<IngredientTerm> terms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Terms heading
        Row(
          children: [
            const Text(
              'Matching Terms',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),

            // Add term button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addNewTerm(ingredient.id),
              tooltip: 'Add New Term',
            ),
          ],
        ),

        const SizedBox(height: 8),

        // No terms placeholder
        if (terms.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No additional terms for this ingredient. Add terms to improve pantry matching.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),

        // Terms list with reordering
        if (terms.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                final List<IngredientTerm> updatedTerms = List.from(terms);
                final item = updatedTerms.removeAt(oldIndex);
                updatedTerms.insert(newIndex, item);

                // Update sort values
                for (int i = 0; i < updatedTerms.length; i++) {
                  updatedTerms[i] = IngredientTerm(
                    value: updatedTerms[i].value,
                    source: updatedTerms[i].source,
                    sort: i,
                  );
                }

                // Update terms list in our map
                _ingredientTermsMap[ingredient.id] = updatedTerms;

                // Mark as modified
                _modifiedIngredients[ingredient.id] = ingredient.copyWith(terms: updatedTerms);
                
                // Ensure this ingredient's accordion stays expanded
                _expandedIngredientIds.add(ingredient.id);
              });
            },
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              return _buildTermItem(
                key: ValueKey('${ingredient.id}_term_${term.value}_$index'),
                ingredientId: ingredient.id,
                term: term,
              );
            },
          ),

        const SizedBox(height: 16),

        // Help text
        const Text(
          'Tip: Add terms that match pantry item names to improve matching.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTermItem({
    required Key key,
    required String ingredientId,
    required IngredientTerm term,
  }) {
    return Card(
      key: key,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(term.value),
        subtitle: Text('Source: ${term.source}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reorder handle
            const Icon(Icons.drag_handle),

            // Menu for additional actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  setState(() {
                    // Get the current terms
                    final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

                    // Remove the term
                    terms.removeWhere((t) => t.value == term.value && t.source == term.source);

                    // Update the maps
                    _ingredientTermsMap[ingredientId] = terms;

                    // Find the original ingredient to update
                    final ingredient = widget.matches.matches
                        .firstWhere((match) => match.ingredient.id == ingredientId)
                        .ingredient;

                    // Mark as modified
                    _modifiedIngredients[ingredientId] = ingredient.copyWith(terms: terms);
                    
                    // Ensure the accordion stays expanded
                    _expandedIngredientIds.add(ingredientId);
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewTerm(String ingredientId) {
    // Creating a controller for the dialog
    final controller = TextEditingController();

    // Find the original ingredient
    final ingredient = widget.matches.matches
        .firstWhere((match) => match.ingredient.id == ingredientId)
        .ingredient;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Matching Term'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Term',
            hintText: 'Enter a matching term (e.g., pantry item name)',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  // Get existing terms from our working copy
                  final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

                  // Add new term with the next sort value
                  terms.add(IngredientTerm(
                    value: value,
                    source: 'user', // Marked as user-added
                    sort: terms.length, // Next position
                  ));

                  // Update the maps
                  _ingredientTermsMap[ingredientId] = terms;

                  // Mark as modified
                  _modifiedIngredients[ingredientId] = ingredient.copyWith(terms: terms);
                });
              }
              Navigator.of(context).pop();
              
              // Ensure the accordion stays expanded
              setState(() {
                _expandedIngredientIds.add(ingredientId);
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Save all changes
  Future<void> _saveChanges() async {
    if (_modifiedIngredients.isEmpty) {
      return;
    }

    final repository = ref.read(recipeRepositoryProvider);

    // Get the original recipe to modify
    final recipeId = widget.matches.recipeId;
    final recipeAsync = await repository.getRecipeById(recipeId);

    if (recipeAsync == null) {
      return;
    }

    // Important: Create a deep copy of the ingredients list to avoid modifying the original
    final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);

    // Replace ingredients with modified versions
    for (final entry in _modifiedIngredients.entries) {
      final ingredientId = entry.key;
      final updatedIngredient = entry.value;
      
      // Find the matching ingredient by ID
      final index = ingredients.indexWhere((ing) => ing.id == ingredientId);
      if (index >= 0) {
        // Replace the ingredient in the list with our modified version
        ingredients[index] = updatedIngredient;
      }
    }

    // Save the updated recipe ingredients
    await repository.updateIngredients(recipeId, ingredients);
  }
}