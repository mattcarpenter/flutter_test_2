import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/pantry_items.dart'; // For StockStatus enum
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' show recipeIngredientMatchesProvider;
import 'package:recipe_app/src/repositories/recipe_repository.dart' show recipeRepositoryProvider;
import 'package:disclosure/disclosure.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

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
  // Track expanded state for each ingredient
  final Set<String> _expandedIngredientIds = {};
  // Map to store working copies of ingredient terms
  final Map<String, List<IngredientTerm>> _ingredientTermsMap = {};
  
  // Helper method to get color based on stock status
  Color _getStockStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return Colors.red;
      case StockStatus.lowStock:
        return Colors.yellow.shade700; // Darker yellow for better visibility
      case StockStatus.inStock:
        return Colors.green;
    }
  }

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
    // Watch the live matches provider to get real-time updates
    final matchesAsync = ref.watch(recipeIngredientMatchesProvider(widget.matches.recipeId));
    
    return matchesAsync.when(
      loading: () => AdaptiveSliverPage(
        title: 'Pantry Matches',
        automaticallyImplyLeading: true,
        previousPageTitle: widget.previousPageTitle,
        slivers: [
          const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, stack) => AdaptiveSliverPage(
        title: 'Pantry Matches',
        automaticallyImplyLeading: true,
        previousPageTitle: widget.previousPageTitle,
        slivers: [
          SliverToBoxAdapter(
            child: Center(child: Text('Error: $error')),
          ),
        ],
      ),
      data: (currentMatches) => AdaptiveSliverPage(
        title: 'Pantry Matches',
        automaticallyImplyLeading: true,
        previousPageTitle: widget.previousPageTitle,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary text with live data
                  Text(
                    'Pantry matches: ${currentMatches.matches.where((m) => m.hasMatch).length} of ${currentMatches.matches.length} ingredients',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 16),

                  // Match details list with accordion sections using live data
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentMatches.matches.length,
                    itemBuilder: (context, index) {
                      final match = currentMatches.matches[index];
                      return _buildIngredientAccordion(context, match);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                                color: _getStockStatusColor(match.pantryItem!.stockStatus),
                                fontStyle: match.pantryItem!.stockStatus == StockStatus.outOfStock
                                  ? FontStyle.italic
                                  : FontStyle.normal,
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
            onReorder: (oldIndex, newIndex) async {
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
              
              // Ensure this ingredient's accordion stays expanded
              _expandedIngredientIds.add(ingredient.id);
              
              // Save changes immediately
              await _saveIngredientChanges(ingredient.id);
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
              onSelected: (value) async {
                if (value == 'delete') {
                  // Get the current terms
                  final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

                  // Remove the term
                  terms.removeWhere((t) => t.value == term.value && t.source == term.source);

                  // Update the maps
                  _ingredientTermsMap[ingredientId] = terms;
                  
                  // Ensure the accordion stays expanded
                  _expandedIngredientIds.add(ingredientId);
                  
                  // Save changes immediately
                  await _saveIngredientChanges(ingredientId);
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
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
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
                
                // Ensure the accordion stays expanded
                _expandedIngredientIds.add(ingredientId);
                
                // Save changes immediately
                await _saveIngredientChanges(ingredientId);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Save changes for a specific ingredient immediately
  Future<void> _saveIngredientChanges(String ingredientId) async {
    final repository = ref.read(recipeRepositoryProvider);

    // Get the original recipe to modify
    final recipeId = widget.matches.recipeId;
    final recipeAsync = await repository.getRecipeById(recipeId);

    if (recipeAsync == null) {
      return;
    }

    // Get the updated terms for this ingredient
    final updatedTerms = _ingredientTermsMap[ingredientId] ?? [];
    
    // Find the original ingredient
    final originalIngredient = widget.matches.matches
        .firstWhere((match) => match.ingredient.id == ingredientId)
        .ingredient;
    
    // Create updated ingredient with new terms
    final updatedIngredient = originalIngredient.copyWith(terms: updatedTerms);

    // Important: Create a deep copy of the ingredients list to avoid modifying the original
    final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);

    // Find the matching ingredient by ID and replace it
    final index = ingredients.indexWhere((ing) => ing.id == ingredientId);
    if (index >= 0) {
      ingredients[index] = updatedIngredient;
      
      // Save the updated recipe ingredients
      await repository.updateIngredients(recipeId, ingredients);
      
      // Invalidate the matches provider to refresh the UI with new match data
      ref.invalidate(recipeIngredientMatchesProvider(recipeId));
    }
  }
}