import 'package:flutter/material.dart' hide Step;
import 'package:recipe_app/database/models/steps.dart';

import '../items/step_list_item.dart';
import '../utils/context_menu_utils.dart';

class StepsSection extends StatefulWidget {
  final List<Step> steps;
  final String? autoFocusStepId;
  final Function(bool isSection) onAddStep;
  final Function(String id) onRemoveStep;
  final Function(String id, Step updatedStep) onUpdateStep;
  final Function(int oldIndex, int newIndex) onReorderSteps;
  final Function(String id, bool hasFocus) onFocusChanged;

  const StepsSection({
    Key? key,
    required this.steps,
    required this.autoFocusStepId,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onUpdateStep,
    required this.onReorderSteps,
    required this.onFocusChanged,
  }) : super(key: key);

  @override
  _StepsSectionState createState() => _StepsSectionState();
}

class _StepsSectionState extends State<StepsSection> {
  bool _isDragging = false;
  int? _draggedIndex;

  // Method to handle drag start
  void _onDragStart(int index) {
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
        });
      }
    });
  }

  // Calculate visual index during drag operations
  int? _getVisualIndex(int index) {
    if (!_isDragging || _draggedIndex == null) return null;

    // The dragged item doesn't have a visual position (it's floating)
    if (index == _draggedIndex) return null;

    // Items before the dragged item stay in the same visual position
    if (index < _draggedIndex!) {
      return index;
    }

    // Items after the dragged item shift up by one visual position
    return index - 1;
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
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onAddStep(false),
                icon: const Icon(Icons.add),
                label: const Text('Add Step'),
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onAddStep(true),
                icon: const Icon(Icons.segment),
                label: const Text('Add Section'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
