import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/stock_status_segmented_control.dart';

void showAddPantryItemModal(BuildContext context) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddPantryItemModalPage.build(
        context: bottomSheetContext,
      ),
    ],
  );
}

class AddPantryItemModalPage {
  AddPantryItemModalPage._();

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
        child: const Text('Close'),
      ),
      pageTitle: const ModalSheetTitle('Add Pantry Items'),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: AddPantryItemForm(),
      ),
    );
  }
}

class AddPantryItemForm extends ConsumerStatefulWidget {
  const AddPantryItemForm({super.key});

  @override
  ConsumerState<AddPantryItemForm> createState() => _AddPantryItemFormState();
}

class _AddPantryItemFormState extends ConsumerState<AddPantryItemForm> {
  late final TextEditingController _nameController;
  PantryItemEntry? _lastAddedItem;
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
      
      final itemId = await ref.read(pantryNotifierProvider.notifier).addItem(
        name: name,
        stockStatus: StockStatus.inStock,
        isStaple: false,
        userId: userId,
      );

      // Get the newly added item by ID
      final pantryItemsAsyncValue = ref.read(pantryNotifierProvider);
      final newItem = pantryItemsAsyncValue.when(
        data: (items) => items.where((item) => item.id == itemId).firstOrNull,
        loading: () => null,
        error: (_, __) => null,
      );
      
      setState(() {
        _lastAddedItem = newItem;
        _isLoading = false;
      });

      _nameController.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error adding pantry item: $e');
    }
  }

  Future<void> _undoLastItem() async {
    if (_lastAddedItem == null) return;

    try {
      await ref.read(pantryNotifierProvider.notifier).deleteItem(_lastAddedItem!.id);
      setState(() {
        _lastAddedItem = null;
      });
    } catch (e) {
      debugPrint('Error deleting last item: $e');
    }
  }

  Future<void> _updateLastItemStatus(StockStatus status) async {
    if (_lastAddedItem == null) return;

    try {
      await ref.read(pantryNotifierProvider.notifier).updateItem(
        id: _lastAddedItem!.id,
        stockStatus: status,
      );

      setState(() {
        _lastAddedItem = _lastAddedItem!.copyWith(stockStatus: status);
      });
    } catch (e) {
      debugPrint('Error updating last item status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input section
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _nameController,
                placeholder: 'Enter item name',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addItem(),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(width: 12),
            CupertinoButton(
              onPressed: _isLoading ? null : _addItem,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(8),
              child: _isLoading 
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),

        // Recently added item section
        if (_lastAddedItem != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Recently Added',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name and undo button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _lastAddedItem!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: _undoLastItem,
                      padding: const EdgeInsets.all(4),
                      minSize: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.delete,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Undo',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stock status control
                Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    StockStatusSegmentedControl(
                      value: _lastAddedItem!.stockStatus,
                      onChanged: _updateLastItemStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        const Text(
          'Items are added with "In Stock" status by default. You can change the status above or edit items later for more details.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}