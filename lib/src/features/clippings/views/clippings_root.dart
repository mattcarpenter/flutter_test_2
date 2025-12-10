import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../database/database.dart';
import '../../../providers/household_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/clippings_provider.dart';
import '../../../providers/clippings_filter_sort_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/clippings_filter_sort.dart';
import '../widgets/clipping_list.dart';

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
        // Sort + Add buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                // Sort button - wrapped in Flexible for proper constraints
                Flexible(
                  child: AdaptivePullDownButton(
                    items: ClippingSortOption.values.map((option) {
                      return AdaptiveMenuItem(
                        title: option.label,
                        icon: Icon(
                          filterSortState.sortOption == option
                              ? CupertinoIcons.checkmark
                              : CupertinoIcons.circle,
                          color: filterSortState.sortOption == option
                              ? null
                              : Colors.transparent,
                        ),
                        onTap: () {
                          ref
                              .read(clippingsFilterSortProvider.notifier)
                              .updateSortOption(option);
                        },
                      );
                    }).toList(),
                    child: AppButton(
                      text: filterSortState.sortOption.label,
                      trailingIcon: Icon(
                        filterSortState.sortDirection == SortDirection.ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                      style: AppButtonStyle.mutedOutline,
                      shape: AppButtonShape.square,
                      size: AppButtonSize.medium,
                      theme: AppButtonTheme.primary,
                      onPressed: () {
                        // Toggle direction when button is tapped (menu handles option change)
                        ref
                            .read(clippingsFilterSortProvider.notifier)
                            .toggleSortDirection();
                      },
                    ),
                  ),
                ),

                SizedBox(width: AppSpacing.md),

                // Add Clipping button
                AppButton(
                  text: 'New',
                  leadingIcon: const Icon(Icons.add),
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  theme: AppButtonTheme.secondary,
                  onPressed: () => _createNewClipping(context, ref),
                ),
              ],
            ),
          ),
        ),

        // Clippings list with filtering and sorting applied
        clippingsAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (clippings) {
            // Apply search filter
            List<ClippingEntry> filteredClippings = clippings;
            if (filterSortState.searchQuery.isNotEmpty) {
              filteredClippings =
                  clippings.applySearch(filterSortState.searchQuery);
            }

            // Apply sorting
            filteredClippings = filteredClippings.applySorting(
              filterSortState.sortOption,
              filterSortState.sortDirection,
            );

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

            return ClippingList(
              clippings: filteredClippings,
              onDelete: (id) {
                ref.read(clippingsProvider.notifier).deleteClipping(id);
              },
            );
          },
        ),
      ],
      trailing: AdaptivePullDownButton(
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
    );
  }

  Future<void> _createNewClipping(BuildContext context, WidgetRef ref) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Get the current household ID
    final householdState = ref.read(householdNotifierProvider);
    final householdId = householdState.currentHousehold?.id;
    AppLogger.debug('Creating clipping with householdId: $householdId (household: ${householdState.currentHousehold?.name})');

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
