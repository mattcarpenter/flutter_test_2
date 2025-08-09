import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../../database/models/pantry_items.dart';
import '../../../../theme/colors.dart';
import '../../models/pantry_filter_sort.dart';

/// Shows a bottom sheet for selecting stock status filters
void showStockStatusFilterSheet(
  BuildContext context, {
  required List<StockStatus> selectedStatuses,
  required Function(List<StockStatus>) onStatusesChanged,
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
          topBarTitle: const Text('Filter by Stock Status'),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          trailingNavBarWidget: TextButton(
            onPressed: () {
              // Clear all stock status filters
              onStatusesChanged([]);
              Navigator.of(modalContext).pop();
            },
            child: const Text('Clear All'),
          ),
          child: StockStatusFilterContent(
            selectedStatuses: selectedStatuses,
            onStatusesChanged: (statuses) {
              onStatusesChanged(statuses);
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

class StockStatusFilterContent extends ConsumerStatefulWidget {
  final List<StockStatus> selectedStatuses;
  final Function(List<StockStatus>) onStatusesChanged;

  const StockStatusFilterContent({
    super.key,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  @override
  ConsumerState<StockStatusFilterContent> createState() => _StockStatusFilterContentState();
}

class _StockStatusFilterContentState extends ConsumerState<StockStatusFilterContent> {
  late List<StockStatus> _selectedStatuses;

  @override
  void initState() {
    super.initState();
    _selectedStatuses = List.from(widget.selectedStatuses);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: StockStatusFilter.values.map((filter) {
                    final isSelected = _selectedStatuses.contains(filter.stockStatus);
                    return FilterChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStatuses.add(filter.stockStatus);
                          } else {
                            _selectedStatuses.remove(filter.stockStatus);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onStatusesChanged(_selectedStatuses);
                },
                child: Text(_selectedStatuses.isEmpty 
                    ? 'Show All Statuses' 
                    : 'Apply Statuses (${_selectedStatuses.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}