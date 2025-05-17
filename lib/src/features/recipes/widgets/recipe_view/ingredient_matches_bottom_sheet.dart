import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:disclosure/disclosure.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' show recipeIngredientMatchesProvider, recipeRepositoryProvider;
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:uuid/uuid.dart';
import 'ingredient_match_circle.dart';
import 'pantry_item_selector_bottom_sheet.dart';

/// Shows a bottom sheet displaying ingredient-pantry match details
/// with ability to edit the ingredient terms for better matching
void showIngredientMatchesBottomSheet(
  BuildContext context, {
  required RecipeIngredientMatches matches,
}) {
  // Ensure all ingredients have been properly initialized in the matches object
  if (matches.matches.isEmpty && matches.recipeId.isNotEmpty) {
    debugPrint("Warning: No matches found for recipe ${matches.recipeId}");
  }
  // Create a global key to access the state directly
  final contentKey = GlobalKey<_IngredientMatchesBottomSheetContentState>();
  
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
                onPressed: () async {
                  // Access the state directly using the global key
                  final state = contentKey.currentState;
                  if (state != null) {
                    print("Found state, saving changes");
                    await state.saveChanges(ref);
                    
                    // Force a refresh of the matches provider to get fresh data next time
                    // by invalidating the cache
                    ref.invalidate(recipeIngredientMatchesProvider(matches.recipeId));
                    
                    // Force an immediate refresh to ensure UI updates on return
                    ref.read(recipeIngredientMatchesProvider(matches.recipeId).future);
                    print("Invalidated and refreshed recipe ingredient matches for ${matches.recipeId}");
                    
                    // Force immediate closure to trigger refresh when reopened
                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop(true); // Pass true to indicate successful save
                    }
                  } else {
                    print("ERROR: Could not find bottom sheet state to save changes");
                  }
                },
                child: const Text('Save'),
              );
            },
          ),
          child: IngredientMatchesBottomSheetContent(
            key: contentKey, // Use the global key here
            matches: matches,
          ),
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

  // Track expanded state for each ingredient
  final Set<String> _expandedIngredientIds = {};
  // Map to store working copies of ingredient terms
  final Map<String, List<IngredientTerm>> _ingredientTermsMap = {};

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

  @override
  void initState() {
    super.initState();
    // Initialize working copies of terms for each ingredient
    for (final match in widget.matches.matches) {
      final ingredient = match.ingredient;
      _ingredientTermsMap[ingredient.id] = List<IngredientTerm>.from(ingredient.terms ?? []);
    }
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

            // Add term button with key to get its position
            IconButton(
              key: ValueKey('add_term_button_${ingredient.id}'),
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
    // Find the original ingredient
    final ingredient = widget.matches.matches
        .firstWhere((match) => match.ingredient.id == ingredientId)
        .ingredient;

    // Show platform-specific menu with options
    if (Platform.isIOS || Platform.isMacOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Add Matching Term'),
          message: const Text('Choose an option to add a matching term'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Enter Custom Term'),
              onPressed: () {
                Navigator.pop(context);
                _showAddTermDialog(ingredientId, ingredient);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Select from Pantry'),
              onPressed: () {
                Navigator.pop(context);
                showPantryItemSelectorBottomSheet(
                  context: context,
                  recipeId: widget.matches.recipeId,
                  onItemSelected: (itemName) {
                    _addTermFromPantryItem(ingredientId, ingredient, itemName);
                  },
                );
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      // Material Design popup menu
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + 50, // Offset to appear below the + button
          position.dx + 1,
          position.dy + 1,
        ),
        items: [
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Enter Custom Term'),
              subtitle: const Text('Enter a new term for matching'),
            ),
            onTap: () {
              // Add delay to avoid "Looking up a deactivated widget's ancestor" errors
              Future.delayed(Duration.zero, () {
                _showAddTermDialog(ingredientId, ingredient);
              });
            },
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.kitchen),
              title: const Text('Select from Pantry'),
              subtitle: const Text('Use an existing pantry item name'),
            ),
            onTap: () {
              // Add delay to avoid "Looking up a deactivated widget's ancestor" errors
              Future.delayed(Duration.zero, () {
                showPantryItemSelectorBottomSheet(
                  context: context,
                  recipeId: widget.matches.recipeId,
                  onItemSelected: (itemName) {
                    _addTermFromPantryItem(ingredientId, ingredient, itemName);
                  },
                );
              });
            },
          ),
        ],
      );
    }
  }

  // Show the platform-specific dialog
  void _showAddTermDialog(String ingredientId, Ingredient ingredient) {
    final controller = TextEditingController();

    // Handle saving the term
    void saveTerm() {
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
          
          // Ensure the accordion stays expanded
          _expandedIngredientIds.add(ingredientId);
        });
      }
      Navigator.of(context).pop();
    }

    if (Platform.isIOS) {
      // Show Cupertino dialog on iOS
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Add Matching Term'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Enter a matching term',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => saveTerm(),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: saveTerm,
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } else {
      // Show Material dialog on Android and other platforms
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
            onSubmitted: (_) => saveTerm(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: saveTerm,
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }
  }

  // Add a term from a selected pantry item
  void _addTermFromPantryItem(String ingredientId, Ingredient ingredient, String itemName) {
    setState(() {
      // Get existing terms from our working copy
      final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

      // Add new term with the next sort value
      terms.add(IngredientTerm(
        value: itemName,
        source: 'pantry', // Marked as coming from pantry item
        sort: terms.length, // Next position
      ));

      // Update the maps
      _ingredientTermsMap[ingredientId] = terms;

      // Mark as modified
      _modifiedIngredients[ingredientId] = ingredient.copyWith(terms: terms);
      
      // Ensure the accordion stays expanded
      _expandedIngredientIds.add(ingredientId);
    });
  }

  // Save all changes
  Future<void> saveChanges(WidgetRef ref) async {
    if (_modifiedIngredients.isEmpty) {
      print("No modifications to save");
      return;
    }
    
    print("Saving changes for ${_modifiedIngredients.length} ingredients");

    final repository = ref.read(recipeRepositoryProvider);

    // Get the original recipe to modify
    final recipeId = widget.matches.recipeId;
    print("Recipe ID: $recipeId");
    
    final recipeAsync = await repository.getRecipeById(recipeId);

    if (recipeAsync == null) {
      print("Error: Recipe not found");
      return;
    }

    // Important: Create a deep copy of the ingredients list to avoid modifying the original
    final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);
    print("Original ingredient count: ${ingredients.length}");

    // Debug: Print original ingredients and terms
    for (int i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      print("Ingredient $i: ${ing.id} - ${ing.name} - Terms: ${ing.terms?.map((t) => t.value).join(', ') ?? 'none'}");
    }

    // Replace ingredients with modified versions
    int updatedCount = 0;
    for (final entry in _modifiedIngredients.entries) {
      final ingredientId = entry.key;
      final updatedIngredient = entry.value;
      
      // Debug: Print terms for the updated ingredient
      print("Modified ingredient ${updatedIngredient.name}: Terms: ${updatedIngredient.terms?.map((t) => t.value).join(', ') ?? 'none'}");
      
      // Find the matching ingredient by ID
      final index = ingredients.indexWhere((ing) => ing.id == ingredientId);
      if (index >= 0) {
        print("Found matching ingredient at index $index");
        
        // Replace the ingredient in the list with our modified version
        ingredients[index] = updatedIngredient;
        updatedCount++;
      } else {
        print("Warning: Ingredient with ID $ingredientId not found in recipe");
      }
    }
    
    print("Updated $updatedCount ingredients");

    // Debug: Print final ingredients list after modifications
    for (int i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      print("Final ingredient $i: ${ing.id} - ${ing.name} - Terms: ${ing.terms?.map((t) => t.value).join(', ') ?? 'none'}");
    }

    // Save the updated recipe ingredients
    try {
      final result = await repository.updateIngredients(recipeId, ingredients);
      print("Save result: $result");
      if (result) {
        print("Successfully saved ingredient updates");
      } else {
        print("Failed to save ingredient updates: updateIngredients returned false");
      }
    } catch (e) {
      print("Error saving ingredients: $e");
    }
  }
}
