import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/pantry_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/pantry_item_list.dart';
import 'add_pantry_item_modal.dart';

class PantryTab extends ConsumerWidget {
  const PantryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all pantry items
    final pantryItemsAsyncValue = ref.watch(pantryItemsProvider);

    return AdaptiveSliverPage(
      title: 'Pantry',
      searchEnabled: true,
      onSearchChanged: (query) {
        // TODO: Implement search functionality for pantry items
      },
      slivers: [
        pantryItemsAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (pantryItems) {
            if (pantryItems.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text('No pantry items yet. Tap the + button to add items.')
                ),
              );
            }

            return PantryItemList(pantryItems: pantryItems);
          },
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Add Pantry Item',
            icon: const Icon(CupertinoIcons.cart_badge_plus),
            onTap: () {
              showPantryItemEditorModal(context);
            },
          )
        ],
        child: const Icon(CupertinoIcons.add_circled),
      ),
    );
  }
}
