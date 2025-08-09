import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../theme/colors.dart';

/// Shows a bottom sheet for selecting category filters
void showCategoryFilterSheet(
  BuildContext context, {
  required List<String> selectedCategories,
  required Function(List<String>) onCategoriesChanged,
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
          topBarTitle: const Text('Filter by Category'),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          trailingNavBarWidget: TextButton(
            onPressed: () {
              // Clear all category filters
              onCategoriesChanged([]);
              Navigator.of(modalContext).pop();
            },
            child: const Text('Clear All'),
          ),
          child: CategoryFilterContent(
            selectedCategories: selectedCategories,
            onCategoriesChanged: (categories) {
              onCategoriesChanged(categories);
              Navigator.of(modalContext).pop();
            },
          ),
        ),
      ];
    },
    onModalDismissedWithBarrierTap: () {
      // The modal will auto-dismiss, no need to manually pop
    },
  );
}

class CategoryFilterContent extends ConsumerStatefulWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onCategoriesChanged;

  const CategoryFilterContent({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  @override
  ConsumerState<CategoryFilterContent> createState() => _CategoryFilterContentState();
}

class _CategoryFilterContentState extends ConsumerState<CategoryFilterContent> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final pantryItemsAsyncValue = ref.watch(pantryItemsProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: pantryItemsAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (pantryItems) {
                  // Extract unique categories from pantry items
                  final categories = pantryItems
                      .map((item) => item.category ?? 'Other')
                      .toSet()
                      .toList()
                    ..sort((a, b) {
                      if (a == 'Other' && b != 'Other') return 1;
                      if (b == 'Other' && a != 'Other') return -1;
                      return a.compareTo(b);
                    });

                  if (categories.isEmpty) {
                    return const Center(child: Text('No categories available'));
                  }

                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: categories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onCategoriesChanged(_selectedCategories);
                },
                child: Text(_selectedCategories.isEmpty 
                    ? 'Show All Categories' 
                    : 'Apply Categories (${_selectedCategories.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}