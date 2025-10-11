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
  int _quantity = 1;
  bool _isLoading = false;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hasInput = _nameController.text.trim().isNotEmpty;
    _nameController.addListener(_updateHasInput);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateHasInput);
    _nameController.dispose();
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
        AppTextFieldSimple(
          controller: _nameController,
          placeholder: 'Item name',
          autofocus: true,
          enabled: !_isLoading,
          onSubmitted: (_) => _addItem(),
          textInputAction: TextInputAction.done,
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

        SizedBox(height: AppSpacing.xl),

        // Add button
        AppButtonVariants.primaryFilled(
          text: 'Add Item',
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          onPressed: (_isLoading || !_hasInput) ? null : _addItem,
          loading: _isLoading,
          fullWidth: true,
        ),
      ],
    );
  }
}