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
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
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
      mainContentSliversBuilder: (builderContext) => [
        _InputPageContent(
          pageIndexNotifier: pageIndexNotifier,
        ),
      ],
    );
  }
}

class _InputPageContent extends StatefulWidget {
  final ValueNotifier<int> pageIndexNotifier;

  const _InputPageContent({
    required this.pageIndexNotifier,
  });

  @override
  State<_InputPageContent> createState() => _InputPageContentState();
}

class _InputPageContentState extends State<_InputPageContent> {
  late TextEditingController _textController;
  bool _initialized = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final viewModel = provider.Provider.of<AiRecipeGeneratorViewModel>(
      context,
      listen: true,
    );

    // Initialize controller on first build with context available
    if (!_initialized) {
      _textController = TextEditingController(text: viewModel.promptText);
      _initialized = true;
    }

    // Sync text controller with view model
    if (_textController.text != viewModel.promptText) {
      _textController.text = viewModel.promptText;
    }

    // Build list of widgets for SliverList (correct pattern for multi-page Wolt modals)
    final List<Widget> widgets = [];

    // Title
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: Text(
          'Generate with AI',
          style: AppTypography.h4.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
    );

    // Subtitle
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Text(
          'Describe what you want to eat',
          style: AppTypography.body.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );

    // Text input
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: TextField(
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
      ),
    );

    // Pantry toggle
    if (viewModel.hasPantryItems) {
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: _PantryToggle(
            value: viewModel.usePantryItems,
            onChanged: viewModel.toggleUsePantryItems,
            pantryItemCount: viewModel.availablePantryItems.length,
            selectedCount: viewModel.selectedPantryItemCount,
            onSelectTap: () {
              widget.pageIndexNotifier.value = 2;
            },
          ),
        ),
      );
    }

    // Generate button
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: ListenableBuilder(
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
      ),
    );

    return SliverList(
      delegate: SliverChildListDelegate(widgets),
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
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
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
        child: Text(
          'Back',
          style: TextStyle(
            color: AppColors.of(context).primary,
            fontSize: 17,
          ),
        ),
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
      mainContentSliversBuilder: (builderContext) => [
        _ResultsPageContent(
          pageIndexNotifier: pageIndexNotifier,
        ),
      ],
    );
  }
}

class _ResultsPageContent extends StatelessWidget {
  final ValueNotifier<int> pageIndexNotifier;

