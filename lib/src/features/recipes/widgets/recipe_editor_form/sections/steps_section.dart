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

  // Method to handle drag start
  void _onDragStart() {
    setState(() {
      _isDragging = true;
      // Unfocus any text fields to prevent the leader-follower error
      FocusScope.of(context).unfocus();
    });
  }

  // Method to handle drag end
  void _onDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Instructions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

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
            onReorderStart: (_) => _onDragStart(),
            onReorderEnd: (_) => _onDragEnd(),
            itemCount: widget.steps.length,
            onReorder: widget.onReorderSteps,
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                key: ValueKey(step.id),
                child: StepListItem(
                  index: index,
                  step: step,
                  autoFocus: widget.autoFocusStepId == step.id && !_isDragging,
                  onRemove: () => widget.onRemoveStep(step.id),
                  onUpdate: (updatedStep) => widget.onUpdateStep(step.id, updatedStep),
                  onAddNext: () => widget.onAddStep(false),
                  onFocus: (hasFocus) => widget.onFocusChanged(step.id, hasFocus),
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onAddStep(false),
                icon: const Icon(Icons.add),
                label: const Text('Add Step'),
              ),
              const SizedBox(width: 8),
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
