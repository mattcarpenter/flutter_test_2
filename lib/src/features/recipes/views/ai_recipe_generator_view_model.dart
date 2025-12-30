import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/ai_recipe_service.dart';
import '../../../services/logging/app_logger.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../clippings/models/recipe_preview.dart';
import '../../clippings/providers/preview_usage_provider.dart';
import '../models/recipe_idea.dart';

/// State machine for the AI Recipe Generator
enum AiGeneratorState {
  inputting,          // User entering prompt
  brainstorming,      // Calling brainstorm-recipes endpoint
  showingResults,     // Displaying recipe ideas
  generatingRecipe,   // Calling generate-recipe endpoint
  showingPreview,     // Showing preview for non-Plus users
  error,              // Error occurred
}

/// ViewModel for the AI Recipe Generator modal.
///
/// Manages state across both pages of the modal using ChangeNotifier.
/// Uses the AI Recipe Service for backend communication.
class AiRecipeGeneratorViewModel extends ChangeNotifier {
  final WidgetRef ref;
  final String? folderId;

  // State
  AiGeneratorState _state = AiGeneratorState.inputting;
  String _errorMessage = '';
  bool _isRateLimitError = false;
  bool _usePantryItems = false;
  List<RecipeIdea> _recipeIdeas = [];
  RecipeIdea? _selectedIdea;
  bool _isTransitioning = false;

  // Original prompt (stored when brainstorming starts)
  String _originalPrompt = '';

  // Pantry items that were checked when brainstorming
  List<String> _selectedPantryItems = [];

  // Quill controller for input
  late quill.QuillController _inputController;

  // Pantry items (cached on init)
  List<PantryItemEntry> _availablePantryItems = [];

  // Extraction result for Plus users
  ExtractedRecipe? _extractedRecipe;

  // Preview result for non-Plus users
  RecipePreview? _recipePreview;

