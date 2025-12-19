import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../repositories/pantry_repository.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/stock_chip.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../shopping_list/widgets/shopping_lists_content.dart';
import '../../shopping_list/widgets/create_list_content.dart';
import '../models/extracted_shopping_item.dart';

/// Wrapper class that adds pantry and shopping list context to extracted items
class _EnrichedShoppingItem {
  final String id;
  final ExtractedShoppingItem item;
  final PantryItemEntry? matchingPantryItem;
  final bool existsInShoppingList;

  _EnrichedShoppingItem({
    required this.id,
    required this.item,
    this.matchingPantryItem,
    this.existsInShoppingList = false,
  });

  String get name => item.name;
  List<String> get terms => item.terms;
  String get category => item.category;
}

/// Provider that enriches extracted shopping items with pantry/shopping list context
final _enrichedClippingItemsProvider = FutureProvider.autoDispose
    .family<List<_EnrichedShoppingItem>, List<ExtractedShoppingItem>>(
  (ref, items) async {
    final pantryRepository = ref.read(pantryRepositoryProvider);
    final shoppingListRepository = ref.read(shoppingListRepositoryProvider);

    final enrichedItems = <_EnrichedShoppingItem>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // Check pantry for matching items using terms
      final pantryMatches = await pantryRepository.findItemsByTerms(item.terms);
      final matchingPantryItem =
          pantryMatches.isNotEmpty ? pantryMatches.first : null;

      // Check shopping lists for existing items
      final shoppingListMatches =
          await shoppingListRepository.findItemsByTerms(item.terms);
      final existsInShoppingList = shoppingListMatches.isNotEmpty;

      enrichedItems.add(_EnrichedShoppingItem(
        id: '${item.name}_$i',
        item: item,
        matchingPantryItem: matchingPantryItem,
        existsInShoppingList: existsInShoppingList,
      ));
    }

    return enrichedItems;
  },
);

// Global controller instance
final _clippingShoppingListController = _ClippingShoppingListController();

/// Shows the shopping list modal with extracted items
void showClippingShoppingListModal(
  BuildContext context,
  List<ExtractedShoppingItem> items,
) {
  // Reset controller state when opening modal
  _clippingShoppingListController.reset();

  final pageIndexNotifier = ValueNotifier<int>(0);

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageIndexNotifier: pageIndexNotifier,
    //modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) => [
      // Page 0: Add to Shopping List
      _buildAddToShoppingListPage(
        modalContext: modalContext,
        items: items,
        pageIndexNotifier: pageIndexNotifier,
      ),
      // Page 1: Manage Lists
      _buildManageListsPage(
        modalContext: modalContext,
        pageIndexNotifier: pageIndexNotifier,
      ),
      // Page 2: Create New List
      _buildCreateListPage(
        modalContext: modalContext,
        pageIndexNotifier: pageIndexNotifier,
      ),
    ],
  );
}

// ============================================================================
// Page 0: Add to Shopping List
// ============================================================================

