import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
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
              'Add Pantry Items',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            const AddPantryItemForm(),
            SizedBox(height: AppSpacing.sm),
          ],
        ),
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
  late final FocusNode _focusNode;
  final _textFieldKey = GlobalKey();
  PantryItemEntry? _lastAddedItem;
  bool _isLoading = false;
  bool _hasInput = false;

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

  void _handleSubmitFromKeyboard() {
    if (_isLoading) return;
    // Make sure we keep focus locked on the field
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _addItem();
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

      // Store the last added item and reset form state
      setState(() {
        _lastAddedItem = newItem;
        _isLoading = false;
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
              child: AppTextFieldSimple(
                key: _textFieldKey,
                controller: _nameController,
                focusNode: _focusNode,
                placeholder: 'Item name',
                autofocus: true,
                textInputAction: TextInputAction.send,
                onEditingComplete: () {}, // Prevent default focus traversal
                onSubmitted: (_) => _handleSubmitFromKeyboard(),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            AppButtonVariants.primaryFilled(
              text: 'Add',
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              onPressed: (_isLoading || !_hasInput) ? null : () {
                // Re-assert focus so keyboard stays up even after button tap
                if (!_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                }
                _addItem();
              },
            ),
          ],
        ),

        // Previously added item section
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name and undo button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _lastAddedItem!.name,
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
                SizedBox(height: AppSpacing.sm),
                // Stock status control
                Row(
                  children: [
                    Text(
                      'Status:',
                      style: AppTypography.body.copyWith(
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
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

        SizedBox(height: AppSpacing.lg),
        Text(
          'Items are added with "In Stock" status by default. You can change the status above or edit items later for more details.',
          style: AppTypography.caption.copyWith(
            color: AppColors.of(context).textTertiary,
          ),
        ),
      ],
    );
  }
}