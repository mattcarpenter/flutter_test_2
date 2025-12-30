import 'package:flutter/material.dart' hide Step;
import 'package:recipe_app/database/models/steps.dart';

import '../../../../../widgets/app_button.dart';
import '../../../../../widgets/app_overflow_button.dart';
import '../../../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../items/step_list_item.dart';
import '../utils/context_menu_utils.dart';
import '../../../../../theme/spacing.dart';

class StepsSection extends StatefulWidget {
  final List<Step> steps;
  final String? autoFocusStepId;
  final Function(bool isSection) onAddStep;
  final Function(String id) onRemoveStep;
  final Function(String id, Step updatedStep) onUpdateStep;
  final Function(int oldIndex, int newIndex) onReorderSteps;
  final Function(String id, bool hasFocus) onFocusChanged;
  final VoidCallback? onEditAsText;
  final VoidCallback? onClearAll;
  final ScrollController? scrollController;

  const StepsSection({
    Key? key,
    required this.steps,
    required this.autoFocusStepId,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onUpdateStep,
    required this.onReorderSteps,
    required this.onFocusChanged,
    this.onEditAsText,
    this.onClearAll,
    this.scrollController,
  }) : super(key: key);

  @override
  _StepsSectionState createState() => _StepsSectionState();
}

class _StepsSectionState extends State<StepsSection> {
  bool _isDragging = false;
  int? _draggedIndex;
  
  // Memoized visual indices to avoid recalculation on every build
  final Map<int, int?> _cachedVisualIndices = {};
  
  // Track which items actually need visual updates (performance optimization)
  final Set<int> _visuallyAffectedItems = {};

  // Method to handle drag start
  void _onDragStart(int index) {
    // Pre-calculate all visual indices once instead of on every build
    _cachedVisualIndices.clear();
    _visuallyAffectedItems.clear();
    
    for (int i = 0; i < widget.steps.length; i++) {
      int? visualIndex;
      
      // The dragged item doesn't have a visual position (it's floating)
      if (i == index) {
        visualIndex = null;
        _visuallyAffectedItems.add(i); // Dragged item changes
      }
      // Items before the dragged item stay in the same visual position  
      else if (i < index) {
        visualIndex = i;
        // Only first item before drag might change border (if it becomes last in group)
        if (i == index - 1) _visuallyAffectedItems.add(i);
      }
      // Items after the dragged item shift up by one visual position
      else {
        visualIndex = i - 1;
        _visuallyAffectedItems.add(i); // All items after change position
      }
      
      _cachedVisualIndices[i] = visualIndex;
    }
    
    setState(() {
      _isDragging = true;
      _draggedIndex = index;
      // Unfocus any text fields to prevent the leader-follower error
      FocusScope.of(context).unfocus();
    });
  }

  // Method to handle drag end
  void _onDragEnd(int index) {
    // Keep both flags for 250ms to match ReorderableListView's animation timing
    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          _isDragging = false;
          _draggedIndex = null;
          _cachedVisualIndices.clear();
          _visuallyAffectedItems.clear();
        });
      }
    });
  }

  // Fast lookup of pre-calculated visual index (performance optimized)
  int? _getVisualIndex(int index) {
    if (!_isDragging || _draggedIndex == null) return null;
    return _cachedVisualIndices[index];
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.steps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No steps added yet."),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            proxyDecorator: defaultProxyDecorator,
            onReorderStart: (index) => _onDragStart(index),
            onReorderEnd: (index) => _onDragEnd(index),
            itemCount: widget.steps.length,
            onReorder: widget.onReorderSteps,
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              return Padding(
                padding: EdgeInsets.zero,
                key: ValueKey(step.id),
                child: StepListItem(
                  index: index,
                  step: step,
                  autoFocus: widget.autoFocusStepId == step.id && !_isDragging,
                  isDragging: _draggedIndex == index,
                  onRemove: () => widget.onRemoveStep(step.id),
                  onUpdate: (updatedStep) => widget.onUpdateStep(step.id, updatedStep),
                  onAddNext: () => widget.onAddStep(false),
                  onFocus: (hasFocus) => widget.onFocusChanged(step.id, hasFocus),
                  allSteps: widget.steps,
                  enableGrouping: true,
                  visualIndex: _getVisualIndex(index),
                  draggedIndex: _draggedIndex,
                  scrollController: widget.scrollController,
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              // Add Step button - flex column 1
              Expanded(
                flex: 1,
                child: AppButton(
                  text: 'Add Step',
                  onPressed: () => widget.onAddStep(false),
                  theme: AppButtonTheme.secondary,
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  leadingIcon: const Icon(Icons.add),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              
              // Add Section button - flex column 2  
              Expanded(
                flex: 1,
                child: AppButton(
                  text: 'Add Section',
                  onPressed: () => widget.onAddStep(true),
                  theme: AppButtonTheme.secondary,
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  leadingIcon: const Icon(Icons.segment),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              
              // Context menu button - compact overflow style
              AppOverflowButton(
                items: [
                  AdaptiveMenuItem(
                    title: 'Edit as Text',
                    icon: const Icon(Icons.edit_note),
                    onTap: () => widget.onEditAsText?.call(),
                  ),
                  AdaptiveMenuItem.divider(),
                  AdaptiveMenuItem(
                    title: 'Clear All Steps',
                    icon: const Icon(Icons.clear_all),
                    isDestructive: true,
                    onTap: () => widget.onClearAll?.call(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
