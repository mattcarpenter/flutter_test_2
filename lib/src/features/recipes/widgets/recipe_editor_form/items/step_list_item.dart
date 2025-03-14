import 'package:flutter/material.dart' hide Step;
import 'package:recipe_app/database/models/steps.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../utils/context_menu_utils.dart';

class StepListItem extends StatefulWidget {
  final int index;
  final Step step;
  final bool autoFocus;
  final VoidCallback onRemove;
  final Function(Step) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const StepListItem({
    Key? key,
    required this.index,
    required this.step,
    required this.autoFocus,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  _StepListItemState createState() => _StepListItemState();
}

class _StepListItemState extends State<StepListItem> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  bool get isSection => widget.step.type == 'section';

  final GlobalKey _dragHandleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.step.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus(_focusNode.hasFocus);
      setState(() {});
    });
    if (widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant StepListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.text != widget.step.text &&
        _textController.text != widget.step.text) {
      _textController.text = widget.step.text;
    }

    // Handle autofocus change
    if (!oldWidget.autoFocus && widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _contextMenuIsAllowed(Offset location) {
    return isLocationOutsideKey(location, _dragHandleKey);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.white;

    if (isSection) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.segment),
          title: Focus(
            focusNode: _focusNode,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Section name',
                border: InputBorder.none,
              ),
              controller: _textController,
              style: const TextStyle(fontWeight: FontWeight.bold),
              onChanged: (value) {
                widget.onUpdate(widget.step.copyWith(text: value));
              },
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.onRemove,
              ),
              SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ContextMenuWidget(
      contextMenuIsAllowed: _contextMenuIsAllowed,
      menuProvider: (_) {
        return Menu(
          children: [
            MenuAction(
              title: 'Convert to section',
              image: MenuImage.icon(Icons.segment),
              callback: () {
                // Convert the step to a section
                widget.onUpdate(widget.step.copyWith(
                    type: 'section',
                    text: widget.step.text.isEmpty ? 'New Section' : widget.step.text
                ));
              },
            ),
          ],
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: _focusNode.hasFocus
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onRemove,
                  )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Describe this step',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                      maxLines: null,
                      minLines: 2,
                      onChanged: (value) {
                        widget.onUpdate(widget.step.copyWith(text: value));
                      },
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.onAddNext(),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Space for the drag handle
              ],
            ),
          ),
          // Position the drag handle on top so it's clickable
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 40,
              child: ReorderableDragStartListener(
                key: _dragHandleKey,
                index: widget.index,
                child: const Icon(Icons.drag_handle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
