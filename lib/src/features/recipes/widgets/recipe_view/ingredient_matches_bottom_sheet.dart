import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:disclosure/disclosure.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:uuid/uuid.dart';
import 'ingredient_match_circle.dart';

/// Shows a bottom sheet displaying ingredient-pantry match details
/// with ability to edit the ingredient terms for better matching
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
          trailingNavBarWidget: Consumer(
            builder: (context, ref, child) {
              return TextButton(
                onPressed: () {
                  // The key will be accessed from the state to save changes
                  final state = modalContext.findAncestorStateOfType<_IngredientMatchesBottomSheetContentState>();
                  state?.saveChanges(ref).then((_) {
                    Navigator.of(modalContext).pop();
                  });
                },
                child: const Text('Save'),
              );
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

class IngredientMatchesBottomSheetContent extends StatefulWidget {
  final RecipeIngredientMatches matches;

  const IngredientMatchesBottomSheetContent({
    Key? key,
    required this.matches,
  }) : super(key: key);

  @override
  State<IngredientMatchesBottomSheetContent> createState() => _IngredientMatchesBottomSheetContentState();
}

class _IngredientMatchesBottomSheetContentState extends State<IngredientMatchesBottomSheetContent> {
  // Track the modified ingredients to save on completion
  final Map<String, Ingredient> _modifiedIngredients = {};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
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
            Expanded(
              child: ListView.builder(
                itemCount: widget.matches.matches.length,
                itemBuilder: (context, index) {
                  final match = widget.matches.matches[index];
                  return _buildIngredientAccordion(context, match);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIngredientAccordion(BuildContext context, IngredientPantryMatch match) {
    final ingredient = match.ingredient;
    
    // Get the terms (or empty list if null)
    final terms = List<IngredientTerm>.from(ingredient.terms ?? []);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Disclosure(
        closed: true, // Initially closed
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
              onPressed: () => _addNewTerm(ingredient),
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
                final item = terms.removeAt(oldIndex);
                terms.insert(newIndex, item);
                
                // Update sort values
                for (int i = 0; i < terms.length; i++) {
                  terms[i] = IngredientTerm(
                    value: terms[i].value,
                    source: terms[i].source,
                    sort: i,
                  );
                }
                
                // Mark as modified
                _modifiedIngredients[ingredient.id] = ingredient.copyWith(terms: terms);
              });
            },
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              return _buildTermItem(
                key: ValueKey('${ingredient.id}_term_${term.value}'),
                ingredient: ingredient,
                term: term,
                terms: terms,
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
    required Ingredient ingredient,
    required IngredientTerm term,
    required List<IngredientTerm> terms,
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
                    terms.removeWhere((t) => t.value == term.value);
                    _modifiedIngredients[ingredient.id] = ingredient.copyWith(terms: terms);
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
  
  void _addNewTerm(Ingredient ingredient) {
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
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  // Get existing terms or create new list
                  final terms = List<IngredientTerm>.from(ingredient.terms ?? []);
                  
                  // Add new term with the next sort value
                  terms.add(IngredientTerm(
                    value: value,
                    source: 'user', // Marked as user-added
                    sort: terms.length, // Next position
                  ));
                  
                  // Update the ingredient and mark as modified
                  _modifiedIngredients[ingredient.id] = ingredient.copyWith(terms: terms);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  // Save all changes
  Future<void> saveChanges(WidgetRef ref) async {
    if (_modifiedIngredients.isEmpty) return;
    
    final repository = ref.read(recipeRepositoryProvider);
    
    // Get the original recipe to modify
    final recipeId = widget.matches.recipeId;
    final recipeAsync = await repository.getRecipeById(recipeId);
    
    if (recipeAsync == null) return;
    
    // Update the ingredients list with our modified ingredients
    final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);
    
    for (final entry in _modifiedIngredients.entries) {
      final index = ingredients.indexWhere((ing) => ing.id == entry.key);
      if (index >= 0) {
        ingredients[index] = entry.value;
      }
    }
    
    // Save the updated recipe
    await repository.updateIngredients(recipeId, ingredients);
  }
}