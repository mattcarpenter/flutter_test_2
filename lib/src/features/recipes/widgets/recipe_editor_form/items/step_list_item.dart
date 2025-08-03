import 'package:flutter/material.dart' hide Step;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../../../theme/colors.dart';
import '../utils/context_menu_utils.dart';

class StepListItem extends StatefulWidget {
  final int index;
  final Step step;
  final bool autoFocus;
  final bool isDragging;
  final VoidCallback onRemove;
  final Function(Step) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;
  final List<Step> allSteps;
  final bool enableGrouping;
  final int? visualIndex;
  final int? draggedIndex;

  const StepListItem({
    Key? key,
    required this.index,
    required this.step,
    required this.autoFocus,
    required this.isDragging,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
    required this.allSteps,
    this.enableGrouping = false,
    this.visualIndex,
    this.draggedIndex,
  }) : super(key: key);

  @override
  _StepListItemState createState() => _StepListItemState();
}

class _StepListItemState extends State<StepListItem> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  bool get isSection => widget.step.type == 'section';

  final GlobalKey _dragHandleKey = GlobalKey();

  // Grouping detection methods
  bool get _isGrouped => widget.enableGrouping;

  bool get _isFirstInGroup {
    if (!_isGrouped) return false;

    // Use visual index during drag operations if available
    final effectiveIndex = widget.visualIndex ?? widget.index;

    // Only the very first item (position 0) is first in group
    return effectiveIndex == 0;
  }

  bool get _isLastInGroup {
    if (!_isGrouped) return false;

    // Use visual index during drag operations if available
    final effectiveIndex = widget.visualIndex ?? widget.index;

    // During drag operations, check if this is the last visual item
    if (widget.visualIndex != null) {
      final visualArrayLength = widget.allSteps.length - 1;
      if (effectiveIndex == visualArrayLength - 1) return true;
    } else {
      // Normal (non-drag) logic - check if this is the last item
      if (effectiveIndex == widget.allSteps.length - 1) return true;
    }

    // Look forwards to find the first non-section item
    final maxIndex = widget.visualIndex != null
        ? widget.allSteps.length - 1  // During drag, array is conceptually shorter
        : widget.allSteps.length;

    for (int i = effectiveIndex + 1; i < maxIndex; i++) {
      if (i >= widget.allSteps.length) continue;
      final nextItem = widget.allSteps[i];
      if (nextItem.type != 'section') {
        return false; // Found a non-section item, so we're not last in group
      }
    }

    // Only sections found after this item, so this is last in group
    return true;
  }

  // Border radius calculation for grouping
  BorderRadius _getBorderRadius() {
    if (!_isGrouped) {
      return BorderRadius.circular(8.0);
    }

    if (_isFirstInGroup && _isLastInGroup) {
      // Single item in group
      return BorderRadius.circular(8.0);
    } else if (_isFirstInGroup) {
      return const BorderRadius.only(
        topLeft: Radius.circular(8.0),
        topRight: Radius.circular(8.0),
      );
    } else if (_isLastInGroup) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(8.0),
        bottomRight: Radius.circular(8.0),
      );
    } else {
      // Middle item - no rounded corners
      return BorderRadius.zero;
    }
  }

  // Border calculation for grouping
  Border _getBorder() {
    final colors = AppColors.of(context);
    final borderColor = colors.borderStrong;
    const borderWidth = 1.0;

    if (!_isGrouped || widget.isDragging) {
      // During drag, use full border to prevent animation glitches
      return Border.all(color: borderColor, width: borderWidth);
    }

    if (_isFirstInGroup && _isLastInGroup) {
      // Single item gets full border
      return Border.all(color: borderColor, width: borderWidth);
    } else if (_isFirstInGroup) {
      // First item: full border
      return Border.all(color: borderColor, width: borderWidth);
    } else {
      // Non-first items: omit top border to prevent double borders
      return Border(
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: borderColor, width: borderWidth),
        bottom: BorderSide(color: borderColor, width: borderWidth),
      );
    }
  }


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
      // Force focus immediately and repeatedly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceFocus(0);
      });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forceFocus(0);
      });
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

  void _forceFocus(int attempt) {
    if (attempt >= 10 || !mounted || !widget.autoFocus) return;

    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();

      // Try again after delay, but only if autoFocus is still true
      Future.delayed(Duration(milliseconds: 50 + (attempt * 25)), () {
        _forceFocus(attempt + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final backgroundColor = colors.surface;
    final backgroundColorSection = colors.surfaceVariant;

    if (isSection) {
      return Container(
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: _getBorderRadius(),
        ),
        child: Slidable(
          enabled: !widget.isDragging,
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: Icon(
                      Icons.delete,
                      color: colors.surface,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: ContextMenuWidget(
            contextMenuIsAllowed: _contextMenuIsAllowed,
            menuProvider: (_) {
              return Menu(
                children: [
                  MenuAction(
                    title: 'Convert to step',
                    image: MenuImage.icon(Icons.format_list_numbered),
                    callback: () {
                      // Convert the section to a step
                      widget.onUpdate(widget.step.copyWith(
                        type: 'step',
                        text: widget.step.text.isEmpty ? '' : widget.step.text,
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
                    color: backgroundColorSection,
                    border: _getBorder(),
                    borderRadius: _getBorderRadius(),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12), // Left padding
                      Expanded(
                        child: Focus(
                          focusNode: _focusNode,
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Section name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: TextStyle(fontWeight: FontWeight.w400, color: colors.textSecondary),
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
                      child: Icon(Icons.drag_handle, color: colors.textTertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: _getBorderRadius(),
      ),
      child: Slidable(
        enabled: !widget.isDragging,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(
                    Icons.delete,
                    color: colors.surface,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: ContextMenuWidget(
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
                  border: _getBorder(),
                  borderRadius: _getBorderRadius(),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12), // Add some left padding
                    Expanded(
                      child: TextField(
                        autofocus: widget.autoFocus,
                        focusNode: _focusNode,
                        controller: _textController,
                        scrollPadding: const EdgeInsets.only(bottom: 200.0), // Keep context visible above
                        decoration: const InputDecoration(
                          hintText: 'Describe this step',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          widget.onUpdate(widget.step.copyWith(text: value));
                        },
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          // Only add next step if this is the last step
                          final isLastStep = widget.index == widget.allSteps.length - 1;
                          if (isLastStep) {
                            widget.onAddNext();
                          }
                        },
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
                    child: Icon(Icons.drag_handle, color: colors.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
