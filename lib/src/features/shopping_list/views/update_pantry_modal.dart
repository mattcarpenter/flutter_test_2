import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/pantry_update_models.dart';
import '../services/pantry_update_service.dart';
import '../widgets/pantry_update_item_tile.dart';

// State management for checked items
final _updatePantryCheckedItemsProvider = StateProvider<Map<String, bool>>((ref) => {});
final _updatePantryResultProvider = StateProvider<PantryUpdateResult?>((ref) => null);

void showUpdatePantryModal(
  BuildContext context,
  List<ShoppingListItemEntry> boughtItems,
) {
  // Reset providers when modal opens
  final container = ProviderScope.containerOf(context);
  container.invalidate(_updatePantryCheckedItemsProvider);
  container.invalidate(_updatePantryResultProvider);

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      UpdatePantryModalPage.build(
        context: bottomSheetContext,
        boughtItems: boughtItems,
      ),
    ],
  );
}

class UpdatePantryModalPage {
  UpdatePantryModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext context,
    required List<ShoppingListItemEntry> boughtItems,
  }) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: CupertinoColors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: true,
      hasSabGradient: true,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      mainContentSliversBuilder: (BuildContext builderContext) {
        return [
          // Use Consumer to reactively watch providers
          Consumer(
            builder: (context, ref, child) {
              final pantryItemsAsync = ref.watch(pantryItemsProvider);
              final checkedItems = ref.watch(_updatePantryCheckedItemsProvider);

              return _UpdatePantryContentSlivers(
                pantryItemsAsync: pantryItemsAsync,
                checkedItems: checkedItems,
                boughtItems: boughtItems,
              );
            },
          ),
        ];
      },
      stickyActionBar: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).background,
          border: Border(
            top: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: UpdatePantryButton(boughtItems: boughtItems),
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          '($count)',
          style: AppTypography.body.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}

class _UpdatePantryContentSlivers extends ConsumerWidget {
  final AsyncValue<List<PantryItemEntry>> pantryItemsAsync;
  final Map<String, bool> checkedItems;
  final List<ShoppingListItemEntry> boughtItems;

  const _UpdatePantryContentSlivers({
    required this.pantryItemsAsync,
    required this.checkedItems,
    required this.boughtItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Spacing above title
        SizedBox(height: AppSpacing.md),

        // Title
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
          child: Text(
            'Update Pantry',
            style: AppTypography.h4.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Content based on async state
        ...pantryItemsAsync.when(
          loading: () => [
            SizedBox(
              height: 300,
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          ],
          error: (error, stack) => [
            SizedBox(
              height: 300,
              child: Center(
                child: Text('Error loading pantry: $error'),
              ),
            ),
          ],
          data: (pantryItems) {
            // Analyze updates
            final updateResult = PantryUpdateService.analyzeUpdates(
              shoppingListItems: boughtItems,
              pantryItems: pantryItems,
            );

            // Store result in provider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(_updatePantryResultProvider.notifier).state = updateResult;
            });

            // No changes state
            if (!updateResult.hasChanges) {
              return [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.activeGreen,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nothing to update',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All items are already in your pantry\nand marked as in stock.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }

            // Build widgets for items
            final List<Widget> widgets = [];

            // Items to add section
            if (updateResult.itemsToAdd.isNotEmpty) {
              widgets.add(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: UpdatePantryModalPage._buildSectionHeader(
                    context,
                    'Items to add',
                    updateResult.itemsToAdd.length,
                  ),
                ),
              );
              widgets.add(SizedBox(height: AppSpacing.sm));

              // Add each item
              for (final item in updateResult.itemsToAdd) {
                final itemId = 'add_${item.shoppingListItem.id}';
                widgets.add(
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: PantryUpdateItemTile(
                      item: item,
                      isChecked: checkedItems[itemId] ?? true,
                      onCheckedChanged: (value) {
                        final newCheckedItems = {...checkedItems};
                        newCheckedItems[itemId] = value;
                        ref.read(_updatePantryCheckedItemsProvider.notifier).state = newCheckedItems;
                      },
                    ),
                  ),
                );
              }

              widgets.add(SizedBox(height: AppSpacing.xl));
            }

            // Items to update section
            if (updateResult.itemsToUpdate.isNotEmpty) {
              widgets.add(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: UpdatePantryModalPage._buildSectionHeader(
                    context,
                    'Items to update',
                    updateResult.itemsToUpdate.length,
                  ),
                ),
              );
              widgets.add(SizedBox(height: AppSpacing.sm));

              // Add each item
              for (final item in updateResult.itemsToUpdate) {
                final itemId = 'update_${item.shoppingListItem.id}';
                widgets.add(
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: PantryUpdateItemTile(
                      item: item,
                      isChecked: checkedItems[itemId] ?? true,
                      onCheckedChanged: (value) {
                        final newCheckedItems = {...checkedItems};
                        newCheckedItems[itemId] = value;
                        ref.read(_updatePantryCheckedItemsProvider.notifier).state = newCheckedItems;
                      },
                    ),
                  ),
                );
              }
            }

            // Bottom padding for sticky action bar and gradient
            // Extra padding ensures last item is fully visible above the gradient
            widgets.add(SizedBox(height: 150));

            return widgets;
          },
        ),
      ]),
    );
  }
}