  AiRecipeGeneratorViewModel({
    required this.ref,
    this.folderId,
  }) {
    _inputController = quill.QuillController.basic();
    _loadPantryItems();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ============================================================================
  // Getters
  // ============================================================================

  AiGeneratorState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isRateLimitError => _isRateLimitError;
  bool get usePantryItems => _usePantryItems;
  List<RecipeIdea> get recipeIdeas => _recipeIdeas;
  RecipeIdea? get selectedIdea => _selectedIdea;
  bool get isTransitioning => _isTransitioning;
  quill.QuillController get inputController => _inputController;
  List<PantryItemEntry> get availablePantryItems => _availablePantryItems;
  bool get hasPantryItems => _availablePantryItems.isNotEmpty;
  ExtractedRecipe? get extractedRecipe => _extractedRecipe;
  RecipePreview? get recipePreview => _recipePreview;
  String get originalPrompt => _originalPrompt;
  List<String> get selectedPantryItems => _selectedPantryItems;

  /// Returns true if the input has content
  bool get hasInput {
    final text = _inputController.document.toPlainText().trim();
    return text.isNotEmpty && text != '\n';
  }

  /// Returns true if user has Plus subscription
  bool get hasPlus => ref.read(effectiveHasPlusProvider);

  // ============================================================================
  // Pantry Items
  // ============================================================================

  Future<void> _loadPantryItems() async {
    final pantryAsync = ref.read(pantryNotifierProvider);
    _availablePantryItems = pantryAsync.whenData((items) {
      // Filter to in-stock and low-stock only
      return items.where((item) =>
        item.stockStatus != StockStatus.outOfStock
      ).toList();
    }).value ?? [];
    notifyListeners();
  }

  /// Toggle use pantry items switch
  void toggleUsePantryItems(bool value) {
    _usePantryItems = value;
    if (value) {
      _appendPantryItemsToEditor();
    } else {
      _removePantryItemsFromEditor();
    }
    notifyListeners();
  }

  /// Append pantry items as checkable items to the editor
  void _appendPantryItemsToEditor() {
    if (_availablePantryItems.isEmpty) return;

    final document = _inputController.document;
    final currentLength = document.length;

    // Add header
    document.insert(currentLength - 1, '\n\nAvailable ingredients:\n');

    // Add each pantry item as a checked checklist item
    for (final item in _availablePantryItems) {
      final insertPos = document.length - 1;
      document.insert(insertPos, '${item.name}\n');

      // Apply checklist format - checked by default so users can uncheck items they don't want
      _inputController.formatText(
        insertPos,
        item.name.length + 1,
        quill.Attribute.unchecked,
      );
      // Then check it
      _inputController.formatText(
        insertPos,
        item.name.length + 1,
        quill.Attribute.checked,
      );
    }

    notifyListeners();
  }

  /// Remove pantry items from the editor
  void _removePantryItemsFromEditor() {
    // Find and remove the "Available ingredients:" section and items after it
    final plainText = _inputController.document.toPlainText();
    final marker = '\n\nAvailable ingredients:\n';
    final markerIndex = plainText.indexOf(marker);

    if (markerIndex == -1) return;

    // Create new document with content before the marker
    final textBefore = plainText.substring(0, markerIndex);
    _inputController.document = quill.Document()..insert(0, textBefore.isEmpty ? '' : textBefore);

    notifyListeners();
  }

  /// Get list of pantry items that are still checked (for sending to API)
  List<String> _getCheckedPantryItems() {
    if (!_usePantryItems) return [];

    final checkedItems = <String>[];
    final document = _inputController.document;
    final delta = document.toDelta();

    // Parse document to find checked items
    String currentText = '';
    bool isChecked = false;

    for (final op in delta.toList()) {
      if (op.data is String) {
        currentText = (op.data as String).trim();
      }
      if (op.attributes != null) {
        final listType = op.attributes!['list'];
        if (listType == 'checked' && currentText.isNotEmpty) {
          isChecked = true;
        }
      }
      if (isChecked && currentText.isNotEmpty) {
        // Only add if it's actually a pantry item name
        if (_availablePantryItems.any((item) => item.name == currentText)) {
          checkedItems.add(currentText);
        }
        isChecked = false;
        currentText = '';
      }
    }

    return checkedItems;
  }

  /// Get the user's prompt text (excluding the pantry items section)
  String _getPromptText() {
    final plainText = _inputController.document.toPlainText();
    final marker = '\n\nAvailable ingredients:';
    final markerIndex = plainText.indexOf(marker);

    if (markerIndex != -1) {
      return plainText.substring(0, markerIndex).trim();
    }
    return plainText.trim();
  }

  // ============================================================================
  // State Transitions
  // ============================================================================

  /// Transition to a new state with animation
  Future<void> _transitionToState(AiGeneratorState newState) async {
    if (_isTransitioning || _state == newState) return;

    _isTransitioning = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200)); // Fade-out time

