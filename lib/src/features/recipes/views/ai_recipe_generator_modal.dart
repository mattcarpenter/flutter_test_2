import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/steps.dart' as db;
import '../../../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../share/widgets/share_recipe_preview_result.dart';
import '../models/recipe_idea.dart';
import 'add_recipe_modal.dart';
import 'ai_recipe_generator_view_model.dart';

/// Shows the AI Recipe Generator modal.
///
/// Entry point for generating recipes with AI from user prompts.
/// Handles idea generation, recipe selection, and subscription flow.
Future<void> showAiRecipeGeneratorModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
}) async {
  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    modalDecorator: (child) {
      // Wrap in ChangeNotifierProvider for cross-page state
      return provider.ChangeNotifierProvider<AiRecipeGeneratorViewModel>(
        create: (_) => AiRecipeGeneratorViewModel(
          ref: ref,
          folderId: folderId,
        ),
        child: child,
      );
    },
    pageListBuilder: (bottomSheetContext) => [
      _AiRecipeInputPage.build(bottomSheetContext), // Page 0
      _AiRecipeResultsPage.build(bottomSheetContext), // Page 1
    ],
  );
}

// ============================================================================
// Page 1: Input Page
// ============================================================================

class _AiRecipeInputPage {
  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      child: const _InputPageContent(),
    );
  }
}

class _InputPageContent extends ConsumerStatefulWidget {
  const _InputPageContent();

  @override
  ConsumerState<_InputPageContent> createState() => _InputPageContentState();
}

