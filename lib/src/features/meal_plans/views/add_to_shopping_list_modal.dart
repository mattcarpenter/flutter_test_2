import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../providers/meal_plan_shopping_list_provider.dart';
import '../models/aggregated_ingredient.dart';

void showAddToShoppingListModal(BuildContext context, String date) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      AddToShoppingListModalPage.build(
        context: modalContext,
        date: date,
      ),
    ],
  );
}

class AddToShoppingListModalPage {
  AddToShoppingListModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
      pageTitle: const ModalSheetTitle('Add to Shopping List'),
      child: AddToShoppingListContent(date: date),
    );
  }
}

class AddToShoppingListContent extends ConsumerStatefulWidget {
  final String date;

  const AddToShoppingListContent({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<AddToShoppingListContent> createState() => _AddToShoppingListContentState();
}

class _AddToShoppingListContentState extends ConsumerState<AddToShoppingListContent> {
  String? selectedListId;
  Map<String, bool> checkedState = {};
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final aggregatedIngredientsAsync = ref.watch(aggregatedIngredientsProvider(widget.date));
    final shoppingLists = ref.watch(shoppingListsProvider);

    return aggregatedIngredientsAsync.when(
      data: (aggregatedIngredients) {
        // Initialize checked state for new ingredients
        for (final ingredient in aggregatedIngredients) {
          checkedState.putIfAbsent(ingredient.id, () => ingredient.isChecked);
        }
        
        // Remove checked state for ingredients no longer in list
        checkedState.removeWhere((id, _) => 
          !aggregatedIngredients.any((i) => i.id == id));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shopping list selector
            _buildShoppingListSelector(context, shoppingLists),
            
            const SizedBox(height: 16),
            
            // Content
            if (aggregatedIngredients.isEmpty)
              _buildEmptyState(context)
            else
              _buildIngredientList(context, aggregatedIngredients),
            
            // Action button
            if (aggregatedIngredients.isNotEmpty && checkedState.values.any((checked) => checked))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: isLoading ? null : () => _addToShoppingList(aggregatedIngredients),
                    child: Text(isLoading ? 'Adding...' : 'Add to Shopping List'),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error loading ingredients: $error',
          style: TextStyle(
            color: CupertinoColors.destructiveRed.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListSelector(BuildContext context, AsyncValue<List<ShoppingListEntry>> shoppingListsAsync) {
    final currentListId = ref.watch(currentShoppingListProvider);
    final shoppingLists = shoppingListsAsync.valueOrNull ?? [];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('Add to:'),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showListPicker(context, shoppingLists),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _getListName(currentListId, shoppingLists),
                      style: TextStyle(
                        color: CupertinoColors.activeBlue.resolveFrom(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 64,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No ingredients to add',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All ingredients are either in your pantry with sufficient stock or already on a shopping list.',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList(BuildContext context, List<AggregatedIngredient> ingredients) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final isChecked = checkedState[ingredient.id] ?? ingredient.isChecked;
          
          return _IngredientTile(
            ingredient: ingredient,
            isChecked: isChecked,
            onChanged: (value) {
              setState(() {
                checkedState[ingredient.id] = value;
              });
            },
          );
        },
      ),
    );
  }

  void _showListPicker(BuildContext context, List<ShoppingListEntry> shoppingLists) {
    final currentListId = ref.read(currentShoppingListProvider);
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Shopping List'),
        actions: [
          // Default list option
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(currentShoppingListProvider.notifier).setCurrentList(null);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentListId == null) ...[
                  const Icon(CupertinoIcons.checkmark_alt, size: 20),
                  const SizedBox(width: 8),
                ],
                const Text('My Shopping List'),
              ],
            ),
          ),
          // Other lists
          ...shoppingLists.map((list) => CupertinoActionSheetAction(
            onPressed: () {
              ref.read(currentShoppingListProvider.notifier).setCurrentList(list.id);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentListId == list.id) ...[
                  const Icon(CupertinoIcons.checkmark_alt, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(list.name ?? 'Unnamed List'),
              ],
            ),
          )),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _getListName(String? listId, List<ShoppingListEntry> shoppingLists) {
    if (listId == null) return 'My Shopping List';
    try {
      final list = shoppingLists.firstWhere((l) => l.id == listId);
      return list.name ?? 'My Shopping List';
    } catch (e) {
      return 'My Shopping List';
    }
  }

  Future<void> _addToShoppingList(List<AggregatedIngredient> ingredients) async {
    setState(() {
      isLoading = true;
    });

    try {
      final shoppingListRepository = ref.read(shoppingListRepositoryProvider);
      final currentListId = ref.read(currentShoppingListProvider);
      
      // Add checked ingredients to shopping list
      for (final ingredient in ingredients) {
        if (checkedState[ingredient.id] ?? false) {
          await shoppingListRepository.addItem(
            shoppingListId: currentListId,
            name: ingredient.name,
            terms: ingredient.terms,
            category: ingredient.matchingPantryItem?.category,
            userId: null, // TODO: Pass actual user ID
            householdId: null, // TODO: Pass actual household ID
          );
        }
      }
      
      // Show success and close modal
      if (mounted) {
        Navigator.of(context).pop();
        // TODO: Show success toast/snackbar
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // TODO: Show error message
      }
    }
  }
}

class _IngredientTile extends StatelessWidget {
  final AggregatedIngredient ingredient;
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const _IngredientTile({
    required this.ingredient,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(!isChecked),
            child: Icon(
              isChecked
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: isChecked
                  ? CupertinoColors.activeBlue.resolveFrom(context)
                  : CupertinoColors.tertiaryLabel.resolveFrom(context),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Pantry status indicator
          _buildStockIndicator(context, ingredient.matchingPantryItem),
          
          const SizedBox(width: 8),
          
          // Ingredient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 16,
                    decoration: isChecked ? null : TextDecoration.lineThrough,
                    color: isChecked 
                        ? CupertinoColors.label.resolveFrom(context)
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From ${ingredient.sourcesDisplay}',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 12,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(BuildContext context, dynamic pantryItem) {
    if (pantryItem == null) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: CupertinoColors.separator.resolveFrom(context),
          shape: BoxShape.circle,
        ),
      );
    }

    final Color color;
    switch (pantryItem.stockStatus) {
      case StockStatus.inStock:
        color = CupertinoColors.systemGreen.resolveFrom(context);
        break;
      case StockStatus.lowStock:
        color = CupertinoColors.systemYellow.resolveFrom(context);
        break;
      case StockStatus.outOfStock:
        color = CupertinoColors.destructiveRed.resolveFrom(context);
        break;
      default:
        color = CupertinoColors.separator.resolveFrom(context);
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}