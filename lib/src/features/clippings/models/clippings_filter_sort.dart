import '../../../../database/database.dart';
import '../../../providers/clippings_filter_sort_provider.dart';
import '../utils/quill_text_extractor.dart';

extension ClippingsFiltering on List<ClippingEntry> {
  List<ClippingEntry> applySearch(String query) {
    if (query.isEmpty) return this;

    final lowerQuery = query.toLowerCase();
    return where((clipping) {
      final title = clipping.title?.toLowerCase() ?? '';
      // Extract plain text from Quill Delta JSON for searching
      final content = extractPlainTextFromQuillJson(clipping.content).toLowerCase();
      return title.contains(lowerQuery) || content.contains(lowerQuery);
    }).toList();
  }
}

extension ClippingsSorting on List<ClippingEntry> {
  List<ClippingEntry> applySorting(
    ClippingSortOption option,
    SortDirection direction,
  ) {
    final sorted = List<ClippingEntry>.from(this);

    switch (option) {
      case ClippingSortOption.recentlyModified:
        sorted.sort((a, b) {
          final aTime = a.updatedAt ?? 0;
          final bTime = b.updatedAt ?? 0;
          return direction == SortDirection.descending
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        });
      case ClippingSortOption.recentlyCreated:
        sorted.sort((a, b) {
          final aTime = a.createdAt ?? 0;
          final bTime = b.createdAt ?? 0;
          return direction == SortDirection.descending
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        });
      case ClippingSortOption.alphabetical:
        sorted.sort((a, b) {
          final aTitle = a.title?.toLowerCase() ?? '';
          final bTitle = b.title?.toLowerCase() ?? '';
          return direction == SortDirection.ascending
              ? aTitle.compareTo(bTitle)
              : bTitle.compareTo(aTitle);
        });
    }

    return sorted;
  }
}