class _InputPageContentState extends ConsumerState<_InputPageContent> {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return provider.Consumer<AiRecipeGeneratorViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Generate with AI',
                style: AppTypography.h4.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Describe what you want to eat',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Quill Editor
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: quill.QuillEditor.basic(
                    controller: viewModel.inputController,
                    config: quill.QuillEditorConfig(
                      placeholder: 'e.g., "I want a warm soup with chicken"',
                      padding: EdgeInsets.all(AppSpacing.md),
                      autoFocus: true,
                      expands: true,
                      scrollable: true,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Pantry toggle
              if (viewModel.hasPantryItems) ...[
                _PantryToggle(
                  value: viewModel.usePantryItems,
                  onChanged: viewModel.toggleUsePantryItems,
                  pantryItemCount: viewModel.availablePantryItems.length,
                ),
                SizedBox(height: AppSpacing.lg),
              ],

              // Generate button
              ListenableBuilder(
                listenable: viewModel.inputController,
                builder: (context, _) {
                  return AppButton(
                    text: 'Generate Ideas',
                    onPressed: viewModel.hasInput
                        ? () {
                            HapticFeedback.lightImpact();
                            viewModel.generateIdeas();
                            WoltModalSheet.of(context).showNext();
                          }
                        : null,
                    style: AppButtonStyle.fill,
                    theme: AppButtonTheme.primary,
                    size: AppButtonSize.large,
                    shape: AppButtonShape.square,
                    fullWidth: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Toggle switch for using pantry items
class _PantryToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final int pantryItemCount;

  const _PantryToggle({
    required this.value,
    required this.onChanged,
    required this.pantryItemCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use pantry items',
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '$pantryItemCount items in stock',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ============================================================================
// Page 2: Results Page
// ============================================================================

class _AiRecipeResultsPage {
  static SliverWoltModalSheetPage build(BuildContext context) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: const ModalSheetTitle('Recipe Ideas'),
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () {
          final viewModel = provider.Provider.of<AiRecipeGeneratorViewModel>(
            context,
            listen: false,
          );
          viewModel.resetToInput();
          WoltModalSheet.of(context).showPrevious();
        },
        child: const Icon(CupertinoIcons.back, size: 24),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        SliverToBoxAdapter(
          child: _ResultsPageContent(),
        ),
      ],
    );
  }
}

class _ResultsPageContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return provider.Consumer<AiRecipeGeneratorViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: viewModel.isTransitioning ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _buildContent(context, viewModel),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AiRecipeGeneratorViewModel viewModel) {
    switch (viewModel.state) {
      case AiGeneratorState.inputting:
        // Should not normally appear on page 2
        return const SizedBox.shrink();
      case AiGeneratorState.brainstorming:
        return const _BrainstormingState();
      case AiGeneratorState.showingResults:
        return _ResultsState(
          ideas: viewModel.recipeIdeas,
          onSelectIdea: viewModel.selectIdea,
        );
      case AiGeneratorState.generatingRecipe:
        return _GeneratingRecipeState(viewModel: viewModel);
      case AiGeneratorState.showingPreview:
        return _PreviewState(viewModel: viewModel);
      case AiGeneratorState.error:
        return _ErrorState(viewModel: viewModel);
    }
  }
}

// ============================================================================
// State Widgets
// ============================================================================

class _BrainstormingState extends StatelessWidget {
  const _BrainstormingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.xl),
          const CupertinoActivityIndicator(radius: 16),
          SizedBox(height: AppSpacing.lg),
          _AnimatedLoadingText(
            messages: const [
              'Brainstorming recipes...',
              'Considering your preferences...',
              'Finding delicious ideas...',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ResultsState extends StatelessWidget {
  final List<RecipeIdea> ideas;
  final ValueChanged<RecipeIdea> onSelectIdea;

  const _ResultsState({
    required this.ideas,
    required this.onSelectIdea,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a recipe to generate',
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Recipe idea cards
          ...ideas.map((idea) => _RecipeIdeaCard(
                idea: idea,
                onTap: () => onSelectIdea(idea),
              )),
        ],
      ),
    );
  }
}

class _RecipeIdeaCard extends StatelessWidget {
  final RecipeIdea idea;
  final VoidCallback onTap;

  const _RecipeIdeaCard({
    required this.idea,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.title,
                  style: AppTypography.h5.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  idea.description,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (idea.formattedTime != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        idea.formattedTime!,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                    ],
                    if (idea.difficultyLabel != null) ...[
                      Icon(
                        Icons.bar_chart,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        idea.difficultyLabel!,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingRecipeState extends StatefulWidget {
  final AiRecipeGeneratorViewModel viewModel;

  const _GeneratingRecipeState({required this.viewModel});

  @override
  State<_GeneratingRecipeState> createState() => _GeneratingRecipeStateState();
}

class _GeneratingRecipeStateState extends State<_GeneratingRecipeState> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Listen for recipe completion
    widget.viewModel.addListener(_checkForRecipe);
    // Check immediately in case recipe is already ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForRecipe());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_checkForRecipe);
    super.dispose();
  }

  void _checkForRecipe() {
    if (_hasNavigated) return;
    if (widget.viewModel.extractedRecipe != null && mounted) {
      _hasNavigated = true;
      // Recipe is ready - close modal and open editor
      _openRecipeEditor();
    }
  }

  Future<void> _openRecipeEditor() async {
    final recipe = widget.viewModel.extractedRecipe;
    if (recipe == null) return;

    final recipeEntry = _convertToRecipeEntry(recipe, widget.viewModel.folderId);

    // Close modal
    Navigator.of(context, rootNavigator: true).pop();

    // Open editor using root context
    await Future.delayed(const Duration(milliseconds: 100));
    final rootContext = globalRootNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      showRecipeEditorModal(
        rootContext,
        recipe: recipeEntry,
        isEditing: false,
        folderId: widget.viewModel.folderId,
      );
    }
  }

  RecipeEntry _convertToRecipeEntry(ExtractedRecipe extracted, String? folderId) {
    const uuid = Uuid();

    final ingredients = extracted.ingredients.map((e) {
      return Ingredient(
        id: uuid.v4(),
        type: e.type,
        name: e.name,
        isCanonicalised: false,
      );
    }).toList();

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
      userId: '',
      servings: extracted.servings,
      prepTime: extracted.prepTime,
      cookTime: extracted.cookTime,
      source: extracted.source,
      ingredients: ingredients,
      steps: steps,
      images: null,
      folderIds: folderId != null ? [folderId] : [],
      pinned: 0,
      pinnedAt: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.xl),
          const CupertinoActivityIndicator(radius: 16),
          SizedBox(height: AppSpacing.lg),
          _AnimatedLoadingText(
            messages: const [
              'Generating recipe...',
              'Writing ingredients...',
              'Crafting instructions...',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _PreviewState extends StatelessWidget {
  final AiRecipeGeneratorViewModel viewModel;

  const _PreviewState({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final preview = viewModel.recipePreview;
    if (preview == null) return const SizedBox.shrink();

    return ShareRecipePreviewResultContent(
      preview: preview,
      onSubscribe: () async {
        if (!context.mounted) return;

        final purchased = await viewModel.presentPaywall(context);

        if (purchased && context.mounted) {
          // User upgraded - generate full recipe
          await viewModel.upgradeAndGenerateFullRecipe();
        }
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final AiRecipeGeneratorViewModel viewModel;

  const _ErrorState({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.isRateLimitError ? 'Limit Reached' : 'Generation Failed',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            viewModel.errorMessage,
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          if (viewModel.isRateLimitError)
            AppButton(
              text: 'Upgrade to Plus',
              onPressed: () async {
                final purchased = await viewModel.presentPaywall(context);
                if (purchased && context.mounted) {
                  // If upgraded, retry
                  viewModel.resetToInput();
                  WoltModalSheet.of(context).showPrevious();
                }
              },
              style: AppButtonStyle.fill,
              theme: AppButtonTheme.primary,
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              fullWidth: true,
            )
          else
            AppButton(
              text: 'Try Again',
              onPressed: () {
                viewModel.resetToInput();
                WoltModalSheet.of(context).showPrevious();
              },
              style: AppButtonStyle.fill,
              theme: AppButtonTheme.primary,
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              fullWidth: true,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Animated Loading Text
// ============================================================================

class _AnimatedLoadingText extends StatefulWidget {
  final List<String> messages;

  const _AnimatedLoadingText({required this.messages});

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  void _startCycle() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.messages.length;
        });
        _startCycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        widget.messages[_currentIndex],
        key: ValueKey(_currentIndex),
        style: AppTypography.body.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

