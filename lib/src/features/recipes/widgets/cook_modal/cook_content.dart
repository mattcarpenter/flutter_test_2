import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart' as recipe_steps;
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' as recipe_provider;
import '../../../../../database/database.dart';
import '../../../../../database/models/cooks.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../utils/recipe_text_renderer.dart';
import '../../../timers/widgets/start_timer_dialog.dart';
import 'ingredients_sheet.dart';
import '../add_recipe_modal.dart';
import 'package:collection/collection.dart';
import '../../../../theme/spacing.dart';

class CookContent extends ConsumerStatefulWidget {
  final String initialCookId;
  final String initialRecipeId;
  final BuildContext modalContext;

  const CookContent({
    Key? key,
    required this.initialCookId,
    required this.initialRecipeId,
    required this.modalContext,
  }) : super(key: key);

  @override
  ConsumerState<CookContent> createState() => CookContentState();
}

class CookContentState extends ConsumerState<CookContent> {
  List<Ingredient>? _ingredients;
  final GlobalKey<_CookStepDisplayState> _cookStepDisplayKey = GlobalKey<_CookStepDisplayState>();
  final ScrollController _scrollController = ScrollController();

  // Public methods that can be called from the parent
  void showIngredientsSheet() {
    if (_ingredients != null) {
      showIngredientsModal(
        context,
        _ingredients!,
        recipeId: widget.initialRecipeId,
      );
    }
  }

  void showAddRecipeSheet() {
    showAddRecipeModal(
      context,
      title: context.l10n.recipeCookAddRecipeTitle,
      onRecipeSelected: (recipe) async {
        // Add the selected recipe to cook session
        final cookNotifier = ref.read(cookNotifierProvider.notifier);
        final userId = ref.read(userIdProvider);

        // Create a new cook for the selected recipe
        await cookNotifier.startCook(
          recipeId: recipe.id,
          recipeName: recipe.title,
          userId: userId,
        );
      },
      validateRecipe: (recipe) async {
        // Validate that recipe has non-section steps before allowing it to be added to cook
        final nonSectionSteps = recipe.steps?.where((s) => s.type != 'section').toList() ?? [];
        if (nonSectionSteps.isEmpty) {
          return "This recipe doesn't have any cooking steps yet. Please add steps to this recipe before starting a cook session.";
        }
        return null; // Valid
      },
    );
  }

