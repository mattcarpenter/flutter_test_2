import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart' as recipe_steps;
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' as recipe_provider;
import '../../../../../database/database.dart';
import '../../../../../database/models/cooks.dart';
import '../../../../theme/colors.dart';
import '../../../../widgets/wolt/button/wolt_elevated_button.dart';
import 'ingredients_sheet.dart';
import 'add_recipe_search_modal.dart';
import 'package:collection/collection.dart';

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

  // Public methods that can be called from the parent
  void showIngredientsSheet() {
    if (_ingredients != null) {
      showIngredientsModal(context, _ingredients!);
    }
  }

  void showAddRecipeSheet() {
    showAddRecipeSearchModal(context, cookId: widget.initialCookId);
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

    // Add fixed height to the entire content to avoid flex/expanded issues
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

          // Get the current step index from the activeCook or default to 0
          final currentStepIndex = activeCook?.currentStepIndex ?? 0;

          // Ensure we have a valid step index and handle empty steps list
          if (steps.isEmpty) {
            return _buildErrorContent("No steps found for this recipe");
          }

          final validStepIndex = currentStepIndex.clamp(0, steps.length - 1);

          return _buildStepContent(
            recipe: recipe,
            steps: steps,
            ingredients: ingredients,
            currentStepIndex: validStepIndex.toInt(),
            totalSteps: steps.length,
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

  Widget _buildStepContent({
    required dynamic recipe,
    required List<recipe_steps.Step> steps,
    required List<Ingredient> ingredients,
    required int currentStepIndex,
    required int totalSteps,
    required List<CookEntry> inProgressCooks,
    required String? activeCookId,
  }) {
    // Find the current step
    final isFirstStep = currentStepIndex == 0;
    final isLastStep = currentStepIndex == totalSteps - 1;
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
                'Step ${currentStepIndex + 1} of $totalSteps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Middle section - Scrollable instruction text (centered when short, scrollable when long)
        Flexible(
          fit: FlexFit.tight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: CookStepDisplay(
                      key: const ValueKey('cook-step-display'),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom section - Recipe cards and navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recipe cards - only show if multiple cooks
              if (inProgressCooks.length > 1) ...[
                SizedBox(
                  height: 70, // Reduced height
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Active cooks as recipe cards
                      ...inProgressCooks.map((cook) {
                        final isActive = cook.id == activeCookId;
                        return GestureDetector(
                          onTap: () {
                            // Switch to this cook
                            ref.read(activeCookInModalProvider.notifier).state = cook.id;
                          },
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    cook.recipeName,
                                    style: TextStyle(
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  isActive ? 'Now cooking' : 'Tap to switch',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive ? Theme.of(context).primaryColor : Colors.grey
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Navigation buttons - Always show 2 equal width buttons
              Row(
                children: [
                  // Previous button (disabled when on first step)
                  Expanded(
                    child: WoltElevatedButton(
                      theme: WoltElevatedButtonTheme.secondary,
                      onPressed: isFirstStep ? () {} : () => _updateStep(currentStepIndex - 1),
                      enabled: !isFirstStep,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Next/Complete button
                  Expanded(
                    child: WoltElevatedButton(
                      onPressed: () {
                        if (isLastStep) {
                          completeCook();
                        } else {
                          _updateStep(currentStepIndex + 1);
                        }
                      },
                      child: Text(isLastStep ? 'Complete' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateStep(int newIndex) {
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
  final String stepText;
  final String cookId;
  final int stepIndex;
  final TextStyle style;

  const CookStepDisplay({
    super.key,
    required this.stepText,
    required this.cookId,
    required this.stepIndex,
    required this.style,
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

  @override
  Widget build(BuildContext context) {
    // If no controller yet (initial render), just show current text
    if (_controller == null) {
      return Text(
        widget.stepText,
        style: widget.style,
        textAlign: TextAlign.center,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Exiting child (if transitioning)
        if (_previousStepText != null)
          _buildExitingChild(),

        // Entering child
        _buildEnteringChild(),
      ],
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
      return Text(
        widget.stepText,
        key: ValueKey('${widget.cookId}-${widget.stepIndex}'),
        style: widget.style,
        textAlign: TextAlign.center,
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
        child: Text(
          _previousStepText!,
          key: ValueKey(_previousKey),
          style: widget.style,
          textAlign: TextAlign.center,
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
        child: Text(
          widget.stepText,
          key: ValueKey('${widget.cookId}-${widget.stepIndex}'),
          style: widget.style,
          textAlign: TextAlign.center,
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
        child: Text(
          _previousStepText!,
          key: ValueKey(_previousKey),
          style: widget.style,
          textAlign: TextAlign.center,
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
        child: Text(
          widget.stepText,
          key: ValueKey('${widget.cookId}-${widget.stepIndex}'),
          style: widget.style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
