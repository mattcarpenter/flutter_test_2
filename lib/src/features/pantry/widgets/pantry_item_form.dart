import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_item_terms.dart';
import '../../../providers/pantry_provider.dart';
class PantryItemForm extends ConsumerStatefulWidget {
  final PantryItemEntry? initialPantryItem;

  const PantryItemForm({
    Key? key,
    this.initialPantryItem,
  }) : super(key: key);

  @override
  ConsumerState<PantryItemForm> createState() => PantryItemFormState();
}

class PantryItemFormState extends ConsumerState<PantryItemForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _baseUnitController;
  late final TextEditingController _baseQuantityController;
  late final TextEditingController _priceController;
  
  bool _inStock = true;

  @override
  void initState() {
    super.initState();
    
    final item = widget.initialPantryItem;
    
    _nameController = TextEditingController(text: item?.name ?? '');
    _unitController = TextEditingController(text: item?.unit ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity != null ? item!.quantity.toString() : '',
    );
    _baseUnitController = TextEditingController(text: item?.baseUnit ?? '');
    _baseQuantityController = TextEditingController(
      text: item?.baseQuantity != null ? item!.baseQuantity.toString() : '',
    );
    _priceController = TextEditingController(
      text: item?.price != null ? item!.price.toString() : '',
    );
    
    _inStock = item?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _baseUnitController.dispose();
    _baseQuantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> savePantryItem() async {
    // Validate required field
    if (_nameController.text.isEmpty) {
      // Show error
      return;
    }

    final name = _nameController.text.trim();
    final unit = _unitController.text.isEmpty ? null : _unitController.text.trim();
    final quantity = _quantityController.text.isEmpty 
        ? null 
        : double.tryParse(_quantityController.text);
    final baseUnit = _baseUnitController.text.isEmpty 
        ? null 
        : _baseUnitController.text.trim();
    final baseQuantity = _baseQuantityController.text.isEmpty 
        ? null 
        : double.tryParse(_baseQuantityController.text);
    final price = _priceController.text.isEmpty 
        ? null 
        : double.tryParse(_priceController.text);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    try {
      if (widget.initialPantryItem == null) {
        // Create new pantry item
        await ref.read(pantryItemsProvider.notifier).addItem(
          name: name,
          inStock: _inStock,
          userId: userId,
          unit: unit,
          quantity: quantity,
          baseUnit: baseUnit,
          baseQuantity: baseQuantity,
          price: price,
        );
      } else {
        // Update existing pantry item
        await ref.read(pantryItemsProvider.notifier).updateItem(
          id: widget.initialPantryItem!.id,
          name: name,
          inStock: _inStock,
          unit: unit,
          quantity: quantity,
          baseUnit: baseUnit,
          baseQuantity: baseQuantity,
          price: price,
        );
      }
    } catch (e) {
      debugPrint('Error saving pantry item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildQuantitySection(),
          const SizedBox(height: 24),
          _buildPricingSection(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Item Name',
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        // In stock toggle
        Row(
          children: [
            const Text('In Stock'),
            const Spacer(),
            CupertinoSwitch(
              value: _inStock,
              onChanged: (value) {
                setState(() {
                  _inStock = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CupertinoTextField(
                controller: _quantityController,
                placeholder: 'Quantity',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: CupertinoTextField(
                controller: _unitController,
                placeholder: 'Unit (e.g., pack, can)',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CupertinoTextField(
                controller: _baseQuantityController,
                placeholder: 'Base Quantity',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: CupertinoTextField(
                controller: _baseUnitController,
                placeholder: 'Base Unit (e.g., g, ml)',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _priceController,
          placeholder: 'Price',
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text('\$'),
          ),
        ),
      ],
    );
  }
}