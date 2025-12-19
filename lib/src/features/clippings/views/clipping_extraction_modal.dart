import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/steps.dart' as db;
import '../../../services/clipping_extraction_service.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../recipes/views/add_recipe_modal.dart';
import '../models/extracted_recipe.dart';
import '../models/extracted_shopping_item.dart';
import 'clipping_shopping_list_modal.dart';

/// Shows the recipe extraction modal, extracts recipe data, and opens the recipe editor on success.
///
/// The modal displays a loading spinner while the API call is in progress.
/// On success, closes the modal and opens the recipe editor with pre-populated data.
/// On failure, shows an error message with a close button.
Future<void> showRecipeExtractionModal(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    if (context.mounted) {
      _showErrorDialog(
        context,
        'No internet connection. Please check your network and try again.',
      );
    }
    return;
  }

  if (!context.mounted) return;

  // Show loading modal and perform extraction
  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        child: _RecipeExtractionContent(
          title: title,
          body: body,
          onComplete: (extractedRecipe) {
            // Close loading modal
            Navigator.of(modalContext, rootNavigator: true).pop();

            if (extractedRecipe == null) {
              if (context.mounted) {
                _showErrorDialog(
                  context,
                  'Unable to extract a recipe from this text. Please make sure the text contains recipe information.',
                );
              }
              return;
            }

            // Convert to RecipeEntry and open editor
            if (context.mounted) {
              final recipeEntry = _convertToRecipeEntry(extractedRecipe);
              showRecipeEditorModal(
                context,
                ref: ref,
                recipe: recipeEntry,
                isEditing: false,
              );
            }
          },
          onError: (message) {
            // Close loading modal
            Navigator.of(modalContext, rootNavigator: true).pop();

            if (context.mounted) {
              _showErrorDialog(context, message);
            }
          },
        ),
      ),
    ],
  );
}

/// Shows the shopping list extraction modal, extracts items, and shows the add-to-shopping-list modal on success.
Future<void> showShoppingListExtractionModal(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    if (context.mounted) {
      _showErrorDialog(
        context,
        'No internet connection. Please check your network and try again.',
      );
    }
    return;
  }

  if (!context.mounted) return;

  // Show loading modal and perform extraction
  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        child: _ShoppingListExtractionContent(
          title: title,
          body: body,
          onComplete: (items) {
            // Close loading modal
            Navigator.of(modalContext, rootNavigator: true).pop();

            if (items.isEmpty) {
              if (context.mounted) {
                _showErrorDialog(
                  context,
                  'No shopping list items found in this text.',
                );
              }
              return;
            }

            // Show the shopping list modal
            if (context.mounted) {
              showClippingShoppingListModal(context, items);
            }
          },
          onError: (message) {
            // Close loading modal
            Navigator.of(modalContext, rootNavigator: true).pop();

            if (context.mounted) {
              _showErrorDialog(context, message);
            }
          },
        ),
      ),
    ],
  );
}

/// Animated loading text that cycles through messages with sequential fade animation
class _AnimatedLoadingText extends StatefulWidget {
  final List<String> messages;

  const _AnimatedLoadingText({required this.messages});

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      value: 1.0, // Start fully visible
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < widget.messages.length - 1) {
        _transitionToNext();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _transitionToNext() async {
    // Fade out
    await _fadeController.reverse();
    // Change text
    if (mounted) {
      setState(() {
        _currentIndex++;
      });
      // Fade in
      await _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        widget.messages[_currentIndex],
        style: AppTypography.body.copyWith(
          color: AppColors.of(context).textSecondary,
          fontFamily: Platform.isIOS ? 'SF Pro Rounded' : null,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Content widget that performs recipe extraction on init
class _RecipeExtractionContent extends ConsumerStatefulWidget {
  final String title;
  final String body;
  final void Function(ExtractedRecipe?) onComplete;
  final void Function(String) onError;

  const _RecipeExtractionContent({
    required this.title,
    required this.body,
    required this.onComplete,
    required this.onError,
  });

  @override
  ConsumerState<_RecipeExtractionContent> createState() =>
      _RecipeExtractionContentState();
}

class _RecipeExtractionContentState
    extends ConsumerState<_RecipeExtractionContent> {
  @override
  void initState() {
    super.initState();
    _performExtraction();
  }

  Future<void> _performExtraction() async {
    try {
      final service = ref.read(clippingExtractionServiceProvider);
      final extractedRecipe = await service.extractRecipe(
        title: widget.title,
        body: widget.body,
      );
      widget.onComplete(extractedRecipe);
    } on ClippingExtractionException catch (e) {
      widget.onError(e.message);
    } catch (e) {
      AppLogger.error('Recipe extraction failed', e);
      widget.onError('Failed to process. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          SizedBox(height: AppSpacing.lg),
          const _AnimatedLoadingText(
            messages: [
              'Extracting recipe...',
              'Finding the details...',
              'Wrapping up...',
            ],
          ),
        ],
      ),
    );
  }
}

/// Content widget that performs shopping list extraction on init
class _ShoppingListExtractionContent extends ConsumerStatefulWidget {
  final String title;
  final String body;
  final void Function(List<ExtractedShoppingItem>) onComplete;
  final void Function(String) onError;

  const _ShoppingListExtractionContent({
    required this.title,
    required this.body,
    required this.onComplete,
    required this.onError,
  });

  @override
  ConsumerState<_ShoppingListExtractionContent> createState() =>
      _ShoppingListExtractionContentState();
}

class _ShoppingListExtractionContentState
    extends ConsumerState<_ShoppingListExtractionContent> {
  @override
  void initState() {
    super.initState();
    _performExtraction();
  }

  Future<void> _performExtraction() async {
    try {
      final service = ref.read(clippingExtractionServiceProvider);
      final items = await service.extractShoppingList(
        title: widget.title,
        body: widget.body,
      );
      widget.onComplete(items);
    } on ClippingExtractionException catch (e) {
      widget.onError(e.message);
    } catch (e) {
      AppLogger.error('Shopping list extraction failed', e);
      widget.onError('Failed to process. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          SizedBox(height: AppSpacing.lg),
          const _AnimatedLoadingText(
            messages: [
              'Extracting items...',
              'Finding the details...',
              'Wrapping up...',
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows an error dialog with a message and close button
void _showErrorDialog(BuildContext context, String message) {
  showCupertinoDialog(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('OK'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}

/// Converts an ExtractedRecipe to a RecipeEntry for the editor
RecipeEntry _convertToRecipeEntry(ExtractedRecipe extracted) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  const uuid = Uuid();

  // Convert ingredients
  final ingredients = extracted.ingredients.map((e) {
    return Ingredient(
      id: uuid.v4(),
      type: e.type,
      name: e.name,
      isCanonicalised: false, // Will be canonicalized when recipe is saved
    );
  }).toList();

  // Convert steps
  final steps = extracted.steps.map((e) {
    return db.Step(
      id: uuid.v4(),
      type: e.type,
      text: e.text,
    );
  }).toList();

  return RecipeEntry(
    id: uuid.v4(),
    title: extracted.title,
    description: extracted.description,
    language: 'en',
    userId: userId,
    servings: extracted.servings,
    prepTime: extracted.prepTime,
    cookTime: extracted.cookTime,
    source: extracted.source,
    ingredients: ingredients,
    steps: steps,
    folderIds: [],
    pinned: 0,
    pinnedAt: null,
  );
}
