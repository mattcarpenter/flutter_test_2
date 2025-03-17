import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_editor_form/sections/image_picker_section.dart';
import 'package:recipe_app/src/managers/upload_queue_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:uuid/uuid.dart';

import '../../../../../database/database.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../providers/recipe_provider.dart';
import 'sections/ingredients_section.dart';
import 'sections/recipe_metadata_section.dart';
import 'sections/steps_section.dart';

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
      images: Value(_recipe.images),
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
          images: updatedRecipe.images,
        );
        setState(() {
          _isNewRecipe = false;
        });
      } else {
        await notifier.updateRecipe(updatedRecipe);
      }

      // Add any pending images to the upload queue
      for (final image in updatedRecipe.images ?? []) {
        if (image.uploadStatus == "pending") {
          ref.read(uploadQueueManagerProvider).addToQueue(
            fileName: image.fileName,
            recipeId: updatedRecipe.id,
          );
        }
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
            // Recipe Metadata Section
            RecipeMetadataSection(
              titleController: _titleController,
              descriptionController: _descriptionController,
              servingsController: _servingsController,
              prepTimeController: _prepTimeController,
              cookTimeController: _cookTimeController,
              sourceController: _sourceController,
            ),

            const SizedBox(height: 24),

            ImagePickerSection(
              images: _recipe.images ?? [],
              onImagesUpdated: (newImages) {
                setState(() {
                  _recipe = _recipe.copyWith(images: Value(newImages));
                });
              },
            ),

            const SizedBox(height: 24),

            // Ingredients Section
            IngredientsSection(
              ingredients: _ingredients,
              autoFocusIngredientId: _autoFocusIngredientId,
              onAddIngredient: (bool isSection) => _addIngredient(isSection: isSection),
              onRemoveIngredient: _removeIngredient,
              onUpdateIngredient: _updateIngredient,
              onReorderIngredients: _reorderIngredients,
              onFocusChanged: (id, hasFocus) {
                if (!hasFocus && _autoFocusIngredientId == id) {
                  setState(() {
                    _autoFocusIngredientId = null;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Steps Section
            StepsSection(
              steps: _steps,
              autoFocusStepId: _autoFocusStepId,
              onAddStep: (bool isSection) => _addStep(isSection: isSection),
              onRemoveStep: _removeStep,
              onUpdateStep: _updateStep,
              onReorderSteps: _reorderSteps,
              onFocusChanged: (id, hasFocus) {
                if (!hasFocus && _autoFocusStepId == id) {
                  setState(() {
                    _autoFocusStepId = null;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Notes Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Notes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: "General notes about this recipe",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 4,
                ),
              ],
            ),

            // Save Button
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
