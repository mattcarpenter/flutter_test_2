import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';

/// Shows a bottom sheet with a list of pantry items that can be selected
void showPantryItemSelectorBottomSheet({
  required BuildContext context,
  required Function(String itemName) onItemSelected,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: const Text('Select Pantry Item'),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          child: PantryItemSelectorContent(
            onItemSelected: (itemName) {
              onItemSelected(itemName);
              Navigator.of(modalContext).pop();
            },
          ),
        ),
      ];
    },
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}

class PantryItemSelectorContent extends ConsumerStatefulWidget {
  final Function(String itemName) onItemSelected;

  const PantryItemSelectorContent({
    Key? key,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  ConsumerState<PantryItemSelectorContent> createState() => _PantryItemSelectorContentState();
}

class _PantryItemSelectorContentState extends ConsumerState<PantryItemSelectorContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantryItemsAsync = ref.watch(pantryItemsProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search pantry items',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            // Pantry items list
            Expanded(
              child: pantryItemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (pantryItems) {
                  if (pantryItems.isEmpty) {
                    return const Center(
                      child: Text('No pantry items found. Add some in the Pantry tab.'),
                    );
                  }

                  // Filter the pantry items based on search query
                  final filteredItems = _searchQuery.isEmpty
                      ? pantryItems
                      : pantryItems.where((item) => 
                          item.name.toLowerCase().contains(_searchQuery)).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(
                      child: Text('No pantry items match your search.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.inStock ? 'In stock' : 'Out of stock'),
                        leading: Icon(
                          Icons.kitchen,
                          color: item.inStock ? Colors.green : Colors.red,
                        ),
                        onTap: () {
                          widget.onItemSelected(item.name);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}