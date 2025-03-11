import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:uuid/uuid.dart';
import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/steps.dart';
import '../../../providers/recipe_provider.dart';

class RecipeEditorForm extends ConsumerStatefulWidget {
  final RecipeEntry? initialRecipe; // Null for new recipe, non-null for editing
  final VoidCallback? onSave;
  final bool autoSave;

  const RecipeEditorForm({
    Key? key,
    this.initialRecipe,
    this.onSave,
    this.autoSave = true,
  }) : super(key: key);

  @override
  ConsumerState<RecipeEditorForm> createState() => _RecipeEditorFormState();
}

class _RecipeEditorFormState extends ConsumerState<RecipeEditorForm> {
  late RecipeEntry _recipe;
  bool _isNewRecipe = false;
  bool _isInitialized = false;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _sourceController = TextEditingController();
  final _notesController = TextEditingController();

  // State for editable lists
  List<Ingredient> _ingredients = [];
  List<Step> _steps = [];

  // Focused field trackers
  int? _focusedIngredientIndex;
  int? _focusedStepIndex;

  @override
  void initState() {
    super.initState();
    _initializeRecipe();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeRecipe() {
    if (widget.initialRecipe != null) {
      // Editing an existing recipe
      _recipe = widget.initialRecipe!;
      _isNewRecipe = false;

      // Initialize controllers with existing values
      _titleController.text = _recipe.title;
      _descriptionController.text = _recipe.description ?? '';
      _servingsController.text = _recipe.servings?.toString() ?? '';
      _prepTimeController.text = _recipe.prepTime?.toString() ?? '';
      _cookTimeController.text = _recipe.cookTime?.toString() ?? '';
      _sourceController.text = _recipe.source ?? '';
      _notesController.text = _recipe.generalNotes ?? '';

      // Initialize lists
      _ingredients = _recipe.ingredients ?? [] as List<Ingredient>;
      _steps = _recipe.steps ?? [] as List<Step>;
    } else {
      // Creating a new recipe
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id ?? '';

      _recipe = RecipeEntry(
        id: const Uuid().v4(),
        title: 'New Recipe',
        language: 'en', // Default language
        userId: userId,
        ingredients: [],
        steps: [],
        folderIds: [],
      );

      _isNewRecipe = true;
      _titleController.text = _recipe.title;

      // Create the recipe in the database immediately if autoSave is enabled
      if (widget.autoSave) {
        _createInitialRecipe();
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _createInitialRecipe() async {
    if (!_isNewRecipe) return;

    try {
      final notifier = ref.read(recipeNotifierProvider.notifier);
      await notifier.addRecipe(
        title: _recipe.title,
        language: _recipe.language,
        userId: _recipe.userId,
        ingredients: _ingredients,
        steps: _steps,
      );

      // After creation, we're no longer dealing with a "new" recipe
      setState(() {
        _isNewRecipe = false;
      });
    } catch (e) {
      debugPrint('Error creating initial recipe: $e');
      // We'll allow the user to continue editing and try saving manually
    }
  }

  Future<void> _saveRecipe() async {
    if (!_isInitialized) return;

    try {
      final notifier = ref.read(recipeNotifierProvider.notifier);

      // Update recipe with current values
      final updatedRecipe = _recipe.copyWith(
        title: _titleController.text,
        description: Value(_descriptionController.text.isEmpty ? null : _descriptionController.text),
        servings: Value(int.tryParse(_servingsController.text)),
        prepTime: Value(int.tryParse(_prepTimeController.text)),
        cookTime: Value(int.tryParse(_cookTimeController.text)),
        source: Value(_sourceController.text.isEmpty ? null : _sourceController.text),
        generalNotes: Value(_notesController.text.isEmpty ? null : _notesController.text),
        ingredients: Value(_ingredients),
        steps: Value(_steps),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );

      if (_isNewRecipe) {
        await notifier.addRecipe(
          title: updatedRecipe.title,
          description: updatedRecipe.description,
          language: updatedRecipe.language,
          userId: updatedRecipe.userId,
          servings: updatedRecipe.servings,
          prepTime: updatedRecipe.prepTime,
          cookTime: updatedRecipe.cookTime,
          source: updatedRecipe.source,
          generalNotes: updatedRecipe.generalNotes,
          ingredients: updatedRecipe.ingredients,
          steps: updatedRecipe.steps,
        );
        setState(() {
          _isNewRecipe = false;
        });
      } else {
        await ref.read(recipeNotifierProvider.notifier).updateRecipe(updatedRecipe);
      }

      if (widget.onSave != null) {
        widget.onSave!();
      }
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
      );
    }
  }

  void _updateTitle(String value) {
    if (widget.autoSave && !_isNewRecipe) {
      final updatedRecipe = _recipe.copyWith(
        title: value,
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
      ref.read(recipeNotifierProvider.notifier).updateRecipe(updatedRecipe);
    }
  }

  void _updateDescription(String value) {
    if (widget.autoSave && !_isNewRecipe) {
      final updatedRecipe = _recipe.copyWith(
        description: Value(value.isEmpty ? null : value),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
      ref.read(recipeNotifierProvider.notifier).updateRecipe(updatedRecipe);
    }
  }

  // Add an ingredient to the list
  void _addIngredient({bool isSection = false}) {
    final newIngredient = Ingredient(
      type: isSection ? 'section' : 'ingredient',
      name: isSection ? 'New Section' : '',
      primaryAmount1Value: isSection ? null : '',
      primaryAmount1Unit: isSection ? null : 'g',
      primaryAmount1Type: isSection ? null : 'weight',
    );

    setState(() {
      _ingredients.add(newIngredient);
      _focusedIngredientIndex = _ingredients.length - 1;
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateIngredients(
        recipeId: _recipe.id,
        ingredients: _ingredients,
      );
    }
  }

  // Remove an ingredient from the list
  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _focusedIngredientIndex = null;
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateIngredients(
        recipeId: _recipe.id,
        ingredients: _ingredients,
      );
    }
  }

  // Update an ingredient in the list
  void _updateIngredient(int index, Ingredient updatedIngredient) {
    setState(() {
      _ingredients[index] = updatedIngredient;
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateIngredients(
        recipeId: _recipe.id,
        ingredients: _ingredients,
      );
    }
  }

  // Reorder ingredients
  void _reorderIngredients(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _ingredients.removeAt(oldIndex);
      _ingredients.insert(newIndex, item);
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateIngredients(
        recipeId: _recipe.id,
        ingredients: _ingredients,
      );
    }
  }

  // Add a step to the list
  void _addStep({bool isSection = false}) {
    final newStep = Step(
      type: isSection ? 'section' : 'step',
      text: isSection ? 'New Section' : '',
    );

    setState(() {
      _steps.add(newStep);
      _focusedStepIndex = _steps.length - 1;
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateSteps(
        recipeId: _recipe.id,
        steps: _steps,
      );
    }
  }

  // Remove a step from the list
  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      _focusedStepIndex = null;
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateSteps(
        recipeId: _recipe.id,
        steps: _steps,
      );
    }
  }

  // Update a step in the list
  void _updateStep(int index, Step updatedStep) {
    setState(() {
      _steps[index] = updatedStep;
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateSteps(
        recipeId: _recipe.id,
        steps: _steps,
      );
    }
  }

  // Reorder steps
  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });

    if (widget.autoSave && !_isNewRecipe) {
      ref.read(recipeNotifierProvider.notifier).updateSteps(
        recipeId: _recipe.id,
        steps: _steps,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Title
            CupertinoTextField(
              controller: _titleController,
              placeholder: "Recipe Title",
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              onChanged: _updateTitle,
              onEditingComplete: () {
                if (!widget.autoSave) {
                  _saveRecipe();
                }
              },
            ),
            const SizedBox(height: 16),

            // Recipe Description
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: "Description (optional)",
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              maxLines: 3,
              onChanged: _updateDescription,
              onEditingComplete: () {
                if (!widget.autoSave) {
                  _saveRecipe();
                }
              },
            ),
            const SizedBox(height: 16),

            // Recipe Details Row
            Row(
              children: [
                // Servings
                Expanded(
                  child: CupertinoTextField(
                    controller: _servingsController,
                    placeholder: "Servings",
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    keyboardType: TextInputType.number,
                    onEditingComplete: () {
                      if (!widget.autoSave) {
                        _saveRecipe();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Prep Time
                Expanded(
                  child: CupertinoTextField(
                    controller: _prepTimeController,
                    placeholder: "Prep Time (min)",
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    keyboardType: TextInputType.number,
                    onEditingComplete: () {
                      if (!widget.autoSave) {
                        _saveRecipe();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Cook Time
                Expanded(
                  child: CupertinoTextField(
                    controller: _cookTimeController,
                    placeholder: "Cook Time (min)",
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    keyboardType: TextInputType.number,
                    onEditingComplete: () {
                      if (!widget.autoSave) {
                        _saveRecipe();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Source Field
            CupertinoTextField(
              controller: _sourceController,
              placeholder: "Source (optional)",
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              onEditingComplete: () {
                if (!widget.autoSave) {
                  _saveRecipe();
                }
              },
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            const Text(
              "Ingredients",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Ingredients List
            if (_ingredients.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No ingredients added yet."),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                onReorder: _reorderIngredients,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return IngredientListItem(
                    key: ValueKey('ingredient_$index'),
                    ingredient: ingredient,
                    index: index,
                    isFocused: _focusedIngredientIndex == index,
                    onRemove: () => _removeIngredient(index),
                    onUpdate: (updatedIngredient) => _updateIngredient(index, updatedIngredient),
                    onAddNext: () {
                      _addIngredient();
                    },
                    onFocus: (isFocused) {
                      setState(() {
                        _focusedIngredientIndex = isFocused ? index : null;
                      });
                    },
                  );
                },
              ),

            // Add Ingredient/Section Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addIngredient(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addIngredient(isSection: true),
                    icon: const Icon(Icons.segment),
                    label: const Text('Add Section'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Steps Section
            const Text(
              "Instructions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Steps List
            if (_steps.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No steps added yet."),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorder: _reorderSteps,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return StepListItem(
                    key: ValueKey('step_$index'),
                    step: step,
                    index: index,
                    isFocused: _focusedStepIndex == index,
                    onRemove: () => _removeStep(index),
                    onUpdate: (updatedStep) => _updateStep(index, updatedStep),
                    onAddNext: () {
                      _addStep();
                    },
                    onFocus: (isFocused) {
                      setState(() {
                        _focusedStepIndex = isFocused ? index : null;
                      });
                    },
                  );
                },
              ),

            // Add Step/Section Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addStep(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addStep(isSection: true),
                    icon: const Icon(Icons.segment),
                    label: const Text('Add Section'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes Field
            const Text(
              "Notes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _notesController,
              placeholder: "General notes about this recipe",
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              maxLines: 4,
              onEditingComplete: () {
                if (!widget.autoSave) {
                  _saveRecipe();
                }
              },
            ),

            // Save Button (only shown if not in autoSave mode)
            if (!widget.autoSave)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  child: const Text('Save Recipe'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget for an Ingredient List Item
class IngredientListItem extends StatelessWidget {
  final Ingredient ingredient;
  final int index;
  final bool isFocused;
  final VoidCallback onRemove;
  final Function(Ingredient) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const IngredientListItem({
    Key? key,
    required this.ingredient,
    required this.index,
    required this.isFocused,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSection = ingredient.type == 'section';

    // For sections, just show a section title field
    if (isSection) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.segment),
          title: TextField(
            decoration: const InputDecoration(
              hintText: 'Section name',
              border: InputBorder.none,
            ),
            controller: TextEditingController(text: ingredient.name),
            style: const TextStyle(fontWeight: FontWeight.bold),
            onChanged: (value) {
              onUpdate(ingredient.copyWith(name: value));
            },
            onTap: () => onFocus(true),
            onEditingComplete: () => onFocus(false),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
      );
    }

    // For regular ingredients, show name and amount fields
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isFocused ? Colors.blue.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Remove button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),

          // Amount field
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(text: ingredient.primaryAmount1Value ?? ''),
              decoration: const InputDecoration(
                hintText: 'Amt',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                onUpdate(ingredient.copyWith(primaryAmount1Value: value));
              },
              onTap: () => onFocus(true),
            ),
          ),

          // Unit (hardcoded to 'g' for now)
          const Text('g', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),

          // Ingredient name field
          Expanded(
            child: TextField(
              controller: TextEditingController(text: ingredient.name),
              decoration: const InputDecoration(
                hintText: 'Ingredient name',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                onUpdate(ingredient.copyWith(name: value));
              },
              onTap: () => onFocus(true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => onAddNext(),
            ),
          ),

          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// Widget for a Step List Item
class StepListItem extends StatelessWidget {
  final Step step;
  final int index;
  final bool isFocused;
  final VoidCallback onRemove;
  final Function(Step) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const StepListItem({
    Key? key,
    required this.step,
    required this.index,
    required this.isFocused,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSection = step.type == 'section';

    // For sections, just show a section title field
    if (isSection) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.segment),
          title: TextField(
            decoration: const InputDecoration(
              hintText: 'Section name',
              border: InputBorder.none,
            ),
            controller: TextEditingController(text: step.text),
            style: const TextStyle(fontWeight: FontWeight.bold),
            onChanged: (value) {
              onUpdate(step.copyWith(text: value));
            },
            onTap: () => onFocus(true),
            onEditingComplete: () => onFocus(false),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
      );
    }

    // For regular steps
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isFocused ? Colors.blue.shade50 : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number or remove button
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: isFocused
                ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              onPressed: onRemove,
            )
                : Text(
              '${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Step description field
          Expanded(
            child: TextField(
              controller: TextEditingController(text: step.text),
              decoration: const InputDecoration(
                hintText: 'Describe this step',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              maxLines: null,
              minLines: 2,
              onChanged: (value) {
                onUpdate(step.copyWith(text: value));
              },
              onTap: () => onFocus(true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => onAddNext(),
            ),
          ),

          // Drag handle
          Column(
            children: [
              const SizedBox(height: 12),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
