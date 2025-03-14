import 'package:flutter/material.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../../../../database/models/ingredients.dart';
import '../utils/context_menu_utils.dart';

class IngredientListItem extends StatefulWidget {
  final int index;
  final Ingredient ingredient;
  final bool autoFocus;
  final VoidCallback onRemove;
  final Function(Ingredient) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const IngredientListItem({
    Key? key,
    required this.index,
    required this.ingredient,
    required this.autoFocus,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  _IngredientListItemState createState() => _IngredientListItemState();
}

class _IngredientListItemState extends State<IngredientListItem> {
  late TextEditingController _nameController;
  TextEditingController? _amountController;
  late FocusNode _focusNode;

  bool get isSection => widget.ingredient.type == 'section';

  final GlobalKey _dragHandleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    if (!isSection) {
      _amountController = TextEditingController(text: widget.ingredient.primaryAmount1Value ?? '');
    }
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus(_focusNode.hasFocus);
      setState(() {}); // update background color
    });
    if (widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant IngredientListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredient.name != widget.ingredient.name &&
        _nameController.text != widget.ingredient.name) {
      _nameController.text = widget.ingredient.name;
    }
    if (!isSection &&
        oldWidget.ingredient.primaryAmount1Value != widget.ingredient.primaryAmount1Value) {
      _amountController?.text = widget.ingredient.primaryAmount1Value ?? '';
    }

    // Handle autofocus change
    if (!oldWidget.autoFocus && widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController?.dispose();
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
              controller: _nameController,
              style: const TextStyle(fontWeight: FontWeight.bold),
              onChanged: (value) {
                widget.onUpdate(widget.ingredient.copyWith(name: value));
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
                // Convert the ingredient to a section
                widget.onUpdate(widget.ingredient.copyWith(
                  type: 'section',
                  name: widget.ingredient.name.isEmpty ? 'New Section' : widget.ingredient.name,
                  primaryAmount1Value: null,
                  primaryAmount1Unit: null,
                  primaryAmount1Type: null,
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
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: widget.onRemove,
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      hintText: 'Amt',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      widget.onUpdate(widget.ingredient.copyWith(primaryAmount1Value: value));
                    },
                  ),
                ),
                const Text('g', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Ingredient name',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        widget.onUpdate(widget.ingredient.copyWith(name: value));
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
