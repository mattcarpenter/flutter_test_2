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
import '../../../providers/subscription_provider.dart';
import '../../../services/clipping_extraction_service.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../recipes/views/add_recipe_modal.dart';
import '../models/extracted_recipe.dart';
import '../models/extracted_shopping_item.dart';
import '../models/recipe_preview.dart';
import '../models/shopping_list_preview.dart';
import '../providers/preview_usage_provider.dart';
import '../widgets/recipe_preview_result.dart';
import '../widgets/shopping_list_preview_result.dart';
import 'clipping_shopping_list_modal.dart';

/// Shows recipe extraction modal.
/// For Plus users: Full extraction → opens recipe editor
/// For non-Plus users: Preview → shows teaser with subscribe button
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

  // Check subscription status
  final hasPlus = ref.read(effectiveHasPlusProvider);

  if (hasPlus) {
    // Entitled user - full extraction
    await _showFullRecipeExtraction(context, ref, title: title, body: body);
  } else {
    // Non-entitled user - check preview limit first
    final usageService = await ref.read(previewUsageServiceProvider.future);

    if (!usageService.hasRecipePreviewsRemaining()) {
      // Limit exceeded - go straight to paywall
      if (!context.mounted) return;
      final purchased =
          await ref.read(subscriptionProvider.notifier).presentPaywall(context);
      if (purchased && context.mounted) {
        // User subscribed - now do full extraction
        await _showFullRecipeExtraction(context, ref, title: title, body: body);
      }
      return;
    }

    // Show preview extraction
    if (!context.mounted) return;
    await _showRecipePreviewExtraction(context, ref, title: title, body: body);
  }
}

/// Full extraction for entitled users.
Future<void> _showFullRecipeExtraction(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  if (!context.mounted) return;

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

/// Preview extraction for non-entitled users.
Future<void> _showRecipePreviewExtraction(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  if (!context.mounted) return;

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
        child: _RecipePreviewContent(
          title: title,
          body: body,
          onPreviewReady: (preview) async {
            Navigator.of(modalContext, rootNavigator: true).pop();

            if (preview != null && context.mounted) {
              // Increment usage counter
              final usageService =
                  await ref.read(previewUsageServiceProvider.future);
              await usageService.incrementRecipeUsage();

              // Show preview result
              if (context.mounted) {
                _showRecipePreviewResult(context, ref, preview, title, body);
              }
            } else if (context.mounted) {
              _showErrorDialog(
                  context, 'Unable to detect a recipe in this text.');
            }
          },
          onError: (message) {
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

/// Shows the preview result with fading ingredients and subscribe button.
void _showRecipePreviewResult(
  BuildContext context,
  WidgetRef ref,
  RecipePreview preview,
  String originalTitle,
  String originalBody,
) {
  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: false,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 55,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        hasTopBarLayer: true,
        isTopBarLayerAlwaysVisible: false,
        topBarTitle: const ModalSheetTitle('Recipe Found'),
        trailingNavBarWidget: Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.neutral,
            onPressed: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
        child: RecipePreviewResultContent(
          preview: preview,
          onSubscribe: () async {
            Navigator.of(modalContext, rootNavigator: true).pop();
            if (!context.mounted) return;

            final purchased = await ref
                .read(subscriptionProvider.notifier)
                .presentPaywall(context);

            if (purchased && context.mounted) {
              // User subscribed - do full extraction
              await _showFullRecipeExtraction(
                context,
                ref,
                title: originalTitle,
                body: originalBody,
              );
            }
          },
        ),
      ),
    ],
  );
}

/// Shows shopping list extraction modal.
/// For Plus users: Full extraction → shows add-to-shopping-list modal
/// For non-Plus users: Preview → shows teaser with subscribe button
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

  // Check subscription status
  final hasPlus = ref.read(effectiveHasPlusProvider);

  if (hasPlus) {
    // Entitled user - full extraction
    await _showFullShoppingListExtraction(context, ref,
        title: title, body: body);
  } else {
    // Non-entitled user - check preview limit first
    final usageService = await ref.read(previewUsageServiceProvider.future);

    if (!usageService.hasShoppingListPreviewsRemaining()) {
      // Limit exceeded - go straight to paywall
      if (!context.mounted) return;
      final purchased =
          await ref.read(subscriptionProvider.notifier).presentPaywall(context);
      if (purchased && context.mounted) {
        // User subscribed - now do full extraction
        await _showFullShoppingListExtraction(context, ref,
            title: title, body: body);
      }
      return;
    }

    // Show preview extraction
    if (!context.mounted) return;
    await _showShoppingListPreviewExtraction(context, ref,
        title: title, body: body);
  }
}

