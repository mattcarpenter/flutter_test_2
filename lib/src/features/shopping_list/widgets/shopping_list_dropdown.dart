import 'package:flutter/cupertino.dart';
import '../../../../database/database.dart';

class ShoppingListDropdown extends StatelessWidget {
  final String? currentListId;
  final List<ShoppingListEntry> lists;
  final Function(String?) onListSelected;
  final VoidCallback onManageLists;

  const ShoppingListDropdown({
    super.key,
    required this.currentListId,
    required this.lists,
    required this.onListSelected,
    required this.onManageLists,
  });

  String get _currentListName {
    if (currentListId == null) {
      return 'My Shopping List'; // Default list name
    }
    
    final list = lists.where((l) => l.id == currentListId).firstOrNull;
    return list?.name ?? 'My Shopping List';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onManageLists,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.systemGrey4,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _currentListName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}