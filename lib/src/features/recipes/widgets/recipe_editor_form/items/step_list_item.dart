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

class _StepListItemState extends State<StepListItem> with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  bool get isSection => widget.step.type == 'section';

  final GlobalKey _dragHandleKey = GlobalKey();
  final GlobalKey _sizeKey = GlobalKey();
  double _previousHeight = 0.0;

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
      return effectiveIndex == visualArrayLength - 1;
    } else {
      // Normal (non-drag) logic - check if this is the last item
      return effectiveIndex == widget.allSteps.length - 1;
    }
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
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    _animationController.addListener(_handleAnimation);
    
    _textController = TextEditingController(text: widget.step.text);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus(_focusNode.hasFocus);
      setState(() {});
    });

    // Handle new vs existing items
    if (widget.autoFocus) {
      // New item - start collapsed and animate in
      _animationController.forward();
      
      // Focus immediately while animating for fluid feel
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    } else {
      // Existing item - start fully expanded
      _animationController.value = 1.0;
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
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_handleAnimation);
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _contextMenuIsAllowed(Offset location) {
    return isLocationOutsideKey(location, _dragHandleKey);
  }

  void _handleAnimation() {
    if (!widget.autoFocus) return;
    if (widget.index != widget.allSteps.length - 1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _sizeKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      final currentHeight = renderBox.size.height;
      final delta = currentHeight - _previousHeight;
      if (delta > 0) {
        final position = Scrollable.of(context)?.position;
        if (position != null) {
          final newOffset = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
          if (newOffset != position.pixels) {
            position.jumpTo(newOffset);
          }
        }
      }
      _previousHeight = currentHeight;
    });
  }


  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final backgroundColor = colors.surface;
    final backgroundColorSection = colors.surfaceVariant;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ClipRect(
          key: _sizeKey,
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: _buildContent(colors, backgroundColor, backgroundColorSection),
    );
  }

  Widget _buildContent(AppColors colors, Color backgroundColor, Color backgroundColorSection) {
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
                            // Prevent unwanted focus traversal - keep focus here temporarily
                            _focusNode.requestFocus();
                            widget.onAddNext(); // Add new step (which will get focus)
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
