import 'package:flutter/material.dart' hide Step;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:super_context_menu/super_context_menu.dart';

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
  bool get _isGrouped => widget.enableGrouping && !isSection;
  
  bool get _isFirstInGroup {
    if (!_isGrouped) return false;
    
    // Use visual index during drag operations if available
    final effectiveIndex = widget.visualIndex ?? widget.index;
    final prevIndex = effectiveIndex - 1;
    
    if (effectiveIndex == 0) return true;
    if (prevIndex < 0 || prevIndex >= widget.allSteps.length) return true;
    
    return widget.allSteps[prevIndex].type == 'section';
  }
  
  bool get _isLastInGroup {
    if (!_isGrouped) return false;
    
    // Use visual index during drag operations if available
    final effectiveIndex = widget.visualIndex ?? widget.index;
    
    // During drag operations, visual array length is reduced by 1 (dragged item)
    if (widget.visualIndex != null) {
      final visualArrayLength = widget.allSteps.length - 1;
      return effectiveIndex == visualArrayLength - 1;
    }
    
    // Normal (non-drag) logic
    final nextIndex = effectiveIndex + 1;
    if (effectiveIndex == widget.allSteps.length - 1) return true;
    if (nextIndex >= widget.allSteps.length) return true;
    
    return widget.allSteps[nextIndex].type == 'section';
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
    const borderColor = Colors.grey;
    const borderWidth = 1.0;
    
    if (!_isGrouped || widget.isDragging) {
      // During drag, use full border to prevent animation glitches
      return Border.all(color: borderColor.shade300, width: borderWidth);
    }
    
    if (_isFirstInGroup && _isLastInGroup) {
      // Single item gets full border
      return Border.all(color: borderColor.shade300, width: borderWidth);
    } else if (_isFirstInGroup) {
      // First item: full border
      return Border.all(color: borderColor.shade300, width: borderWidth);
    } else {
      // Non-first items: omit top border to prevent double borders
      return Border(
        left: BorderSide(color: borderColor.shade300, width: borderWidth),
        right: BorderSide(color: borderColor.shade300, width: borderWidth),
        bottom: BorderSide(color: borderColor.shade300, width: borderWidth),
      );
    }
  }
  
  // Build inset divider widget for grouped steps
  Widget? _buildInsetDivider() {
    if (!_isGrouped || _isLastInGroup || widget.isDragging) {
      // Hide inset divider during drag to prevent visual conflicts
      return null;
    }
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 1,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 1,
              color: Colors.white,
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
            Container(
              width: 16,
              height: 1,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.step.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      print('👁️ STEP ${widget.step.id}: Focus node listener - hasFocus=${_focusNode.hasFocus}');
      widget.onFocus(_focusNode.hasFocus);
      setState(() {});
    });
    print('🎯 STEP ${widget.step.id}: initState - autoFocus=${widget.autoFocus}');
    
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
      print('🎯 STEP ${widget.step.id}: didUpdateWidget - autoFocus changed from false to true');
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
    if (attempt >= 10 || !mounted) return;
    
    print('🎯 STEP ${widget.step.id}: _forceFocus attempt $attempt - hasFocus=${_focusNode.hasFocus}');
    
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      
      // Try again after delay
      Future.delayed(Duration(milliseconds: 50 + (attempt * 25)), () {
        _forceFocus(attempt + 1);
      });
    } else {
      print('🎯 STEP ${widget.step.id}: Focus successful on attempt $attempt!');
    }
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
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
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
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
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
              ),
              // Add inset divider for grouped steps
              if (_buildInsetDivider() != null) _buildInsetDivider()!,
            ],
          ),
        ),
      ),
    );
  }
}