    _state = newState;
    _isTransitioning = false;
    notifyListeners();
  }

  /// Reset to input state for retrying
  void resetToInput() {
    _state = AiGeneratorState.inputting;
    _errorMessage = '';
    _isRateLimitError = false;
    _recipeIdeas = [];
    _selectedIdea = null;
    _extractedRecipe = null;
    _recipePreview = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      _isRateLimitError = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // API Operations
  // ============================================================================

  /// Generate recipe ideas from user prompt
  Future<void> generateIdeas() async {
    // Store the original prompt and selected pantry items
    _originalPrompt = _getPromptText();
    _selectedPantryItems = _getCheckedPantryItems();

    // Check if non-Plus user has exceeded daily limit
    if (!hasPlus) {
      final usageService = await ref.read(previewUsageServiceProvider.future);
      if (!usageService.hasIdeaGenerationsRemaining()) {
        _state = AiGeneratorState.error;
        _errorMessage = 'Daily idea generation limit reached. Upgrade to Plus for unlimited access.';
        _isRateLimitError = true;
        notifyListeners();
        return;
      }
    }

    await _transitionToState(AiGeneratorState.brainstorming);

    try {
      final service = ref.read(aiRecipeServiceProvider);
      final result = await service.brainstormRecipes(
        prompt: _originalPrompt,
        pantryItems: _selectedPantryItems.isNotEmpty ? _selectedPantryItems : null,
      );

      if (!result.success || result.ideas.isEmpty) {
        await _transitionToState(AiGeneratorState.error);
        _errorMessage = result.errorMessage ??
            "I couldn't think of recipes based on that description. Try being more specific.";
        _isRateLimitError = false;
        notifyListeners();
        return;
      }

      // Increment usage for non-Plus users
      if (!hasPlus) {
        final usageService = await ref.read(previewUsageServiceProvider.future);
        await usageService.incrementIdeaUsage();
      }

      _recipeIdeas = result.ideas;
      await _transitionToState(AiGeneratorState.showingResults);

      AppLogger.info('Generated ${result.ideas.length} recipe ideas');
    } on AiRecipeException catch (e) {
      await _transitionToState(AiGeneratorState.error);
      _errorMessage = e.message;
      _isRateLimitError = e.isRateLimitError;
      notifyListeners();
    } catch (e, stack) {
      AppLogger.error('Brainstorming failed', e, stack);
      await _transitionToState(AiGeneratorState.error);
      _errorMessage = 'Something went wrong. Please try again.';
      _isRateLimitError = false;
      notifyListeners();
    }
  }

  /// Select a recipe idea and generate the full recipe
  Future<void> selectIdea(RecipeIdea idea) async {
    _selectedIdea = idea;
    notifyListeners();

    if (hasPlus) {
      // Plus user - generate full recipe
      await _generateFullRecipe(idea);
    } else {
      // Non-Plus user - generate preview
      await _generatePreview(idea);
    }
  }

  /// Generate full recipe (for Plus users)
  Future<void> _generateFullRecipe(RecipeIdea idea) async {
    await _transitionToState(AiGeneratorState.generatingRecipe);

    try {
      final service = ref.read(aiRecipeServiceProvider);
      final result = await service.generateRecipe(
        idea: idea,
        originalPrompt: _originalPrompt,
        pantryItems: _selectedPantryItems.isNotEmpty ? _selectedPantryItems : null,
      );

      if (!result.success || result.recipe == null) {
        await _transitionToState(AiGeneratorState.error);
        _errorMessage = result.errorMessage ??
            'Unable to generate recipe. Please try another idea.';
        _isRateLimitError = false;
        notifyListeners();
        return;
      }

      _extractedRecipe = result.recipe;
      // State stays at generatingRecipe - the UI will navigate to editor
      notifyListeners();

      AppLogger.info('Generated recipe: ${result.recipe!.title}');
    } on AiRecipeException catch (e) {
      await _transitionToState(AiGeneratorState.error);
      _errorMessage = e.message;
      _isRateLimitError = e.isRateLimitError;
      notifyListeners();
    } catch (e, stack) {
      AppLogger.error('Recipe generation failed', e, stack);
      await _transitionToState(AiGeneratorState.error);
      _errorMessage = 'Something went wrong. Please try again.';
      _isRateLimitError = false;
      notifyListeners();
    }
  }

  /// Generate preview (for non-Plus users)
  Future<void> _generatePreview(RecipeIdea idea) async {
    await _transitionToState(AiGeneratorState.generatingRecipe);

    try {
      final service = ref.read(aiRecipeServiceProvider);
      final result = await service.generatePreview(idea: idea);

      if (!result.success || result.preview == null) {
        await _transitionToState(AiGeneratorState.error);
        _errorMessage = result.errorMessage ??
            'Unable to generate preview. Please try another idea.';
        _isRateLimitError = false;
        notifyListeners();
        return;
      }

      _recipePreview = result.preview;
      await _transitionToState(AiGeneratorState.showingPreview);

      AppLogger.info('Generated preview: ${result.preview!.title}');
    } on AiRecipeException catch (e) {
      await _transitionToState(AiGeneratorState.error);
      _errorMessage = e.message;
      _isRateLimitError = e.isRateLimitError;
      notifyListeners();
    } catch (e, stack) {
      AppLogger.error('Preview generation failed', e, stack);
      await _transitionToState(AiGeneratorState.error);
      _errorMessage = 'Something went wrong. Please try again.';
      _isRateLimitError = false;
      notifyListeners();
    }
  }

  /// Generate full recipe after user upgrades to Plus
  Future<void> upgradeAndGenerateFullRecipe() async {
    if (_selectedIdea == null) return;
    await _generateFullRecipe(_selectedIdea!);
  }

  /// Present the paywall
  Future<bool> presentPaywall(BuildContext context) async {
    return await ref.read(subscriptionProvider.notifier).presentPaywall(context);
  }
}
