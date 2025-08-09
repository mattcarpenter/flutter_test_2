import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/pantry_items.dart'; // For StockStatus enum
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/theme/colors.dart';

/// Shows a bottom sheet with a list of pantry items that can be selected
void showPantryItemSelectorBottomSheet({
  required BuildContext context,
  required Function(String itemName) onItemSelected,
  String? recipeId, // Optional recipe ID to invalidate ingredient matches
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          backgroundColor: AppColors.of(modalContext).background,
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
              // Do the callback first
              onItemSelected(itemName);
              
              // Close the modal
              Navigator.of(modalContext).pop();
              
              // If a recipe ID was provided, invalidate the ingredient matches
              // Use a post-frame callback to ensure the modal is fully closed
              if (recipeId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    // Use the modal context to access providers
                    final container = ProviderScope.containerOf(modalContext);
                    
                    // Invalidate and refresh immediately
                    container.invalidate(recipeIngredientMatchesProvider(recipeId));
                    
                    // Also invalidate other providers that might be watching this
                    container.invalidate(pantryItemsProvider);
                    
                    // Force an immediate refresh
                    container.read(recipeIngredientMatchesProvider(recipeId).future);
                  } catch (e) {
                    // If the context is no longer valid, just ignore
                    debugPrint('Failed to invalidate providers after pantry selection: $e');
                  }
                });
              }
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
  
  // Helper method to get color based on stock status
  Color _getStockStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return Colors.red;
      case StockStatus.lowStock:
        return Colors.yellow.shade700; // Darker yellow for better visibility
      case StockStatus.inStock:
        return Colors.green;
      default:
        return Colors.grey; // Fallback
    }
  }
  
  // Helper method to get text for stock status
  String _getStockStatusText(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of stock';
      case StockStatus.lowStock:
        return 'Low stock';
      case StockStatus.inStock:
        return 'In stock';
      default:
        return 'Unknown';
    }
  }

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
                        subtitle: Text(_getStockStatusText(item.stockStatus)),
                        leading: Icon(
                          Icons.kitchen,
                          color: _getStockStatusColor(item.stockStatus),
                        ),
                        onTap: () {
                          // Just call the callback - navigation is handled in the callback
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