  Future<void> completeCook() async {
    final activeCookId = ref.read(activeCookInModalProvider);
    if (activeCookId == null) return;

    // 1. Save cook to "my cooks" history (mark as completed)
    await ref.read(cookNotifierProvider.notifier).finishCook(
      cookId: activeCookId,
    );

    // 2. Get remaining active cooks
    final inProgressCooks = ref.read(cookNotifierProvider)
        .maybeWhen(
          data: (cooks) => cooks.where((c) => c.status == CookStatus.inProgress).toList(),
          orElse: () => [],
        );

    final remainingCooks = inProgressCooks
        .where((cook) => cook.id != activeCookId)
        .toList();

    // 3. Navigate based on remaining cooks
    if (remainingCooks.isEmpty) {
      // No more active cooks - close modal
      if (mounted && widget.modalContext.mounted) {
        Navigator.of(widget.modalContext).pop();
      }
    } else {
      // Switch to next active cook
      ref.read(activeCookInModalProvider.notifier).state = remainingCooks.first.id;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set the initial active cook
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeCookInModalProvider.notifier).state = widget.initialCookId;
    });
  }

  // Helper functions for handling sections in step navigation

  /// Get only non-section steps
  List<recipe_steps.Step> _getNonSectionSteps(List<recipe_steps.Step> allSteps) {
    return allSteps.where((s) => s.type != 'section').toList();
  }

  /// Get the display step number (1-based, excluding sections)
  int _getDisplayStepNumber(List<recipe_steps.Step> allSteps, int currentIndex) {
    int count = 0;
    for (int i = 0; i <= currentIndex && i < allSteps.length; i++) {
      if (allSteps[i].type != 'section') {
        count++;
      }
    }
    return count;
  }

  /// Find next non-section step index (returns null if no more steps)
  int? _findNextStepIndex(List<recipe_steps.Step> allSteps, int currentIndex) {
    for (int i = currentIndex + 1; i < allSteps.length; i++) {
      if (allSteps[i].type != 'section') {
        return i;
      }
    }
    return null;
  }

  /// Find previous non-section step index (returns null if at start)
  int? _findPreviousStepIndex(List<recipe_steps.Step> allSteps, int currentIndex) {
    for (int i = currentIndex - 1; i >= 0; i--) {
      if (allSteps[i].type != 'section') {
        return i;
      }
    }
    return null;
  }

  /// Find first non-section step index
  int _findFirstNonSectionStepIndex(List<recipe_steps.Step> allSteps) {
    for (int i = 0; i < allSteps.length; i++) {
      if (allSteps[i].type != 'section') {
        return i;
      }
    }
    return 0; // Fallback (shouldn't happen if validation works)
  }

  /// Calculate completion percentage for a cook session
  int _calculateCookProgress(CookEntry cook) {
    // Fetch recipe to get steps
    final recipeAsync = ref.watch(recipe_provider.recipeByIdStreamProvider(cook.recipeId));

    return recipeAsync.when(
      data: (recipe) {
        if (recipe == null || recipe.steps == null) return 0;

        final steps = recipe.steps!;
        final nonSectionSteps = _getNonSectionSteps(steps);

        if (nonSectionSteps.isEmpty) return 0;

        // Count how many non-section steps we've passed
        int completedSteps = 0;
        for (int i = 0; i < cook.currentStepIndex && i < steps.length; i++) {
          if (steps[i].type != 'section') {
            completedSteps++;
          }
        }

        // If we're currently ON a non-section step, it counts as in-progress
        // Only count it as completed if we've moved past it

        final percentage = (completedSteps / nonSectionSteps.length * 100).round();
        return percentage.clamp(0, 100);
      },
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the active cook ID from our state provider
    final activeCookId = ref.watch(activeCookInModalProvider);

    // Get all in-progress cooks
    final cooksAsyncValue = ref.watch(cookNotifierProvider);

    // Find the currently active cook
    final CookEntry? activeCook = cooksAsyncValue.when(
      loading: () => null,
      error: (_, __) => null,
      data: (cooks) => cooks.firstWhereOrNull((c) => c.id == activeCookId),
    );

    // Get all in-progress cooks for the recipe list
    // Sort by startedAt to maintain stable order (oldest first)
    final List<CookEntry> inProgressCooks = cooksAsyncValue.when(
      loading: () => [],
      error: (_, __) => [],
      data: (cooks) {
        final filtered = cooks.where((c) => c.status == CookStatus.inProgress).toList();
        filtered.sort((a, b) {
          final aTime = a.startedAt ?? 0;
          final bTime = b.startedAt ?? 0;
          return aTime.compareTo(bTime);
        });
        return filtered;
      },
    );

    // Get the active recipe details
    final String activeRecipeId = activeCook?.recipeId ?? widget.initialRecipeId;
    // Explicitly using the provider from recipe_provider.dart
    final recipeAsync = ref.watch(recipe_provider.recipeByIdStreamProvider(activeRecipeId));

    // Use 75% of screen height for content
    // Status bar collapses when modal opens, so we have plenty of room
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: recipeAsync.when(
        loading: () => _buildLoadingContent(),
        error: (error, _) => _buildErrorContent(error.toString()),
        data: (recipe) {
          if (recipe == null) {
            return _buildErrorContent("Recipe not found");
          }

          // Get the steps and ingredients from the recipe
          final steps = recipe.steps ?? [];
          final ingredients = recipe.ingredients ?? [];
          _ingredients = ingredients; // Store for action buttons

          // Ensure we have at least one non-section step
          final nonSectionSteps = _getNonSectionSteps(steps);
          if (nonSectionSteps.isEmpty) {
            return _buildErrorContent(context.l10n.recipeCookNoSteps);
          }

          // Get the current step index - ensure it's on a non-section step
          int currentStepIndex = activeCook?.currentStepIndex ?? 0;

          // Safety: if current index points to a section, skip to next non-section
          if (currentStepIndex < steps.length && steps[currentStepIndex].type == 'section') {
            final nextStep = _findNextStepIndex(steps, currentStepIndex);
            currentStepIndex = nextStep ?? _findFirstNonSectionStepIndex(steps);
          }

          // Clamp to valid range
          final validStepIndex = currentStepIndex.clamp(0, steps.length - 1);

          return _buildStepContent(
            recipe: recipe,
            steps: steps,
            ingredients: ingredients,
            currentStepIndex: validStepIndex.toInt(),
            totalSteps: nonSectionSteps.length, // Only count non-sections
            displayStepNumber: _getDisplayStepNumber(steps, validStepIndex.toInt()),
            inProgressCooks: inProgressCooks,
            activeCookId: activeCookId,
          );
        },
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorContent(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookCard(CookEntry cook, bool isActive) {
    final percentage = _calculateCookProgress(cook);
    final colors = AppColors.of(context);
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        // Switch to this cook
        ref.read(activeCookInModalProvider.notifier).state = cook.id;
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: isActive
              ? (isLight
                  ? AppColorSwatches.primary[100]  // Soft apricot in light mode (unchanged)
                  : AppColorSwatches.neutral[800])  // Lighter gray in dark mode - stands out from inactive
              : (isLight
                  ? AppColorSwatches.neutral[300]  // Light gray in light mode (unchanged)
                  : AppColorSwatches.neutral[900]),  // Very dark in dark mode - recedes
          borderRadius: BorderRadius.circular(12),
          // No border - flat design
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              cook.recipeName,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
                color: colors.textPrimary,
              ),
              maxLines: 1, // Single line for clean truncation
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$percentage% complete',
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? (isLight
                        ? colors.primary  // Orange text in light mode
                        : colors.textSecondary)  // Light gray text in dark mode - subtle, not too bright
                    : colors.textSecondary,  // Theme-aware secondary text for inactive
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent({
    required dynamic recipe,
    required List<recipe_steps.Step> steps,
    required List<Ingredient> ingredients,
    required int currentStepIndex,
    required int totalSteps,
    required int displayStepNumber,
    required List<CookEntry> inProgressCooks,
    required String? activeCookId,
  }) {
    // Find next and previous non-section indices
    final prevStepIndex = _findPreviousStepIndex(steps, currentStepIndex);
    final nextStepIndex = _findNextStepIndex(steps, currentStepIndex);
    final isLastStep = nextStepIndex == null;
    final currentStep = steps[currentStepIndex];

    // Find the current section
    String sectionTitle = "";
    for (int i = currentStepIndex; i >= 0; i--) {
      if (steps[i].type == 'section') {
        sectionTitle = steps[i].text;
        break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.max, // Take all available height
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top section - Step number and section
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title - always rendered to maintain consistent spacing
              Text(
                sectionTitle.isNotEmpty ? sectionTitle : ' ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                  color: AppColors.of(context).textTertiary,
                ),
              ),
              const SizedBox(height: 4),

              // Step number and progress indicator
              Text(
                'Step $displayStepNumber of $totalSteps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Middle section - Scrollable instruction text with fade gradients at top/bottom
        Flexible(
          fit: FlexFit.tight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.95, 1.0], // Fade in first 5% and last 5%
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CookStepDisplay(
                          key: _cookStepDisplayKey,
                          availableHeight: constraints.maxHeight,
                          stepText: currentStep.text,
                          cookId: activeCookId ?? '',
                          stepIndex: currentStepIndex,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: Platform.isIOS ? FontWeight.w600 : FontWeight.bold,
                            height: 1.3,
                            fontFamily: Platform.isIOS ? null : 'Inter',
                            letterSpacing: Platform.isIOS ? -0.2 : 0,
                            color: AppColors.of(context).textPrimary,
                          ),
                          // Recipe context for timer integration
                          recipeId: recipe.id,
                          recipeName: recipe.title,
                          stepId: currentStep.id,
                          displayStepNumber: displayStepNumber,
                          totalSteps: totalSteps,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom section - Recipe cards (edge-to-edge) and navigation buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recipe cards - edge-to-edge scrolling (only show if multiple cooks)
            if (inProgressCooks.length > 1) ...[
              SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero, // Critical for edge-to-edge
                  itemCount: inProgressCooks.length,
                  itemBuilder: (context, index) {
                    final cook = inProgressCooks[index];
                    final isFirst = index == 0;
                    final isLast = index == inProgressCooks.length - 1;
                    final isActive = cook.id == activeCookId;

                    return Container(
                      margin: EdgeInsets.only(
                        left: isFirst ? AppSpacing.lg : 0.0,
                        right: isLast ? AppSpacing.lg : AppSpacing.md,
                      ),
                      child: _buildCookCard(cook, isActive),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Navigation buttons - contained with padding
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Previous button (disabled when on first step)
                  Expanded(
                    child: AppButtonVariants.primaryOutline(
                      text: context.l10n.recipeCookPrevious,
                      size: AppButtonSize.large,
                      shape: AppButtonShape.square,
                      fullWidth: true,
                      onPressed: prevStepIndex != null ? () => _updateStep(prevStepIndex) : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // Next/Complete button
                  Expanded(
                    child: AppButtonVariants.primaryFilled(
                      text: isLastStep ? context.l10n.commonDone : context.l10n.recipeCookNext,
                      size: AppButtonSize.large,
                      shape: AppButtonShape.square,
                      fullWidth: true,
                      onPressed: () {
                        if (isLastStep) {
                          completeCook();
                        } else {
                          _updateStep(nextStepIndex);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateStep(int newIndex) {
    // Reset scroll immediately if possible
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0,
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }

    final activeCookId = ref.read(activeCookInModalProvider);
    if (activeCookId != null) {
      ref.read(cookNotifierProvider.notifier).updateCook(
        cookId: activeCookId,
        currentStepIndex: newIndex,
      );
    }
  }
}

// Transition types for step display animation
enum _TransitionType { none, step, recipe }
enum _TransitionDirection { forward, backward }

/// Animated step display widget with smart transition detection
///
/// Automatically detects whether a step change or recipe change occurred
/// and applies the appropriate transition:
/// - Step changes: Slide + fade (parallel, direction-aware)
/// - Recipe changes: Scale + fade (sequential)
class CookStepDisplay extends StatefulWidget {
  final double availableHeight;
  final String stepText;
  final String cookId;
  final int stepIndex;
  final TextStyle style;

  // Recipe context for timer integration
  final String recipeId;
  final String recipeName;
  final String stepId;
  final int displayStepNumber;
  final int totalSteps;

  const CookStepDisplay({
    super.key,
    required this.availableHeight,
    required this.stepText,
    required this.cookId,
    required this.stepIndex,
    required this.style,
    required this.recipeId,
    required this.recipeName,
    required this.stepId,
    required this.displayStepNumber,
    required this.totalSteps,
  });

  @override
  State<CookStepDisplay> createState() => _CookStepDisplayState();
}

class _CookStepDisplayState extends State<CookStepDisplay>
    with TickerProviderStateMixin {

  AnimationController? _controller;

  // Track previous child for exit animation
  String? _previousStepText;
  String? _previousKey;

  // Transition state
  _TransitionType _transitionType = _TransitionType.none;
  _TransitionDirection _direction = _TransitionDirection.forward;

  @override
  void initState() {
    super.initState();
    // No animation on first render
  }

  @override
  void didUpdateWidget(CookStepDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect what changed
    if (oldWidget.cookId != widget.cookId) {
      _previousStepText = oldWidget.stepText;
      _previousKey = '${oldWidget.cookId}-${oldWidget.stepIndex}';
      _transitionType = _TransitionType.recipe;
      _startTransition();
    } else if (oldWidget.stepIndex != widget.stepIndex) {
      _previousStepText = oldWidget.stepText;
      _previousKey = '${oldWidget.cookId}-${oldWidget.stepIndex}';
      _direction = widget.stepIndex > oldWidget.stepIndex
          ? _TransitionDirection.forward
          : _TransitionDirection.backward;
      _transitionType = _TransitionType.step;
      _startTransition();
    }
  }

  void _startTransition() {
    // Dispose old controller if exists
    _controller?.dispose();

    // Create new controller - snappy duration for responsive carousel feel
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    // Clean up old child when animation completes
    _controller!.addStatusListener(_onAnimationComplete);

    // Start animation
    _controller!.forward();
  }

  void _onAnimationComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _previousStepText = null;
        _previousKey = null;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Build the step text with duration detection and timer support
  Widget _buildStepTextContent(String text, Key? key, {bool enableTap = true}) {
    return RecipeTextRenderer(
      key: key,
      text: text,
      baseStyle: widget.style,
      textAlign: TextAlign.center,
      enableRecipeLinks: false, // Don't link recipes in cook modal
      enableDurationLinks: true,
      onDurationTap: enableTap
          ? (duration, detectedText) {
              showStartTimerDialog(
                context,
                recipeId: widget.recipeId,
                recipeName: widget.recipeName,
                stepId: widget.stepId,
                stepNumber: widget.displayStepNumber,
                totalSteps: widget.totalSteps,
                duration: duration,
                detectedText: detectedText,
              );
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If animating, use fixed-height container to prevent jumping
    if (_previousStepText != null) {
      return SizedBox(
        height: widget.availableHeight,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Exiting child
              _buildExitingChild(),

              // Entering child
              _buildEnteringChild(),
            ],
          ),
        ),
      );
    }

    // Not animating - use natural sizing for scrollability
    return _buildStepTextContent(
      widget.stepText,
      ValueKey('${widget.cookId}-${widget.stepIndex}'),
    );
  }

  Widget _buildExitingChild() {
    if (_transitionType == _TransitionType.step) {
      return _buildStepExit();
    } else {
      return _buildRecipeExit();
    }
  }

  Widget _buildEnteringChild() {
    if (_transitionType == _TransitionType.step) {
      return _buildStepEnter();
    } else if (_transitionType == _TransitionType.recipe) {
      return _buildRecipeEnter();
    } else {
      // Initial render - no animation
      return _buildStepTextContent(
        widget.stepText,
        ValueKey('${widget.cookId}-${widget.stepIndex}'),
      );
    }
  }

  /// Step exit: Slide and fade out
  Widget _buildStepExit() {
    final animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOutCubic,
    );

    // Exit direction: slide in SAME direction we're moving
    // Very subtle movement - just 30% of screen width
    final exitOffset = _direction == _TransitionDirection.forward
        ? const Offset(-0.3, 0.0) // Forward: exit to LEFT (30%)
        : const Offset(0.3, 0.0);  // Backward: exit to RIGHT (30%)

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,  // Start at center
        end: exitOffset,     // End halfway off-screen
      ).animate(animation),
      child: FadeTransition(
        // Extended to 50% (175ms) to overlap more with entering text
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _controller!,
            curve: const Interval(0.0, 0.5, curve: Curves.easeInCubic),
          ),
        ),
        child: _buildStepTextContent(
          _previousStepText!,
          ValueKey(_previousKey),
          enableTap: false, // Not tappable during exit animation
        ),
      ),
    );
  }

  /// Step enter: Slide in and fade in
  Widget _buildStepEnter() {
    final animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOutCubic,
    );

    // Enter direction: slide from OPPOSITE direction we're moving
    // Subtle movement - just 50% of screen width for gentle carousel effect
    final enterOffset = _direction == _TransitionDirection.forward
        ? const Offset(0.5, 0.0)  // Forward: enter from RIGHT (50% of screen)
        : const Offset(-0.5, 0.0); // Backward: enter from LEFT (50% of screen)

    return SlideTransition(
      position: Tween<Offset>(
        begin: enterOffset,   // Start off-screen
        end: Offset.zero,     // End at center
      ).animate(animation),
      child: FadeTransition(
        // Start earlier (30% = 105ms) to create crossfade with exiting text
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller!,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _buildStepTextContent(
          widget.stepText,
          ValueKey('${widget.cookId}-${widget.stepIndex}'),
          enableTap: true, // Fully interactive on enter
        ),
      ),
    );
  }

  /// Recipe exit: Scale down and fade out
  Widget _buildRecipeExit() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.8).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: const Interval(0.0, 0.5, curve: Curves.easeInCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _controller!,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        ),
        child: _buildStepTextContent(
          _previousStepText!,
          ValueKey(_previousKey),
          enableTap: false, // Not tappable during exit animation
        ),
      ),
    );
  }

  /// Recipe enter: Scale up and fade in
  Widget _buildRecipeEnter() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller!,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
        ),
        child: _buildStepTextContent(
          widget.stepText,
          ValueKey('${widget.cookId}-${widget.stepIndex}'),
          enableTap: true, // Fully interactive on enter
        ),
      ),
    );
  }
}
