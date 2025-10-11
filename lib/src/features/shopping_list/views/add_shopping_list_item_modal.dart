import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
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
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Shopping List Item',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            AddShoppingListItemForm(listId: listId),
            SizedBox(height: AppSpacing.sm),
          ],
        ),
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
  late final FocusNode _focusNode;
  int _quantity = 1;
  bool _isLoading = false;
  bool _hasInput = false;
  Map<String, dynamic>? _lastAddedItem;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _focusNode = FocusNode();
    _hasInput = _nameController.text.trim().isNotEmpty;
    _nameController.addListener(_updateHasInput);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateHasInput);
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateHasInput() {
    final hasInput = _nameController.text.trim().isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() {
        _hasInput = hasInput;
      });
    }
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final currentQuantity = _quantity;

      final itemId = await ref.read(shoppingListItemsProvider(widget.listId).notifier).addItem(
        name: name,
        userId: userId,
        amount: currentQuantity.toDouble(),
        unit: null, // No unit as requested
      );

      // Store the last added item and reset form state
      setState(() {
        _lastAddedItem = {
          'id': itemId,
          'name': name,
          'amount': currentQuantity,
        };
        _isLoading = false;
        _quantity = 1; // Reset quantity to default
      });

      // Clear form
      _nameController.clear();

      // Request focus after the frame is complete to ensure widget is rebuilt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
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

  Future<void> _undoLastItem() async {
    if (_lastAddedItem == null) return;

    try {
      await ref.read(shoppingListItemsProvider(widget.listId).notifier).deleteItem(_lastAddedItem!['id']);
      setState(() {
        _lastAddedItem = null;
      });
    } catch (e) {
      debugPrint('Error deleting last item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Item name field and Add button in same row
        Row(
          children: [
            Expanded(
              child: AppTextFieldSimple(
                controller: _nameController,
                focusNode: _focusNode,
                placeholder: 'Item name',
                autofocus: true,
                enabled: !_isLoading,
                onSubmitted: (_) => _addItem(),
                textInputAction: TextInputAction.done,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            AppButtonVariants.primaryFilled(
              text: 'Add',
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              onPressed: (_isLoading || !_hasInput) ? null : _addItem,
            ),
          ],
        ),

        SizedBox(height: AppSpacing.lg),

        // Quantity control
        Row(
          children: [
            Text(
              'Quantity:',
              style: AppTypography.body.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(width: AppSpacing.lg),
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

        // Previously added section
        if (_lastAddedItem != null) ...[
          SizedBox(height: AppSpacing.xl),
          Text(
            'Previously Added',
            style: AppTypography.h5.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_lastAddedItem!['name']} - Quantity: ${_lastAddedItem!['amount']}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
                CupertinoButton(
                  onPressed: _undoLastItem,
                  padding: EdgeInsets.all(4),
                  minSize: 0,
                  child: Text(
                    'Undo',
                    style: TextStyle(
                      color: AppColors.of(context).error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}