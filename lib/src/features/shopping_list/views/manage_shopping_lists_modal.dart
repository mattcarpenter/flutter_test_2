import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

void showManageShoppingListsModal(BuildContext context) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      ManageShoppingListsModalPage.build(
        context: bottomSheetContext,
      ),
    ],
  );
}

class ManageShoppingListsModalPage {
  ManageShoppingListsModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Done'),
      ),
      trailingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          _showAddListModal(context);
        },
        child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
      ),
      pageTitle: const ModalSheetTitle('Manage Shopping Lists'),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: ManageShoppingListsContent(),
      ),
    );
  }

  static void _showAddListModal(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => const AddShoppingListDialog(),
    );
  }
}

class ManageShoppingListsContent extends ConsumerWidget {
  const ManageShoppingListsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsyncValue = ref.watch(shoppingListsProvider);
    final currentListId = ref.watch(currentShoppingListProvider);

    return listsAsyncValue.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (lists) {
        // Create a list with the default "My Shopping List" at the top
        final allLists = <_ListItem>[
          _ListItem(
            id: null,
            name: 'My Shopping List',
            isDefault: true,
            isSelected: currentListId == null,
          ),
          ...lists.map((list) => _ListItem(
            id: list.id,
            name: list.name ?? 'Unnamed List',
            isDefault: false,
            isSelected: currentListId == list.id,
          )),
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allLists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No shopping lists yet'),
              )
            else
              ...allLists.map((listItem) => _ListTile(
                listItem: listItem,
                onTap: () {
                  ref.read(currentShoppingListProvider.notifier).setCurrentList(listItem.id);
                  Navigator.of(context).pop();
                },
                onDelete: listItem.isDefault ? null : () async {
                  await ref.read(shoppingListsProvider.notifier).deleteList(listItem.id!);
                },
              )),
          ],
        );
      },
    );
  }
}

class _ListItem {
  final String? id;
  final String name;
  final bool isDefault;
  final bool isSelected;

  _ListItem({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.isSelected,
  });
}

class _ListTile extends StatelessWidget {
  final _ListItem listItem;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ListTile({
    required this.listItem,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          listItem.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: listItem.isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: listItem.isSelected
          ? const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              color: CupertinoColors.activeBlue,
              size: 20,
            )
          : null,
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(listItem.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: CupertinoColors.destructiveRed,
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedDelete02,
            color: CupertinoColors.white,
            size: 20,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Delete List'),
              content: Text('Are you sure you want to delete "${listItem.name}"? All items in this list will also be deleted.'),
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
        onDismissed: (_) => onDelete!(),
        child: tile,
      );
    }

    return tile;
  }
}

class AddShoppingListDialog extends ConsumerStatefulWidget {
  const AddShoppingListDialog({super.key});

  @override
  ConsumerState<AddShoppingListDialog> createState() => _AddShoppingListDialogState();
}

class _AddShoppingListDialogState extends ConsumerState<AddShoppingListDialog> {
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      await ref.read(shoppingListsProvider.notifier).createList(
        name: name,
        userId: userId,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Failed to create shopping list', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('New Shopping List'),
      content: Column(
        children: [
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'List name',
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enabled: !_isLoading,
            onSubmitted: (_) => _createList(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          onPressed: _isLoading ? null : _createList,
          child: _isLoading
            ? const CupertinoActivityIndicator()
            : const Text('Create'),
        ),
      ],
    );
  }
}