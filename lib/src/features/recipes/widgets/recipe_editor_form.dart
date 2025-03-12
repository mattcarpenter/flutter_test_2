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
  final RecipeEntry? initialRecipe; // null for new recipe, non-null for editing
  final VoidCallback? onSave;

  const RecipeEditorForm({
    Key? key,
    this.initialRecipe,
    this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<RecipeEditorForm> createState() => RecipeEditorFormState();
}

class RecipeEditorFormState extends ConsumerState<RecipeEditorForm> {
  late RecipeEntry _recipe;
  bool _isNewRecipe = false;
  bool _isInitialized = false;

  // Controllers for recipe fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _sourceController = TextEditingController();
  final _notesController = TextEditingController();

  // Local state for editable lists
  List<Ingredient> _ingredients = [];
  List<Step> _steps = [];

  // Flags for auto-focusing new items
  String? _autoFocusIngredientId;
  String? _autoFocusStepId;

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
      // Update scenario: pre-populate fields.
      _recipe = widget.initialRecipe!;
      _isNewRecipe = false;
      _titleController.text = _recipe.title;
      _descriptionController.text = _recipe.description ?? '';
      _servingsController.text = _recipe.servings?.toString() ?? '';
      _prepTimeController.text = _recipe.prepTime?.toString() ?? '';
      _cookTimeController.text = _recipe.cookTime?.toString() ?? '';
      _sourceController.text = _recipe.source ?? '';
      _notesController.text = _recipe.generalNotes ?? '';
      _ingredients = List<Ingredient>.from(_recipe.ingredients ?? []);
      _steps = List<Step>.from(_recipe.steps ?? []);
    } else {
      // New recipe: initialize local state.
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id ?? '';
      _recipe = RecipeEntry(
        id: const Uuid().v4(),
        title: 'New Recipe',
        language: 'en',
        userId: userId,
        ingredients: [],
        steps: [],
        folderIds: [],
      );
      _isNewRecipe = true;
      _titleController.text = _recipe.title;
    }
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> saveRecipe() async {
    if (!_isInitialized) return;
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

    try {
      final notifier = ref.read(recipeNotifierProvider.notifier);
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
        await notifier.updateRecipe(updatedRecipe);
      }
      if (widget.onSave != null) widget.onSave!();
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recipe: $e')));
    }
  }

  // Ingredient operations
  void _addIngredient({bool isSection = false}) {
    final newIngredient = Ingredient(
      id: const Uuid().v4(),
      type: isSection ? 'section' : 'ingredient',
      name: isSection ? 'New Section' : '',
      primaryAmount1Value: isSection ? null : '',
      primaryAmount1Unit: isSection ? null : 'g',
      primaryAmount1Type: isSection ? null : 'weight',
    );
    setState(() {
      _ingredients.add(newIngredient);
      _autoFocusIngredientId = newIngredient.id;
    });
  }

  void _removeIngredient(String id) {
    setState(() {
      _ingredients.removeWhere((ingredient) => ingredient.id == id);
      if (_autoFocusIngredientId == id) _autoFocusIngredientId = null;
    });
  }

  void _updateIngredient(String id, Ingredient updatedIngredient) {
    final index = _ingredients.indexWhere((ingredient) => ingredient.id == id);
    if (index == -1) return;
    setState(() {
      _ingredients[index] = updatedIngredient;
    });
  }

  void _reorderIngredients(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _ingredients.removeAt(oldIndex);
      _ingredients.insert(newIndex, item);
    });
  }

  // Step operations
  void _addStep({bool isSection = false}) {
    final newStep = Step(
      id: const Uuid().v4(),
      type: isSection ? 'section' : 'step',
      text: isSection ? 'New Section' : '',
    );
    setState(() {
      _steps.add(newStep);
      _autoFocusStepId = newStep.id;
    });
  }

  void _removeStep(String id) {
    setState(() {
      _steps.removeWhere((step) => step.id == id);
      if (_autoFocusStepId == id) _autoFocusStepId = null;
    });
  }

  void _updateStep(String id, Step updatedStep) {
    final index = _steps.indexWhere((step) => step.id == id);
    if (index == -1) return;
    setState(() {
      _steps[index] = updatedStep;
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());
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
            ),
            const SizedBox(height: 16),
            // Recipe Details Row
            Row(
              children: [
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
                  ),
                ),
                const SizedBox(width: 8),
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
                  ),
                ),
                const SizedBox(width: 8),
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
            ),
            const SizedBox(height: 24),
            // Ingredients Section
            const Text(
              "Ingredients",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_ingredients.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No ingredients added yet."),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                    child: child,
                  );
                },
                itemCount: _ingredients.length,
                onReorder: _reorderIngredients,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return IngredientListItem(
                    key: ValueKey(ingredient.id),
                    index: index,
                    ingredient: ingredient,
                    autoFocus: _autoFocusIngredientId == ingredient.id,
                    onRemove: () => _removeIngredient(ingredient.id),
                    onUpdate: (updatedIngredient) =>
                        _updateIngredient(ingredient.id, updatedIngredient),
                    onAddNext: _addIngredient,
                    onFocus: (hasFocus) {
                      if (!hasFocus && _autoFocusIngredientId == ingredient.id) {
                        setState(() {
                          _autoFocusIngredientId = null;
                        });
                      }
                    },
                  );
                },
              ),
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
            if (_steps.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No steps added yet."),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                    child: child,
                  );
                },
                itemCount: _steps.length,
                onReorder: _reorderSteps,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return StepListItem(
                    key: ValueKey(step.id),
                    index: index,
                    step: step,
                    autoFocus: _autoFocusStepId == step.id,
                    onRemove: () => _removeStep(step.id),
                    onUpdate: (updatedStep) => _updateStep(step.id, updatedStep),
                    onAddNext: _addStep,
                    onFocus: (hasFocus) {
                      if (!hasFocus && _autoFocusStepId == step.id) {
                        setState(() {
                          _autoFocusStepId = null;
                        });
                      }
                    },
                  );
                },
              ),
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
            ),
            // Done Button to commit changes
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: saveRecipe,
                child: Text(_isNewRecipe ? 'Create Recipe' : 'Update Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------
// Ingredient List Item
// --------------------
class IngredientListItem extends StatefulWidget {
  final int index;
  final Ingredient ingredient;
  final bool autoFocus;
  final VoidCallback onRemove;
  final Function(Ingredient) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const IngredientListItem({
    Key? key,
    required this.index,
    required this.ingredient,
    required this.autoFocus,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  _IngredientListItemState createState() => _IngredientListItemState();
}

class _IngredientListItemState extends State<IngredientListItem> {
  late TextEditingController _nameController;
  TextEditingController? _amountController;
  late FocusNode _focusNode;

  bool get isSection => widget.ingredient.type == 'section';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    if (!isSection) {
      _amountController = TextEditingController(text: widget.ingredient.primaryAmount1Value ?? '');
    }
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus(_focusNode.hasFocus);
      setState(() {}); // update background color
    });
    if (widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant IngredientListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredient.name != widget.ingredient.name &&
        _nameController.text != widget.ingredient.name) {
      _nameController.text = widget.ingredient.name;
    }
    if (!isSection &&
        oldWidget.ingredient.primaryAmount1Value != widget.ingredient.primaryAmount1Value) {
      _amountController?.text = widget.ingredient.primaryAmount1Value ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _focusNode.hasFocus ? Colors.blue.shade50 : Colors.white;
    if (isSection) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.segment),
          title: Focus(
            focusNode: _focusNode,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Section name',
                border: InputBorder.none,
              ),
              controller: _nameController,
              style: const TextStyle(fontWeight: FontWeight.bold),
              onChanged: (value) {
                widget.onUpdate(widget.ingredient.copyWith(name: value));
              },
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.onRemove,
              ),
              SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                hintText: 'Amt',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                widget.onUpdate(widget.ingredient.copyWith(primaryAmount1Value: value));
              },
            ),
          ),
          const Text('g', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ingredient name',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  widget.onUpdate(widget.ingredient.copyWith(name: value));
                },
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => widget.onAddNext(),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: ReorderableDragStartListener(
              index: widget.index,
              child: const Icon(Icons.drag_handle),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// --------------------
// Step List Item
// --------------------
class StepListItem extends StatefulWidget {
  final int index;
  final Step step;
  final bool autoFocus;
  final VoidCallback onRemove;
  final Function(Step) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const StepListItem({
    Key? key,
    required this.index,
    required this.step,
    required this.autoFocus,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  _StepListItemState createState() => _StepListItemState();
}

class _StepListItemState extends State<StepListItem> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  bool get isSection => widget.step.type == 'section';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.step.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus(_focusNode.hasFocus);
      setState(() {});
    });
    if (widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant StepListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.text != widget.step.text &&
        _textController.text != widget.step.text) {
      _textController.text = widget.step.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _focusNode.hasFocus ? Colors.blue.shade50 : Colors.white;
    if (isSection) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.segment),
          title: Focus(
            focusNode: _focusNode,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Section name',
                border: InputBorder.none,
              ),
              controller: _textController,
              style: const TextStyle(fontWeight: FontWeight.bold),
              onChanged: (value) {
                widget.onUpdate(widget.step.copyWith(text: value));
              },
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.onRemove,
              ),
              SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: _focusNode.hasFocus
                ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              onPressed: widget.onRemove,
            )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Describe this step',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                maxLines: null,
                minLines: 2,
                onChanged: (value) {
                  widget.onUpdate(widget.step.copyWith(text: value));
                },
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => widget.onAddNext(),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: ReorderableDragStartListener(
              index: widget.index,
              child: const Icon(Icons.drag_handle),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