class UpdatePantryButton extends ConsumerWidget {
  final List<ShoppingListItemEntry> boughtItems;

  const UpdatePantryButton({
    super.key,
    required this.boughtItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedItems = ref.watch(_updatePantryCheckedItemsProvider);
    final updateResult = ref.watch(_updatePantryResultProvider);
    
    if (updateResult == null) {
      return const SizedBox.shrink();
    }

    // Count checked items
    int checkedCount = 0;
    for (final item in updateResult.itemsToAdd) {
      final itemId = 'add_${item.shoppingListItem.id}';
      if (checkedItems[itemId] ?? true) checkedCount++;
    }
    for (final item in updateResult.itemsToUpdate) {
      final itemId = 'update_${item.shoppingListItem.id}';
      if (checkedItems[itemId] ?? true) checkedCount++;
    }

    final isEnabled = checkedCount > 0;

    return AppButtonVariants.primaryFilled(
      text: checkedCount > 0
          ? 'Update Pantry ($checkedCount)'
          : 'Update Pantry',
      size: AppButtonSize.large,
      shape: AppButtonShape.square,
      fullWidth: true,
      onPressed: isEnabled
          ? () async {
              await _performUpdate(context, ref, updateResult, checkedItems);
            }
          : null,
    );
  }

  Future<void> _performUpdate(
    BuildContext context,
    WidgetRef ref,
    PantryUpdateResult updateResult,
    Map<String, bool> checkedItems,
  ) async {
    final pantryNotifier = ref.read(pantryItemsProvider.notifier);
    final currentListId = ref.read(currentShoppingListProvider);
    final shoppingListNotifier = ref.read(shoppingListItemsProvider(currentListId).notifier);

    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(
          radius: 16,
        ),
      ),
    );

    try {
      // Process items to add
      for (final item in updateResult.itemsToAdd) {
        final itemId = 'add_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          await pantryNotifier.addItem(
            name: item.shoppingListItem.name,
            stockStatus: StockStatus.inStock,
            category: item.shoppingListItem.category,
            userId: item.shoppingListItem.userId,
            householdId: item.shoppingListItem.householdId,
          );
        }
      }

      // Process items to update
      for (final item in updateResult.itemsToUpdate) {
        final itemId = 'update_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          await pantryNotifier.updateItem(
            id: item.matchingPantryItem!.id,
            stockStatus: StockStatus.inStock,
          );
        }
      }

      // Delete the shopping list items that were processed
      final processedItemIds = <String>[];
      for (final item in updateResult.itemsToAdd) {
        final itemId = 'add_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          processedItemIds.add(item.shoppingListItem.id);
        }
      }
      for (final item in updateResult.itemsToUpdate) {
        final itemId = 'update_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          processedItemIds.add(item.shoppingListItem.id);
        }
      }

      // Delete all processed items from shopping list
      if (processedItemIds.isNotEmpty) {
        await shoppingListNotifier.deleteMultipleItems(processedItemIds);
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Close the modal
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error updating pantry: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update pantry: $e'),
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
}