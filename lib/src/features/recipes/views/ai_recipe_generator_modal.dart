import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
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
  final pageIndexNotifier = ValueNotifier<int>(0);

  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    useSafeArea: false,
    pageIndexNotifier: pageIndexNotifier,
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
      _AiRecipeInputPage.build(bottomSheetContext, pageIndexNotifier), // Page 0
      _AiRecipeResultsPage.build(bottomSheetContext, pageIndexNotifier), // Page 1
      _PantrySelectionPage.build(bottomSheetContext, pageIndexNotifier), // Page 2
    ],
  );
}

// ============================================================================
// Page 0: Input Page
// ============================================================================

class _AiRecipeInputPage {
  static SliverWoltModalSheetPage build(BuildContext context, ValueNotifier<int> pageIndexNotifier) {
    return SliverWoltModalSheetPage(
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
      mainContentSliversBuilder: (context) => [
        SliverToBoxAdapter(
          child: _InputPageContent(pageIndexNotifier: pageIndexNotifier),
        ),
      ],
    );
  }
}

class _InputPageContent extends StatefulWidget {
  final ValueNotifier<int> pageIndexNotifier;

  const _InputPageContent({required this.pageIndexNotifier});

  @override
  State<_InputPageContent> createState() => _InputPageContentState();
}

class _InputPageContentState extends State<_InputPageContent> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return provider.Consumer<AiRecipeGeneratorViewModel>(
      builder: (context, viewModel, child) {
        // Sync text controller with view model on first build
        if (_textController.text != viewModel.promptText) {
          _textController.text = viewModel.promptText;
        }

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

              // Text input
              TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g., "I want a warm soup with chicken"',
                  hintStyle: AppTypography.body.copyWith(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  viewModel.updatePromptText(value);
                },
              ),
              SizedBox(height: AppSpacing.lg),

              // Pantry toggle
              if (viewModel.hasPantryItems) ...[
                _PantryToggle(
                  value: viewModel.usePantryItems,
                  onChanged: viewModel.toggleUsePantryItems,
                  pantryItemCount: viewModel.availablePantryItems.length,
                  selectedCount: viewModel.selectedPantryItemCount,
                  onSelectTap: () {
                    widget.pageIndexNotifier.value = 2;
                  },
                ),
                SizedBox(height: AppSpacing.lg),
              ],

              // Generate button
              ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  return AppButton(
                    text: 'Generate Ideas',
                    onPressed: viewModel.hasInput
                        ? () {
                            HapticFeedback.lightImpact();
                            viewModel.generateIdeas();
                            widget.pageIndexNotifier.value = 1;
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
  final int selectedCount;
  final VoidCallback onSelectTap;

  const _PantryToggle({
    required this.value,
    required this.onChanged,
    required this.pantryItemCount,
    required this.selectedCount,
    required this.onSelectTap,
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
        if (value) ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onSelectTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedCount selected',
                  style: AppTypography.body.copyWith(
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: colors.primary,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ============================================================================
// Page 1: Results Page
// ============================================================================

class _AiRecipeResultsPage {
  static SliverWoltModalSheetPage build(BuildContext context, ValueNotifier<int> pageIndexNotifier) {
    return SliverWoltModalSheetPage(
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
          pageIndexNotifier.value = 0;
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
          child: _ResultsPageContent(pageIndexNotifier: pageIndexNotifier),
        ),
      ],
    );
  }
}

class _ResultsPageContent extends ConsumerWidget {
  final ValueNotifier<int> pageIndexNotifier;

  const _ResultsPageContent({required this.pageIndexNotifier});

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
        // Should not normally appear on page 1
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
        return _ErrorState(viewModel: viewModel, pageIndexNotifier: pageIndexNotifier);
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
  final ValueNotifier<int> pageIndexNotifier;

  const _ErrorState({
    required this.viewModel,
    required this.pageIndexNotifier,
  });

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
                  pageIndexNotifier.value = 0;
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
                pageIndexNotifier.value = 0;
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

// ============================================================================
// Page 2: Pantry Selection Page
// ============================================================================

class _PantrySelectionPage {
  static SliverWoltModalSheetPage build(BuildContext context, ValueNotifier<int> pageIndexNotifier) {
    return SliverWoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: const ModalSheetTitle('Select Pantry Items'),
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () {
          pageIndexNotifier.value = 0;
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
        SliverFillRemaining(
          hasScrollBody: true,
          child: _PantrySelectionScrollableContent(),
        ),
      ],
      stickyActionBar: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: AppButton(
          text: 'Done',
          onPressed: () {
            pageIndexNotifier.value = 0;
          },
          style: AppButtonStyle.fill,
          theme: AppButtonTheme.primary,
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          fullWidth: true,
        ),
      ),
    );
  }
}

class _PantrySelectionScrollableContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return provider.Consumer<AiRecipeGeneratorViewModel>(
      builder: (context, viewModel, child) {
        final items = viewModel.availablePantryItems;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No pantry items available',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          itemCount: items.length + 1, // +1 for header
          itemBuilder: (context, index) {
            // First item is the header
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (viewModel.selectedPantryItemCount == items.length) {
                          viewModel.deselectAllPantryItems();
                        } else {
                          viewModel.selectAllPantryItems();
                        }
                      },
                      child: Text(
                        viewModel.selectedPantryItemCount == items.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: AppTypography.body.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Pantry items (index - 1 because of header)
            final itemIndex = index - 1;
            final item = items[itemIndex];
            final isFirst = itemIndex == 0;
            final isLast = itemIndex == items.length - 1;
            final isSelected = viewModel.isPantryItemSelected(item.id);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                viewModel.togglePantryItem(item.id);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: colors.input,
                  borderRadius: GroupedListStyling.getBorderRadius(
                    isGrouped: true,
                    isFirstInGroup: isFirst,
                    isLastInGroup: isLast,
                  ),
                  border: GroupedListStyling.getBorder(
                    context: context,
                    isGrouped: true,
                    isFirstInGroup: isFirst,
                    isLastInGroup: isLast,
                    isDragging: false,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      AppRadioButton(
                        selected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          viewModel.togglePantryItem(item.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

