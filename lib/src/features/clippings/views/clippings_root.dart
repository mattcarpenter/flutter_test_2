import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/household_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/clippings_provider.dart';
import '../../../providers/clippings_filter_sort_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/clippings_filter_sort.dart';
import '../widgets/clipping_grid.dart';
import 'clipping_help_modal.dart';

class ClippingsTab extends ConsumerWidget {
  final VoidCallback? onMenuPressed;

  const ClippingsTab({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all clippings
    final clippingsAsyncValue = ref.watch(clippingsProvider);

    // Watch filter/sort state
    final filterSortState = ref.watch(clippingsFilterSortProvider);

    // Check if tablet for leading widget
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final menuButton = onMenuPressed != null
        ? GestureDetector(
            onTap: onMenuPressed,
            child: const Icon(CupertinoIcons.bars),
          )
        : null;

    return AdaptiveSliverPage(
      title: 'Clippings',
      leading: isTablet ? null : menuButton,
      searchEnabled: true,
      onSearchChanged: (query) {
        ref.read(clippingsFilterSortProvider.notifier).updateSearchQuery(query);
      },
      slivers: [
        // Clippings grid with date grouping
        clippingsAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (clippings) {
            // Apply search filter only (sorting is handled by date grouping)
            var filteredClippings = clippings;
            if (filterSortState.searchQuery.isNotEmpty) {
              filteredClippings =
                  clippings.applySearch(filterSortState.searchQuery);
            }

            if (filteredClippings.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        size: 48,
                        color: AppColors.of(context).textTertiary,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        filterSortState.searchQuery.isNotEmpty
                            ? 'No clippings match your search'
                            : 'No clippings yet',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                      if (filterSortState.searchQuery.isEmpty) ...[
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Tap the + button to add a clipping',
                          style: TextStyle(
                            color: AppColors.of(context).textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (filterSortState.searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(clippingsFilterSortProvider.notifier)
                                .clearSearch();
                          },
                          child: const Text('Clear Search'),
                        ),
                    ],
                  ),
                ),
              );
            }

            return ClippingGrid(
              clippings: filteredClippings,
              onDelete: (id) {
                ref.read(clippingsProvider.notifier).deleteClipping(id);
              },
            );
          },
        ),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCircleButton(
            icon: AppCircleButtonIcon.info,
            variant: AppCircleButtonVariant.neutral,
            onPressed: () => showClippingHelpModal(context),
          ),
          SizedBox(width: AppSpacing.sm),
          AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'New Clipping',
                icon: const Icon(CupertinoIcons.doc_text_fill),
                onTap: () => _createNewClipping(context, ref),
              ),
            ],
            child: const AppCircleButton(
              icon: AppCircleButtonIcon.plus,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewClipping(BuildContext context, WidgetRef ref) async {
    // userId can be null - orphaned clippings will be claimed on sign-in
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // Get the current household ID (only if logged in)
    String? householdId;
    if (userId != null) {
      final householdState = ref.read(householdNotifierProvider);
      householdId = householdState.currentHousehold?.id;
    }
    AppLogger.debug('Creating clipping with userId: $userId, householdId: $householdId');

    // Create a new empty clipping
    final newId = await ref.read(clippingsProvider.notifier).addClipping(
          userId: userId,
          householdId: householdId,
          title: null,
          content: null,
        );

    // Navigate to the editor
    if (context.mounted) {
      context.push('/clippings/$newId');
    }
  }
}