  const _ResultsPageContent({
    required this.pageIndexNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = provider.Provider.of<AiRecipeGeneratorViewModel>(
      context,
      listen: true,
    );
    // Return Slivers directly based on state (correct pattern for multi-page Wolt modals)
    return _buildContent(context, viewModel);
  }

  Widget _buildContent(BuildContext context, AiRecipeGeneratorViewModel viewModel) {
    final colors = AppColors.of(context);

    switch (viewModel.state) {
      case AiGeneratorState.inputting:
      case AiGeneratorState.brainstorming:
        // Show spinner for both states - if we're on page 1, we're transitioning to brainstorming
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(radius: 16),
                SizedBox(height: AppSpacing.lg),
                _AnimatedLoadingText(
                  messages: const [
                    'Brainstorming recipes...',
                    'Considering your preferences...',
                    'Finding delicious ideas...',
                  ],
                ),
              ],
            ),
          ),
        );

      case AiGeneratorState.showingResults:
        return _buildResultsSliver(context, colors, viewModel);

      case AiGeneratorState.generatingRecipe:
        return _buildGeneratingSliver(context, viewModel);

      case AiGeneratorState.showingPreview:
        return _buildPreviewSliver(context, viewModel);

      case AiGeneratorState.error:
        return _buildErrorSliver(context, colors, viewModel);
    }
  }

  Widget _buildResultsSliver(BuildContext context, AppColors colors, AiRecipeGeneratorViewModel viewModel) {
    final List<Widget> widgets = [];

    // Title
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: Text(
          'Recipe Ideas',
          style: AppTypography.h4.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
    );

    // Subtitle
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Text(
          'Select a recipe to generate',
          style: AppTypography.body.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );

    // Recipe idea cards (grouped list style)
    final ideas = viewModel.recipeIdeas;
    for (int i = 0; i < ideas.length; i++) {
      final idea = ideas[i];
      final isFirst = i == 0;
      final isLast = i == ideas.length - 1;

      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _RecipeIdeaCard(
            idea: idea,
            isFirst: isFirst,
            isLast: isLast,
            onTap: () => viewModel.selectIdea(idea),
          ),
        ),
      );
    }

    // Bottom padding
    widgets.add(SizedBox(height: AppSpacing.xxl));

    return SliverList(
      delegate: SliverChildListDelegate(widgets),
    );
  }

  Widget _buildGeneratingSliver(BuildContext context, AiRecipeGeneratorViewModel viewModel) {
    // Check if recipe is ready and navigate
    if (viewModel.extractedRecipe != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        final recipe = _createRecipeFromExtracted(viewModel);
        showRecipeEditorModal(
          context,
          recipe: recipe,
          isEditing: false,
          folderId: viewModel.folderId,
        );
      });
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 16),
            SizedBox(height: AppSpacing.lg),
            _AnimatedLoadingText(
              messages: const [
                'Generating recipe...',
                'Writing ingredients...',
                'Crafting instructions...',
              ],
            ),
          ],
        ),
      ),
    );
  }

  RecipeEntry _createRecipeFromExtracted(AiRecipeGeneratorViewModel viewModel) {
    final extracted = viewModel.extractedRecipe!;
    final uuid = const Uuid();

    final ingredients = extracted.ingredients
        .map((i) => Ingredient(
              id: uuid.v4(),
              name: i.name,
              type: i.type == 'section' ? 'section' : 'ingredient',
            ))
        .toList();

    final steps = extracted.steps
        .map((s) => db.Step(
              id: uuid.v4(),
              text: s.text,
              type: s.type == 'section' ? 'section' : 'step',
            ))
        .toList();

    final now = DateTime.now().millisecondsSinceEpoch;
    return RecipeEntry(
      id: uuid.v4(),
      title: extracted.title,
      description: extracted.description,
      ingredients: ingredients,
      steps: steps,
      servings: extracted.servings,
      prepTime: extracted.prepTime,
      cookTime: extracted.cookTime,
      createdAt: now,
      updatedAt: now,
      pinnedAt: null,
    );
  }

  Widget _buildPreviewSliver(BuildContext context, AiRecipeGeneratorViewModel viewModel) {
    final preview = viewModel.recipePreview;
    if (preview == null) {
      return SliverList(delegate: SliverChildListDelegate([]));
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        ShareRecipePreviewResultContent(
          preview: preview,
          onSubscribe: () async {
            if (!context.mounted) return;
            final purchased = await viewModel.presentPaywall(context);
            if (purchased && context.mounted) {
              await viewModel.upgradeAndGenerateFullRecipe();
            }
          },
        ),
      ]),
    );
  }

  Widget _buildErrorSliver(BuildContext context, AppColors colors, AiRecipeGeneratorViewModel viewModel) {
    final List<Widget> widgets = [];

    // Title
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
        child: Text(
          viewModel.isRateLimitError ? 'Limit Reached' : 'Generation Failed',
          style: AppTypography.h4.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
    );

    // Error message
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Text(
          viewModel.errorMessage,
          style: AppTypography.body.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );

    // Button
    widgets.add(
      Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: viewModel.isRateLimitError
            ? AppButton(
                text: 'Upgrade to Plus',
                onPressed: () async {
                  final purchased = await viewModel.presentPaywall(context);
                  if (purchased && context.mounted) {
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
            : AppButton(
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
      ),
    );

    return SliverList(
      delegate: SliverChildListDelegate(widgets),
    );
  }
}

class _RecipeIdeaCard extends StatelessWidget {
  final RecipeIdea idea;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _RecipeIdeaCard({
    required this.idea,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );

    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: border,
          borderRadius: borderRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title, description, and metadata
            Expanded(
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
                  if (idea.formattedTime != null || idea.difficultyLabel != null) ...[
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
                          if (idea.difficultyLabel != null)
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
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Chevron on right, centered vertically
            SizedBox(width: AppSpacing.md),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
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
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.only(left: AppSpacing.md),
        onPressed: () {
          pageIndexNotifier.value = 0;
        },
        child: Text(
          'Back',
          style: TextStyle(
            color: AppColors.of(context).primary,
            fontSize: 17,
          ),
        ),
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
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          itemCount: items.length + 2, // +2 for title and select all row
          itemBuilder: (context, index) {
            // Title
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  'Select Pantry Items',
                  style: AppTypography.h4.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              );
            }

            // Select All / Deselect All row
            if (index == 1) {
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

            // Pantry items (index - 2 because of title and select all rows)
            final itemIndex = index - 2;
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

