import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ClippingSortOption {
  recentlyModified('Recently Modified'),
  recentlyCreated('Recently Created'),
  alphabetical('Alphabetical');

  final String label;
  const ClippingSortOption(this.label);
}

enum SortDirection { ascending, descending }

class ClippingsFilterSortState {
  final ClippingSortOption sortOption;
  final SortDirection sortDirection;
  final String searchQuery;

  const ClippingsFilterSortState({
    this.sortOption = ClippingSortOption.recentlyModified,
    this.sortDirection = SortDirection.descending,
    this.searchQuery = '',
  });

  ClippingsFilterSortState copyWith({
    ClippingSortOption? sortOption,
    SortDirection? sortDirection,
    String? searchQuery,
  }) {
    return ClippingsFilterSortState(
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ClippingsFilterSortNotifier extends Notifier<ClippingsFilterSortState> {
  static const _sortOptionKey = 'clippings_sort_option';
  static const _sortDirectionKey = 'clippings_sort_direction';

  @override
  ClippingsFilterSortState build() {
    _loadState();
    return const ClippingsFilterSortState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt(_sortOptionKey) ?? 0;
    final dirIndex = prefs.getInt(_sortDirectionKey) ?? 1;

    state = state.copyWith(
      sortOption: ClippingSortOption.values[sortIndex.clamp(0, ClippingSortOption.values.length - 1)],
      sortDirection: SortDirection.values[dirIndex.clamp(0, SortDirection.values.length - 1)],
    );
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortOptionKey, state.sortOption.index);
    await prefs.setInt(_sortDirectionKey, state.sortDirection.index);
  }

  void updateSortOption(ClippingSortOption option) {
    state = state.copyWith(sortOption: option);
    _saveState();
  }

  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    _saveState();
  }

  void toggleSortDirection() {
    final newDirection = state.sortDirection == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
    updateSortDirection(newDirection);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

final clippingsFilterSortProvider =
    NotifierProvider<ClippingsFilterSortNotifier, ClippingsFilterSortState>(
  ClippingsFilterSortNotifier.new,
);