/// Full extraction for entitled users.
Future<void> _showFullShoppingListExtraction(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  if (!context.mounted) return;

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

            if (context.mounted) {
              showClippingShoppingListModal(context, items);
            }
          },
          onError: (message) {
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

/// Preview extraction for non-entitled users.
Future<void> _showShoppingListPreviewExtraction(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
}) async {
  if (!context.mounted) return;

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
        child: _ShoppingListPreviewContent(
          title: title,
          body: body,
          onPreviewReady: (preview) async {
            Navigator.of(modalContext, rootNavigator: true).pop();

            if (preview.hasItems && context.mounted) {
              // Increment usage counter
              final usageService =
                  await ref.read(previewUsageServiceProvider.future);
              await usageService.incrementShoppingListUsage();

              // Show preview result
              if (context.mounted) {
                _showShoppingListPreviewResult(
                    context, ref, preview, title, body);
              }
            } else if (context.mounted) {
              _showErrorDialog(
                  context, 'No shopping list items found in this text.');
            }
          },
          onError: (message) {
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

/// Shows the preview result with fading items and subscribe button.
void _showShoppingListPreviewResult(
  BuildContext context,
  WidgetRef ref,
  ShoppingListPreview preview,
  String originalTitle,
  String originalBody,
) {
  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: false,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 55,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        hasTopBarLayer: true,
        isTopBarLayerAlwaysVisible: false,
        topBarTitle: const ModalSheetTitle('Shopping Items Found'),
        trailingNavBarWidget: Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.neutral,
            onPressed: () =>
                Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
        child: ShoppingListPreviewResultContent(
          preview: preview,
          onSubscribe: () async {
            Navigator.of(modalContext, rootNavigator: true).pop();
            if (!context.mounted) return;

            final purchased = await ref
                .read(subscriptionProvider.notifier)
                .presentPaywall(context);

            if (purchased && context.mounted) {
              // User subscribed - do full extraction
              await _showFullShoppingListExtraction(
                context,
                ref,
                title: originalTitle,
                body: originalBody,
              );
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

/// Content widget that performs recipe preview extraction on init
class _RecipePreviewContent extends ConsumerStatefulWidget {
  final String title;
  final String body;
  final void Function(RecipePreview?) onPreviewReady;
  final void Function(String) onError;

  const _RecipePreviewContent({
    required this.title,
    required this.body,
    required this.onPreviewReady,
    required this.onError,
  });

  @override
  ConsumerState<_RecipePreviewContent> createState() =>
      _RecipePreviewContentState();
}

class _RecipePreviewContentState extends ConsumerState<_RecipePreviewContent> {
  @override
  void initState() {
    super.initState();
    _performPreview();
  }

  Future<void> _performPreview() async {
    try {
      final service = ref.read(clippingExtractionServiceProvider);
      final preview = await service.previewRecipe(
        title: widget.title,
        body: widget.body,
      );
      widget.onPreviewReady(preview);
    } on ClippingExtractionException catch (e) {
      widget.onError(e.message);
    } catch (e) {
      AppLogger.error('Recipe preview failed', e);
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
              'Scanning for recipes...',
              'Finding details...',
            ],
          ),
        ],
      ),
    );
  }
}

/// Content widget that performs shopping list preview extraction on init
class _ShoppingListPreviewContent extends ConsumerStatefulWidget {
  final String title;
  final String body;
  final void Function(ShoppingListPreview) onPreviewReady;
  final void Function(String) onError;

  const _ShoppingListPreviewContent({
    required this.title,
    required this.body,
    required this.onPreviewReady,
    required this.onError,
  });

  @override
  ConsumerState<_ShoppingListPreviewContent> createState() =>
      _ShoppingListPreviewContentState();
}

class _ShoppingListPreviewContentState
    extends ConsumerState<_ShoppingListPreviewContent> {
  @override
  void initState() {
    super.initState();
    _performPreview();
  }

  Future<void> _performPreview() async {
    try {
      final service = ref.read(clippingExtractionServiceProvider);
      final preview = await service.previewShoppingList(
        title: widget.title,
        body: widget.body,
      );
      widget.onPreviewReady(preview);
    } on ClippingExtractionException catch (e) {
      widget.onError(e.message);
    } catch (e) {
      AppLogger.error('Shopping list preview failed', e);
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
              'Scanning for items...',
              'Finding details...',
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
