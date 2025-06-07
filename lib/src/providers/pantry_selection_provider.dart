import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the selection state for pantry items
class PantrySelectionNotifier extends StateNotifier<Set<String>> {
  PantrySelectionNotifier() : super({});

  /// Toggle selection of a pantry item
  void toggleSelection(String itemId) {
    final newSelection = Set<String>.from(state);
    if (newSelection.contains(itemId)) {
      newSelection.remove(itemId);
    } else {
      newSelection.add(itemId);
    }
    state = newSelection;
  }

  /// Clear all selections
  void clearSelection() {
    state = {};
  }

  /// Select all items from the provided list
  void selectAll(List<String> itemIds) {
    state = Set<String>.from(itemIds);
  }

  /// Check if an item is selected
  bool isSelected(String itemId) {
    return state.contains(itemId);
  }

  /// Get the number of selected items
  int get selectedCount => state.length;

  /// Check if any items are selected
  bool get hasSelection => state.isNotEmpty;

  /// Get all selected item IDs
  Set<String> get selectedItems => Set<String>.from(state);
}

/// Provider for pantry item selection state
final pantrySelectionProvider = StateNotifierProvider<PantrySelectionNotifier, Set<String>>((ref) {
  return PantrySelectionNotifier();
});

/// Computed providers for convenience
final pantrySelectionCountProvider = Provider<int>((ref) {
  final selection = ref.watch(pantrySelectionProvider);
  return selection.length;
});

final pantryHasSelectionProvider = Provider<bool>((ref) {
  final selection = ref.watch(pantrySelectionProvider);
  return selection.isNotEmpty;
});