import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/quantity_control.dart';

void showAddShoppingListItemModal(BuildContext context, String? listId) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddShoppingListItemModalPage.build(
        context: bottomSheetContext,
        listId: listId,
      ),
    ],
  );
}

class AddShoppingListItemModalPage {
  AddShoppingListItemModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required String? listId,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
      pageTitle: const ModalSheetTitle('Add Shopping List Item'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: AddShoppingListItemForm(listId: listId),
      ),
    );
  }
}

class AddShoppingListItemForm extends ConsumerStatefulWidget {
  final String? listId;

  const AddShoppingListItemForm({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<AddShoppingListItemForm> createState() => _AddShoppingListItemFormState();
}

class _AddShoppingListItemFormState extends ConsumerState<AddShoppingListItemForm> {
  late final TextEditingController _nameController;
  int _quantity = 1;
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

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await ref.read(shoppingListItemsProvider(widget.listId).notifier).addItem(
        name: name,
        userId: userId,
        amount: _quantity.toDouble(),
        unit: null, // No unit as requested
      );

      // Clear form
      _nameController.clear();
      setState(() {
        _quantity = 1; // Reset quantity to default
        _isLoading = false;
      });

      // Close modal
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error adding shopping list item: $e');
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to add item: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Item name field
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Item name',
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enabled: !_isLoading,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          onSubmitted: (_) => _addItem(),
        ),
        
        const SizedBox(height: 16),
        
        // Quantity control
        Row(
          children: [
            const Text(
              'Quantity:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(width: 16),
            QuantityControl(
              value: _quantity,
              onChanged: _isLoading ? (_) {} : (value) {
                setState(() {
                  _quantity = value;
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Add button
        CupertinoButton.filled(
          onPressed: _isLoading ? null : _addItem,
          child: _isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : const Text('Add Item'),
        ),
      ],
    );
  }
}