SliverWoltModalSheetPage _buildAddToShoppingListPage({
  required BuildContext modalContext,
  required List<ExtractedShoppingItem> items,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return SliverWoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    hasSabGradient: true,
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
    ),
    stickyActionBar: Consumer(
      builder: (consumerContext, ref, child) {
        return Container(
          color: AppColors.of(modalContext).background,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: ListenableBuilder(
              listenable: _clippingShoppingListController,
              builder: (buttonContext, child) {
                return AppButtonVariants.primaryFilled(
                  text: _clippingShoppingListController.isLoading
                      ? 'Adding...'
                      : 'Add to Shopping List',
                  size: AppButtonSize.large,
                  shape: AppButtonShape.square,
                  fullWidth: true,
                  onPressed: _clippingShoppingListController.isButtonEnabled
                      ? () async {
                          await _clippingShoppingListController.addToShoppingList(
                            Navigator.of(consumerContext),
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        );
      },
    ),
    mainContentSliversBuilder: (builderContext) => [
      Consumer(
        builder: (consumerContext, ref, child) {
          return _ClippingShoppingListContent(
            items: items,
            pageIndexNotifier: pageIndexNotifier,
            controller: _clippingShoppingListController,
          );
        },
      ),
    ],
  );
}

// ============================================================================
// Page 1: Manage Lists
// ============================================================================

WoltModalSheetPage _buildManageListsPage({
  required BuildContext modalContext,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return WoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    leadingNavBarWidget: Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.back,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () {
          pageIndexNotifier.value = 0;
        },
      ),
    ),
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Manage Lists',
            style: AppTypography.h4.copyWith(
              color: AppColors.of(modalContext).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          ShoppingListsContent(
            showSelection: false,
            showCreateButton: true,
            allowDelete: true,
            onCreateList: () {
              pageIndexNotifier.value = 2;
            },
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// Page 2: Create New List
// ============================================================================

WoltModalSheetPage _buildCreateListPage({
  required BuildContext modalContext,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return WoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    leadingNavBarWidget: Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.back,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () {
          pageIndexNotifier.value = 1;
        },
      ),
    ),
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create New List',
            style: AppTypography.h4.copyWith(
              color: AppColors.of(modalContext).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          CreateListContent(
            onCreated: () {
              pageIndexNotifier.value = 1;
            },
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// Controller
// ============================================================================

class _ClippingShoppingListController extends ChangeNotifier {
  // Track checked state per item
  final Map<String, bool> checkedState = {};

  // Track selected list per item (list ID, null = default)
  final Map<String, String?> selectedListIds = {};

  // Addable items (not already in a list)
  List<_EnrichedShoppingItem> addableItems = [];

  // Reference to WidgetRef for adding items (set by the content widget)
  WidgetRef? _ref;

  bool isLoading = false;
  bool initialized = false;

  void reset() {
    checkedState.clear();
    selectedListIds.clear();
    addableItems = [];
    isLoading = false;
    initialized = false;
    _ref = null;
  }

  void setRef(WidgetRef ref) {
    _ref = ref;
  }

  void updateCheckedState(String id, bool value) {
    checkedState[id] = value;
    notifyListeners();
  }

  void updateSelectedList(String id, String? listId) {
    selectedListIds[id] = listId;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  int get checkedCount => checkedState.entries
      .where((e) => e.value && addableItems.any((i) => i.id == e.key))
      .length;

  bool get isButtonEnabled => checkedCount > 0 && !isLoading;

  /// Triggers a rebuild of listeners (used after initialization)
  void triggerRebuild() => notifyListeners();

  Future<void> addToShoppingList(NavigatorState navigator) async {
    if (_ref == null) return;
    final ref = _ref!;

    setLoading(true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Group items by list
      final itemsByList = <String?, List<_EnrichedShoppingItem>>{};

      for (final item in addableItems) {
        final id = item.id;
        if (checkedState[id] == true) {
          final listId = selectedListIds[id];
          itemsByList.putIfAbsent(listId, () => []);
          itemsByList[listId]!.add(item);
        }
      }

      // Add items to each list
      for (final entry in itemsByList.entries) {
        final listId = entry.key;
        final items = entry.value;

        final itemsNotifier = ref.read(shoppingListItemsProvider(listId).notifier);

        for (final item in items) {
          await itemsNotifier.addItem(
            name: item.name,
            userId: userId,
            // Terms and category from extraction
            terms: item.terms,
            category: item.category,
          );
        }
      }

      // Close the modal
      navigator.pop();
    } catch (e) {
      AppLogger.error('Error adding clipping items to shopping list', e);
      setLoading(false);
    }
  }
}

// ============================================================================
// Content Widget
// ============================================================================

class _ClippingShoppingListContent extends ConsumerStatefulWidget {
  final List<ExtractedShoppingItem> items;
  final ValueNotifier<int> pageIndexNotifier;
  final _ClippingShoppingListController controller;

  const _ClippingShoppingListContent({
    required this.items,
    required this.pageIndexNotifier,
    required this.controller,
  });

  @override
  ConsumerState<_ClippingShoppingListContent> createState() =>
      _ClippingShoppingListContentState();
}

class _ClippingShoppingListContentState
    extends ConsumerState<_ClippingShoppingListContent> {
  _ClippingShoppingListController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the ref on the controller so it can add items
    controller.setRef(ref);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Watch shopping lists and current selection
    final listsAsync = ref.watch(shoppingListsProvider);
    final currentListId = ref.watch(currentShoppingListProvider);

    // Watch the enriched items (like aggregatedIngredientsProvider pattern)
    final enrichedItemsAsync =
        ref.watch(_enrichedClippingItemsProvider(widget.items));

    return listsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(child: Text('Error: $error')),
      ),
      data: (lists) {
        return enrichedItemsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (enrichedItems) {
            // Initialize state on first build
            if (!controller.initialized) {
              _initializeState(enrichedItems, currentListId);
              controller.initialized = true;
            }

            // Separate items into addable vs already in list
            final addableItems = <_EnrichedShoppingItem>[];
            final alreadyInListItems = <_EnrichedShoppingItem>[];

            for (final item in enrichedItems) {
              if (item.existsInShoppingList) {
                alreadyInListItems.add(item);
              } else {
                addableItems.add(item);
              }
            }

            // Sort addable by stock status
            addableItems.sort(
                (a, b) => _getSortPriority(a).compareTo(_getSortPriority(b)));

            // Update controller's addable items for button state
            controller.addableItems = addableItems;

            // Build list of widgets for SliverList
            final List<Widget> sliverChildren = [];

            // Title row with Manage Lists button
            sliverChildren.add(
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Add to Shopping List',
                      style: AppTypography.h4.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    AppButton(
                      text: 'Manage Lists',
                      onPressed: () {
                        widget.pageIndexNotifier.value = 1;
                      },
                      trailingIcon:
                          const Icon(CupertinoIcons.chevron_right, size: 14),
                      compactTrailingIcon: true,
                      theme: AppButtonTheme.secondary,
                      style: AppButtonStyle.outline,
                      shape: AppButtonShape.square,
                      size: AppButtonSize.small,
                    ),
                  ],
                ),
              ),
            );

            sliverChildren.add(SizedBox(height: AppSpacing.sm));

            // Empty state
            if (addableItems.isEmpty && alreadyInListItems.isEmpty) {
              sliverChildren.add(
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.cart,
                          size: 64,
                          color: colors.textTertiary,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'No items to add',
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'All items are already on a shopping list.',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Addable items
            for (int i = 0; i < addableItems.length; i++) {
              final item = addableItems[i];
              final isFirst = i == 0;
              final isLast =
                  i == addableItems.length - 1 && alreadyInListItems.isEmpty;

              sliverChildren.add(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildItemRow(
                    context,
                    item,
                    lists,
                    currentListId,
                    isFirst: isFirst,
                    isLast: isLast,
                  ),
                ),
              );
            }

            // Already in list items
            for (int i = 0; i < alreadyInListItems.length; i++) {
              final item = alreadyInListItems[i];
              final isFirst = i == 0 && addableItems.isEmpty;
              final isLast = i == alreadyInListItems.length - 1;

              sliverChildren.add(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildAlreadyInListRow(
                    context,
                    item,
                    isFirst: isFirst,
                    isLast: isLast,
                  ),
                ),
              );
            }

            // Bottom padding for sticky action bar
            sliverChildren.add(const SizedBox(height: 130));

            return SliverList(
              delegate: SliverChildListDelegate(sliverChildren),
            );
          },
        );
      },
    );
  }

  void _initializeState(
    List<_EnrichedShoppingItem> items,
    String? defaultListId,
  ) {
    for (final item in items) {
      final id = item.id;

      // Skip items already in a list
      if (item.existsInShoppingList) continue;

      // Pre-check items based on pantry status:
      // - No pantry match -> checked
      // - Out of stock -> checked
      // - Low stock -> checked
      // - In stock -> NOT checked
      if (!controller.checkedState.containsKey(id)) {
        final pantryItem = item.matchingPantryItem;
        final shouldCheck = pantryItem == null ||
            pantryItem.stockStatus == StockStatus.outOfStock ||
            pantryItem.stockStatus == StockStatus.lowStock;
        controller.checkedState[id] = shouldCheck;
      }

      // Default list selection
      if (!controller.selectedListIds.containsKey(id)) {
        controller.selectedListIds[id] = defaultListId;
      }
    }
  }

  int _getSortPriority(_EnrichedShoppingItem item) {
    final pantryItem = item.matchingPantryItem;
    if (pantryItem != null) {
      final status = pantryItem.stockStatus;
      if (status == StockStatus.outOfStock) return 1;
      if (status == StockStatus.lowStock) return 2;
      if (status == StockStatus.inStock) return 3;
    }
    return 0; // No match at top (most likely to need)
  }

  Widget _buildStockChip(_EnrichedShoppingItem item) {
    final pantryItem = item.matchingPantryItem;
    if (pantryItem == null) {
      return StockChip(showNotInPantry: true);
    }
    return StockChip(status: pantryItem.stockStatus);
  }

  Widget _buildItemRow(
    BuildContext context,
    _EnrichedShoppingItem item,
    List<ShoppingListEntry> lists,
    String? defaultListId, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
    final isChecked = controller.checkedState[item.id] ?? false;
    final selectedListId =
        controller.selectedListIds[item.id] ?? defaultListId;

    // Get list name for display
    String listName = 'My Shopping List';
    if (selectedListId != null) {
      final list = lists.where((l) => l.id == selectedListId).firstOrNull;
      listName = list?.name ?? 'My Shopping List';
    }

    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.groupedListBackground,
        border: border,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                controller.updateCheckedState(item.id, !isChecked);
              },
              child: AppRadioButton(
                selected: isChecked,
                onTap: () {
                  controller.updateCheckedState(item.id, !isChecked);
                },
              ),
            ),

            SizedBox(width: AppSpacing.md),

            // Item info (name + stock chip below)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  _buildStockChip(item),
                ],
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // List dropdown
            AdaptivePullDownButton(
              items: [
                AdaptiveMenuItem(
                  title: 'My Shopping List',
                  icon: Icon(selectedListId == null
                      ? CupertinoIcons.checkmark
                      : CupertinoIcons.list_bullet),
                  onTap: () {
                    controller.updateSelectedList(item.id, null);
                    if (!isChecked) {
                      controller.updateCheckedState(item.id, true);
                    }
                  },
                ),
                ...lists.map((list) => AdaptiveMenuItem(
                      title: list.name ?? 'Unnamed',
                      icon: Icon(selectedListId == list.id
                          ? CupertinoIcons.checkmark
                          : CupertinoIcons.list_bullet),
                      onTap: () {
                        controller.updateSelectedList(item.id, list.id);
                        if (!isChecked) {
                          controller.updateCheckedState(item.id, true);
                        }
                      },
                    )),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        listName,
                        style: TextStyle(
                          color: colors.chipText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: colors.chipText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyInListRow(
    BuildContext context,
    _EnrichedShoppingItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);

    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.groupedListBackground,
        border: border,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Spacer instead of checkbox (for alignment)
            SizedBox(width: 24 + AppSpacing.md),

            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textTertiary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Already on shopping list',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
