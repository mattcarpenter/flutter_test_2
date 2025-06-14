import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../database/database.dart';

class ShoppingListItemTile extends StatelessWidget {
  final ShoppingListItemEntry item;
  final Function(bool) onBoughtToggle;
  final VoidCallback onDelete;

  const ShoppingListItemTile({
    super.key,
    required this.item,
    required this.onBoughtToggle,
    required this.onDelete,
  });

  String get _quantityText {
    final amount = item.amount;
    final unit = item.unit;
    
    if (amount == null) return '';
    
    String amountStr;
    if (amount == amount.floor()) {
      amountStr = amount.floor().toString();
    } else {
      amountStr = amount.toString();
    }
    
    if (unit != null && unit.isNotEmpty) {
      return '$amountStr $unit';
    } else {
      // Just show the quantity number
      return amountStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: CupertinoColors.destructiveRed,
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
          size: 20,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Delete Item'),
            content: Text('Are you sure you want to delete "${item.name}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: GestureDetector(
            onTap: () => onBoughtToggle(!item.bought),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.bought 
                    ? CupertinoColors.activeGreen 
                    : CupertinoColors.systemGrey3,
                  width: 2,
                ),
                color: item.bought 
                  ? CupertinoColors.activeGreen 
                  : CupertinoColors.systemBackground,
              ),
              child: item.bought
                ? const Icon(
                    CupertinoIcons.check_mark,
                    size: 16,
                    color: CupertinoColors.white,
                  )
                : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: item.bought ? TextDecoration.lineThrough : null,
              color: item.bought 
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.label,
            ),
          ),
          subtitle: _quantityText.isNotEmpty
            ? Text(
                _quantityText,
                style: TextStyle(
                  fontSize: 14,
                  color: item.bought 
                    ? CupertinoColors.tertiaryLabel
                    : CupertinoColors.secondaryLabel,
                ),
              )
            : null,
        ),
      ),
    );
  }
}