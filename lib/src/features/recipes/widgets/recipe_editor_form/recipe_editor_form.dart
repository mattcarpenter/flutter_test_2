import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_editor_form/sections/image_picker_section.dart';
import 'package:recipe_app/src/managers/upload_queue_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:uuid/uuid.dart';

import '../../../../theme/spacing.dart';

import '../../../../../database/database.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../repositories/recipe_repository.dart';
import '../../../../widgets/section_header.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/app_text_field_condensed.dart';
import '../../../../widgets/app_text_field_group.dart';
import 'sections/ingredients_section.dart';
import 'sections/recipe_metadata_section.dart';
import 'sections/steps_section.dart';
import 'items/tag_chips_row.dart';
import '../tag_selection_modal.dart';

class RecipeEditorForm extends ConsumerStatefulWidget {
  final RecipeEntry? initialRecipe; // null for new recipe, non-null for editing
  final VoidCallback? onSave;
  final String? folderId;

  const RecipeEditorForm({
    super.key,
    this.initialRecipe,
    this.onSave,
    this.folderId,
  });

  @override
  ConsumerState<RecipeEditorForm> createState() => RecipeEditorFormState();
}

class RecipeEditorFormState extends ConsumerState<RecipeEditorForm> {
  late RecipeEntry _recipe;
  late String? folderId;
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

  // Scroll controller for the main form
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
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
      final List<String> folderIds = widget.folderId != null ? [widget.folderId!] : [];
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id ?? '';
      _recipe = RecipeEntry(
        id: const Uuid().v4(),
        title: 'New Recipe',
        language: 'en',
        userId: userId,
        ingredients: [],
        steps: [],
        folderIds: folderIds,
        pinned: 0,
        pinnedAt: null,
      );
      _isNewRecipe = true;
      _titleController.text = _recipe.title;
    }
    setState(() {
      _isInitialized = true;
    });
  }

  // Handle folder assignment changes
  void _updateFolderIds(List<String> newFolderIds) {
    setState(() {
      _recipe = _recipe.copyWith(folderIds: Value(newFolderIds));
    });
  }

  Future<void> saveRecipe() async {
    if (!_isInitialized) return;
    // Build your updatedRecipe from form state.
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
      folderIds: Value(_recipe.folderIds),
      tagIds: Value(_recipe.tagIds),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    try {
      final notifier = ref.read(recipeNotifierProvider.notifier);
      if (_isNewRecipe) {
        await notifier.addRecipe(
          id: updatedRecipe.id,
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
          folderIds: updatedRecipe.folderIds,
          tagIds: updatedRecipe.tagIds,
        );
        setState(() {
          _isNewRecipe = false;
        });
      } else {
        // Merge with current DB state before saving, so that any publicUrls are preserved.
        final mergedRecipe = await mergeRecipeImagesWithDb(updatedRecipe);
        await notifier.updateRecipe(mergedRecipe); // was mergedRecipe
      }

      // Add any pending images to the upload queue (only if user is authenticated).
      final currentUser = supabase_flutter.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        for (final image in updatedRecipe.images ?? []) {
          // Even if the image was updated by the processor, addToQueue should be a no-op if already uploaded.
          if (image.publicUrl == null) {
            ref.read(uploadQueueManagerProvider).addToQueue(
              fileName: image.fileName,
              recipeId: updatedRecipe.id,
            );
          }
        }
      }

      if (widget.onSave != null) widget.onSave!();
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
      );
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

    // Don't unfocus - let Flutter handle the focus transition smoothly
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
    // Don't unfocus - let Flutter handle the focus transition smoothly
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

  Future<RecipeEntry> mergeRecipeImagesWithDb(RecipeEntry localRecipe) async {
    // Fetch the current recipe from the database. Use a repository method or direct DB query.
    // Here we use a method getRecipeById (you need to implement this in your repository if not already available).
    final dbRecipe = await ref.read(recipeRepositoryProvider).getRecipeById(localRecipe.id);

    if (dbRecipe == null) {
      // If no recipe exists in the DB (should not happen for updates), return local state.
      return localRecipe;
    }

    // Get image lists from both local and DB.
    final localImages = localRecipe.images ?? [];
    final dbImages = dbRecipe.images ?? [];

    // Merge: for each local image, if a matching image (by fileName) exists in the DB with a publicUrl,
    // update the local image's publicUrl.
    final mergedImages = localImages.map((localImage) {
      final matchingDbImage = dbImages.firstWhere(
            (dbImg) => dbImg.fileName == localImage.fileName,
        orElse: () => localImage,
      );
      if (matchingDbImage.publicUrl != null && matchingDbImage.publicUrl!.isNotEmpty) {
        return localImage.copyWith(publicUrl: matchingDbImage.publicUrl);
      }
      return localImage;
    }).toList();

    // Return an updated RecipeEntry with the merged images.
    return localRecipe.copyWith(images: Value(mergedImages));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
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
              currentFolderIds: _recipe.folderIds ?? [],
              onFolderIdsChanged: _updateFolderIds,
            ),

            // Images Section Header
            const SectionHeader(
              "Add Images",
              topSpacing: AppSpacing.xl,
            ),

            // Images Section with edge-to-edge scrolling
            Transform.translate(
              offset: const Offset(-16, 0), // Shift left to compensate for padding
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width, // More efficient - only rebuilds on size changes
                child: ImagePickerSection(
                  images: _recipe.images ?? [],
                  onImagesUpdated: (newImages) {
                    setState(() {
                      _recipe = _recipe.copyWith(images: Value(newImages));
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Ingredients Section Header
            const SectionHeader(
              "Add Ingredients",
              topSpacing: 0,
            ),

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

            const SizedBox(height: AppSpacing.xl),

            // Steps Section Header
            const SectionHeader(
              "Add Instructions",
              topSpacing: 0,
            ),

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

            const SizedBox(height: AppSpacing.xl),

            // Notes Section Header
            const SectionHeader(
              "Add Notes",
              topSpacing: 0,
            ),

            // Source and Notes grouped together
            AppTextFieldGroup(
              variant: AppTextFieldVariant.outline,
              children: [
                AppTextFieldCondensed(
                  controller: _sourceController,
                  placeholder: "Source (optional)",
                  keyboardType: TextInputType.url,
                  grouped: true,
                ),
                AppTextFieldCondensed(
                  controller: _notesController,
                  placeholder: "General notes about this recipe",
                  multiline: true,
                  minLines: 2,
                  grouped: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Tags Section
            TagChipsRow(
              tagIds: _recipe.tagIds ?? [],
              onEditTags: () {
                showTagSelectionModal(
                  context,
                  currentTagIds: _recipe.tagIds ?? [],
                  onTagIdsChanged: _updateTagIds,
                  ref: ref,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateTagIds(List<String> newTagIds) {
    setState(() {
      _recipe = _recipe.copyWith(tagIds: Value(newTagIds));
    });
  }
}
