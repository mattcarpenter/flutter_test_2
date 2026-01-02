import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_editor_form/sections/image_picker_section.dart';
import 'package:recipe_app/src/managers/upload_queue_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:uuid/uuid.dart';

import '../../../../theme/spacing.dart';
import '../../../../services/logging/app_logger.dart';
import '../../../../localization/l10n_extension.dart';

import '../../../../../database/database.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../repositories/recipe_repository.dart';
import '../../../../widgets/section_header.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/app_text_field_condensed.dart';
import '../../../../widgets/app_text_field_group.dart';
import '../../../../widgets/star_rating.dart';
import 'sections/ingredients_section.dart';
import 'sections/recipe_metadata_section.dart';
import 'sections/steps_section.dart';
import 'items/tag_chips_row.dart';
import '../tag_selection_modal.dart';
import '../../../../services/ingredient_parser_service.dart';
import 'modals/edit_as_text_modal.dart';

class RecipeEditorForm extends ConsumerStatefulWidget {
  final RecipeEntry? initialRecipe; // null for new recipe, non-null for editing
  final VoidCallback? onSave;
  final String? folderId;
  /// Explicitly controls whether this is a new recipe (uses addRecipe) or
  /// editing existing (uses updateRecipe). Defaults to `initialRecipe == null`.
  /// Set to true when pre-populating a new recipe (e.g., from AI extraction).
  final bool? isNewRecipe;

  const RecipeEditorForm({
    super.key,
    this.initialRecipe,
    this.onSave,
    this.folderId,
    this.isNewRecipe,
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

  // Parser for detecting ingredient name changes
  final _parser = IngredientParserService();

  bool _didSetLocalizedTitle = false;

  @override
  void initState() {
    super.initState();
    _initializeRecipe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set localized title for new recipes after context is available
    if (!_didSetLocalizedTitle && _isNewRecipe && widget.initialRecipe == null) {
      _didSetLocalizedTitle = true;
      final localizedTitle = context.l10n.recipeEditorNewRecipe;
      _recipe = _recipe.copyWith(title: localizedTitle);
      _titleController.text = localizedTitle;
    }
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
    // Determine if this is a new recipe:
    // - Use explicit isNewRecipe parameter if provided
    // - Otherwise, infer from initialRecipe == null (backwards compatible)
    _isNewRecipe = widget.isNewRecipe ?? (widget.initialRecipe == null);

    if (widget.initialRecipe != null) {
      // Pre-populate fields from provided recipe
      _recipe = widget.initialRecipe!;
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
      // New recipe: initialize empty state
      // Note: title will be set to localized value in didChangeDependencies()
      final List<String> folderIds = widget.folderId != null ? [widget.folderId!] : [];
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id ?? '';
      _recipe = RecipeEntry(
        id: const Uuid().v4(),
        title: '', // Placeholder, will be set in didChangeDependencies
        language: 'en',
        userId: userId,
        ingredients: [],
        steps: [],
        folderIds: folderIds,
        pinned: 0,
        pinnedAt: null,
      );
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
      AppLogger.error('Error saving recipe', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.recipeEditorSaveFailed(e.toString()))),
      );
    }
  }


  // Ingredient operations
  void _addIngredient({bool isSection = false}) {
    final newIngredient = Ingredient(
      id: const Uuid().v4(),
      type: isSection ? 'section' : 'ingredient',
      name: isSection ? context.l10n.recipeEditorNewSection : '',
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

    final oldIngredient = _ingredients[index];
    Ingredient finalIngredient = updatedIngredient;

    // Only check name changes for regular ingredients (not sections)
    if (updatedIngredient.type == 'ingredient') {
      // Parse names to extract just the ingredient name (without quantities/units)
      final oldParsed = _parser.parse(oldIngredient.name);
      final newParsed = _parser.parse(updatedIngredient.name);

      final oldCleanName = oldParsed.cleanName.toLowerCase().trim();
      final newCleanName = newParsed.cleanName.toLowerCase().trim();

      // If ingredient name changed (not just quantity/unit), clear terms and re-canonicalize
      if (oldCleanName != newCleanName && newCleanName.isNotEmpty) {
        finalIngredient = updatedIngredient.copyWith(
          terms: [],                    // Clear ALL terms (API + user-added)
          isCanonicalised: false,       // Mark for re-canonicalization
          category: null,                // Clear category
        );
      }
    }

    setState(() {
      _ingredients[index] = finalIngredient;
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
      text: isSection ? context.l10n.recipeEditorNewSection : '',
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

  // Clear all operations
  Future<void> _clearAllIngredients() async {
    if (_ingredients.isEmpty) return;

    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.recipeEditorClearAllIngredients),
        content: Text(
          l10n.recipeEditorClearConfirm(_ingredients.length, _ingredients.length == 1 ? 'ingredient' : 'ingredients'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recipeEditorClearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _ingredients = [];
        _autoFocusIngredientId = null;
      });
    }
  }

  Future<void> _clearAllSteps() async {
    if (_steps.isEmpty) return;

    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.recipeEditorClearAllSteps),
        content: Text(
          l10n.recipeEditorClearConfirm(_steps.length, _steps.length == 1 ? 'step' : 'steps'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recipeEditorClearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _steps = [];
        _autoFocusStepId = null;
      });
    }
  }

  // Edit as Text operations
  Future<void> _openEditIngredientsAsText() async {
    final result = await showEditIngredientsAsTextModal(
      context,
      ingredients: _ingredients,
      ref: ref,
    );
    if (result != null) {
      setState(() {
        _ingredients = result;
      });
    }
  }

  Future<void> _openEditStepsAsText() async {
    final result = await showEditStepsAsTextModal(
      context,
      steps: _steps,
    );
    if (result != null) {
      setState(() {
        _steps = result;
      });
    }
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
            SectionHeader(
              context.l10n.recipeEditorAddImages,
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
            SectionHeader(
              context.l10n.recipeEditorAddIngredients,
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
              onEditAsText: _openEditIngredientsAsText,
              onClearAll: _clearAllIngredients,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Steps Section Header
            SectionHeader(
              context.l10n.recipeEditorAddInstructions,
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
              onEditAsText: _openEditStepsAsText,
              onClearAll: _clearAllSteps,
              scrollController: _scrollController,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Notes Section Header
            SectionHeader(
              context.l10n.recipeEditorAddNotes,
              topSpacing: 0,
            ),

            // Source and Notes grouped together
            AppTextFieldGroup(
              variant: AppTextFieldVariant.outline,
              children: [
                AppTextFieldCondensed(
                  controller: _sourceController,
                  placeholder: context.l10n.recipeEditorSourcePlaceholder,
                  valueHint: context.l10n.commonEnterValue,
                  keyboardType: TextInputType.url,
                  grouped: true,
                ),
                AppTextFieldCondensed(
                  controller: _notesController,
                  placeholder: context.l10n.recipeEditorNotesPlaceholder,
                  multiline: true,
                  minLines: 2,
                  grouped: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Rating Section Header
            SectionHeader(
              context.l10n.recipeEditorRating,
              topSpacing: 0,
            ),

            // Rating Widget
            StarRating(
              rating: _recipe.rating,
              onRatingChanged: _updateRating,
              size: StarRatingSize.large,
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

  void _updateRating(int newRating) {
    setState(() {
      _recipe = _recipe.copyWith(rating: Value(newRating == 0 ? null : newRating));
    });
  }
}
