import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/pantry_selection_provider.dart';

class PantrySelectionFAB extends ConsumerStatefulWidget {
  const PantrySelectionFAB({super.key});

  @override
  ConsumerState<PantrySelectionFAB> createState() => _PantrySelectionFABState();
}

class _PantrySelectionFABState extends ConsumerState<PantrySelectionFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = ref.watch(pantryHasSelectionProvider);
    final selectedCount = ref.watch(pantrySelectionCountProvider);

    // Animate based on selection state
    if (hasSelection) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_animationController.isDismissed) {
          return const SizedBox.shrink();
        }

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () => _showContextMenu(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(CupertinoIcons.chevron_up),
              label: Text(
                '$selectedCount Selected',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context) {
    final selectedItems = ref.read(pantrySelectionProvider);
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'} selected'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateStockStatus(StockStatus.inStock);
            },
            child: const Text('Set All to In-Stock'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateStockStatus(StockStatus.lowStock);
            },
            child: const Text('Set All to Low-Stock'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _updateStockStatus(StockStatus.outOfStock);
            },
            child: const Text('Set All to Out-of-Stock'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
            isDestructiveAction: true,
            child: const Text('Delete Selected'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final selectedItems = ref.read(pantrySelectionProvider);
    
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Items'),
        content: Text(
          'Are you sure you want to delete ${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'}? This action cannot be undone.',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteSelected();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStockStatus(StockStatus stockStatus) async {
    final selectedItems = ref.read(pantrySelectionProvider);
    if (selectedItems.isEmpty) return;

    try {
      await ref.read(pantryNotifierProvider.notifier).updateMultipleStockStatus(
        selectedItems.toList(),
        stockStatus,
      );
      
      // Clear selection after successful update
      ref.read(pantrySelectionProvider.notifier).clearSelection();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to update stock status: $e');
      }
    }
  }

  Future<void> _deleteSelected() async {
    final selectedItems = ref.read(pantrySelectionProvider);
    if (selectedItems.isEmpty) return;

    try {
      await ref.read(pantryNotifierProvider.notifier).deleteMultipleItems(
        selectedItems.toList(),
      );
      
      // Clear selection after successful deletion
      ref.read(pantrySelectionProvider.notifier).clearSelection();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to delete items: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}