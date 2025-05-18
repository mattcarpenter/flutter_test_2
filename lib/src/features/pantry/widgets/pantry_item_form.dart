import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:disclosure/disclosure.dart';
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
  late final TextEditingController _termController;
  
  bool _inStock = true;
  bool _isQuantitySectionExpanded = false;
  bool _isCostSectionExpanded = false;
  bool _isTermsSectionExpanded = false;
  
  // Store the current terms (initialize as empty)
  List<PantryItemTerm> _terms = [];

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
    _termController = TextEditingController();
    
    _inStock = item?.inStock ?? true;
    
    // Initialize terms list if available for existing items
    if (item?.terms != null && item!.terms!.isNotEmpty) {
      _terms = List<PantryItemTerm>.from(item.terms!);
    }
    // For new items, leave terms list empty to allow canonicalization service to generate terms
    
    // Auto-expand sections if they have data
    _isQuantitySectionExpanded = _quantityController.text.isNotEmpty || _unitController.text.isNotEmpty;
    _isCostSectionExpanded = _priceController.text.isNotEmpty || _baseQuantityController.text.isNotEmpty || _baseUnitController.text.isNotEmpty;
    _isTermsSectionExpanded = _terms.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _baseUnitController.dispose();
    _baseQuantityController.dispose();
    _priceController.dispose();
    _termController.dispose();
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

    // For new items, we'll leave terms empty to allow canonicalization
    // For existing items, ensure the name is in the terms list
    if (widget.initialPantryItem != null) {
      bool hasNameTerm = _terms.any((term) => term.value.toLowerCase() == name.toLowerCase());
      if (!hasNameTerm) {
        // Add the name as a term if it doesn't exist yet
        _terms.add(PantryItemTerm(
          value: name,
          source: 'user',
          sort: _terms.length,
        ));
      }
      
      // Sort terms by their sort order
      _terms.sort((a, b) => a.sort.compareTo(b.sort));
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    try {
      if (widget.initialPantryItem == null) {
        // Create new pantry item - pass null for terms to trigger canonicalization
        await ref.read(pantryItemsProvider.notifier).addItem(
          name: name,
          inStock: _inStock,
          userId: userId,
          unit: unit,
          quantity: quantity,
          baseUnit: baseUnit,
          baseQuantity: baseQuantity,
          price: price,
          // Do NOT pass terms for new items to ensure canonicalization happens
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
          terms: _terms,
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
          const SizedBox(height: 16),
          _buildExpandableQuantitySection(),
          const SizedBox(height: 16),
          _buildExpandableCostSection(),
          const SizedBox(height: 16),
          _buildExpandableTermsSection(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Ingredient Name',
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
            const Text('I have this'),
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

  Widget _buildExpandableQuantitySection() {
    return Disclosure(
      closed: !_isQuantitySectionExpanded,
      onOpen: () => setState(() => _isQuantitySectionExpanded = true),
      onClose: () => setState(() => _isQuantitySectionExpanded = false),
      header: const DisclosureButton(
        child: ListTile(
          title: Text('+ Track quantity (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          trailing: DisclosureIcon(),
        ),
      ),
      child: DisclosureView(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
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
                placeholder: 'Unit (e.g., onion, g, ml)',
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
      ),
    );
  }

  Widget _buildExpandableCostSection() {
    return Disclosure(
      closed: !_isCostSectionExpanded,
      onOpen: () => setState(() => _isCostSectionExpanded = true),
      onClose: () => setState(() => _isCostSectionExpanded = false),
      header: const DisclosureButton(
        child: ListTile(
          title: Text('+ Track cost (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          trailing: DisclosureIcon(),
        ),
      ),
      child: DisclosureView(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price field
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
            const SizedBox(height: 16),
            // Per quantity and per unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CupertinoTextField(
                    controller: _baseQuantityController,
                    placeholder: 'Per Quantity',
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
                    placeholder: 'Per Unit (e.g., lb, g, pack)',
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
        ),
      ),
    );
  }
  
  Widget _buildExpandableTermsSection() {
    return Disclosure(
      closed: !_isTermsSectionExpanded,
      onOpen: () => setState(() => _isTermsSectionExpanded = true),
      onClose: () => setState(() => _isTermsSectionExpanded = false),
      header: const DisclosureButton(
        child: ListTile(
          title: Text('+ Add matching terms (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          trailing: DisclosureIcon(),
        ),
      ),
      child: DisclosureView(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terms heading
            Row(
              children: [
                const Text(
                  'Matching Terms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),

                // Add term button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAddTermDialog,
                  tooltip: 'Add New Term',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // No terms placeholder
            if (_terms.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No additional terms for this item. Add terms to improve recipe matching.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),

            // Terms list with reordering
            if (_terms.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }

                    final item = _terms.removeAt(oldIndex);
                    _terms.insert(newIndex, item);

                    // Update sort values
                    for (int i = 0; i < _terms.length; i++) {
                      _terms[i] = PantryItemTerm(
                        value: _terms[i].value,
                        source: _terms[i].source,
                        sort: i,
                      );
                    }
                  });
                },
                itemCount: _terms.length,
                itemBuilder: (context, index) {
                  final term = _terms[index];
                  return _buildTermItem(
                    key: ValueKey('term_${term.value}_$index'),
                    term: term,
                    index: index,
                  );
                },
              ),

            const SizedBox(height: 16),

            // Help text
            const Text(
              'Tip: Add terms that match recipe ingredients to improve matching.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem({
    required Key key,
    required PantryItemTerm term,
    required int index,
  }) {
    return Card(
      key: key,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(term.value),
        subtitle: Text('Source: ${term.source}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reorder handle
            const Icon(Icons.drag_handle),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _terms.removeAt(index);
                  
                  // Update sort values
                  for (int i = 0; i < _terms.length; i++) {
                    _terms[i] = PantryItemTerm(
                      value: _terms[i].value,
                      source: _terms[i].source,
                      sort: i,
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTermDialog() {
    _termController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Matching Term'),
        content: TextField(
          controller: _termController,
          decoration: const InputDecoration(
            labelText: 'Term',
            hintText: 'Enter a matching term',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _addNewTerm(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addNewTerm,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewTerm() {
    final value = _termController.text.trim();
    if (value.isNotEmpty) {
      // Check if term already exists
      if (!_terms.any((term) => term.value.toLowerCase() == value.toLowerCase())) {
        setState(() {
          _terms.add(PantryItemTerm(
            value: value,
            source: 'user',
            sort: _terms.length,
          ));
        });
      }
      Navigator.of(context).pop();
    }
  }
}