import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/pantry_item_terms.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../widgets/stock_status_dropdown.dart';

/// Shows a bottom sheet for editing a pantry item
void showUpdatePantryItemModal(
  BuildContext context, {
  required PantryItemEntry pantryItem,
}) {
  // Page navigation state
  final pageIndexNotifier = ValueNotifier<int>(0);

  // Terms state - persists across page navigation (not in widget state!)
  final termsNotifier = ValueNotifier<List<PantryItemTerm>>(
    pantryItem.terms != null ? List<PantryItemTerm>.from(pantryItem.terms!) : [],
  );

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalContext) {
      return [
        // Page 0: Edit pantry item form
        _buildEditPage(modalContext, pantryItem, pageIndexNotifier, termsNotifier),

        // Page 1: Add custom term
        _buildAddTermPage(modalContext, pantryItem, pageIndexNotifier, termsNotifier),
      ];
    },
  ).then((_) {
    // Clean up notifiers when modal closes
    termsNotifier.dispose();
  });
}

// ============================================================================
// Page 0: Edit Pantry Item
// ============================================================================

SliverWoltModalSheetPage _buildEditPage(
  BuildContext context,
  PantryItemEntry pantryItem,
  ValueNotifier<int> pageIndexNotifier,
  ValueNotifier<List<PantryItemTerm>> termsNotifier,
) {
  return SliverWoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(context).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: true,
    isTopBarLayerAlwaysVisible: false,
    leadingNavBarWidget: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    ),
    trailingNavBarWidget: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      onPressed: () async {
        // Access the state to save
        final state = _EditPantryItemPage.currentState;
        if (state != null) {
          await state.savePantryItem();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: const Text('Save'),
    ),
    mainContentSliversBuilder: (context) => [
      SliverToBoxAdapter(
        child: _EditPantryItemPage(
          pantryItem: pantryItem,
          pageIndexNotifier: pageIndexNotifier,
          termsNotifier: termsNotifier,
        ),
      ),
    ],
  );
}

class _EditPantryItemPage extends ConsumerStatefulWidget {
  final PantryItemEntry pantryItem;
  final ValueNotifier<int> pageIndexNotifier;
  final ValueNotifier<List<PantryItemTerm>> termsNotifier;

  // Static reference to current state for save button access
  static _EditPantryItemPageState? currentState;

  const _EditPantryItemPage({
    required this.pantryItem,
    required this.pageIndexNotifier,
    required this.termsNotifier,
  });

  @override
  ConsumerState<_EditPantryItemPage> createState() => _EditPantryItemPageState();
}

class _EditPantryItemPageState extends ConsumerState<_EditPantryItemPage> {
  late final TextEditingController _nameController;
  late StockStatus _stockStatus;
  late bool _isStaple;

  // Track terms being deleted for fade-out animation
  final Set<String> _deletingTermKeys = {};

  @override
  void initState() {
    super.initState();

    // Set static reference
    _EditPantryItemPage.currentState = this;

    _nameController = TextEditingController(text: widget.pantryItem.name);
    _stockStatus = widget.pantryItem.stockStatus;
    _isStaple = widget.pantryItem.isStaple;

    // Listen to terms notifier for changes
    widget.termsNotifier.addListener(_onTermsChanged);
  }

  void _onTermsChanged() {
    // Trigger rebuild when terms change
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    widget.termsNotifier.removeListener(_onTermsChanged);
    _EditPantryItemPage.currentState = null;
    super.dispose();
  }

  Future<void> savePantryItem() async {
    // Validate required field
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final name = _nameController.text.trim();

    // Get updated terms from notifier
    var terms = List<PantryItemTerm>.from(widget.termsNotifier.value);

    // Ensure the name is in the terms list
    bool hasNameTerm = terms.any((term) => term.value.toLowerCase() == name.toLowerCase());
    if (!hasNameTerm) {
      terms.add(PantryItemTerm(
        value: name,
        source: 'user',
        sort: terms.length,
      ));
    }

    // Sort terms by their sort order
    terms.sort((a, b) => a.sort.compareTo(b.sort));

    try {
      await ref.read(pantryItemsProvider.notifier).updateItem(
        id: widget.pantryItem.id,
        name: name,
        stockStatus: _stockStatus,
        isStaple: _isStaple,
        terms: terms,
      );
    } catch (e) {
      debugPrint('Error saving pantry item: $e');
    }
  }

  // Add a new term to the shared state (called from page 2)
  void addTermToSharedState(PantryItemTerm newTerm) {
    final currentTerms = widget.termsNotifier.value;

    // Check if term already exists
    if (currentTerms.any((term) => term.value.toLowerCase() == newTerm.value.toLowerCase())) {
      return; // Already exists
    }

    // Update the shared notifier (triggers rebuild via listener)
    widget.termsNotifier.value = [...currentTerms, newTerm];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final terms = widget.termsNotifier.value;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Edit Pantry Item',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Pantry Item Name
          AppTextFieldSimple(
            controller: _nameController,
            placeholder: 'Pantry Item Name',
            textInputAction: TextInputAction.done,
          ),

          SizedBox(height: AppSpacing.lg),

          // Stock Status
          Row(
            children: [
              Text(
                'Stock Status',
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              StockStatusDropdown(
                value: _stockStatus,
                onChanged: (newValue) {
                  setState(() => _stockStatus = newValue);
                },
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg),

          // Staple toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark as staple',
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Staples are assumed to always be in stock',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _isStaple,
                onChanged: (value) {
                  setState(() => _isStaple = value);
                },
              ),
            ],
          ),

          SizedBox(height: AppSpacing.xl),

          // Matching Terms Section
          Row(
            children: [
              Text(
                'Matching Terms',
                style: AppTypography.h5.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'Add Term',
                onPressed: () {
                  widget.pageIndexNotifier.value = 1;
                },
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.square,
                size: AppButtonSize.small,
                leadingIcon: const Icon(Icons.add),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md),

          // No terms placeholder
          if (terms.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'No additional terms for this item. Add terms to improve recipe matching.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: colors.textTertiary,
                ),
              ),
            ),

          // Terms list with reordering
          if (terms.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                final updatedTerms = List<PantryItemTerm>.from(terms);
                final item = updatedTerms.removeAt(oldIndex);
                updatedTerms.insert(newIndex, item);

                // Update sort values
                for (int i = 0; i < updatedTerms.length; i++) {
                  updatedTerms[i] = PantryItemTerm(
                    value: updatedTerms[i].value,
                    source: updatedTerms[i].source,
                    sort: i,
                  );
                }

                // Update shared notifier
                widget.termsNotifier.value = updatedTerms;
              },
              itemCount: terms.length,
              itemBuilder: (context, index) {
                final term = terms[index];
                final isFirst = index == 0;
                final isLast = index == terms.length - 1;

                return _buildTermItem(
                  key: ValueKey('${widget.pantryItem.id}_term_${term.value}_$index'),
                  term: term,
                  isFirst: isFirst,
                  isLast: isLast,
                );
              },
            ),

          SizedBox(height: AppSpacing.md),

          // Help text
          Text(
            'Tip: Add terms that match recipe ingredients to improve matching.',
            style: TextStyle(
              fontSize: 12,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem({
    required Key key,
    required PantryItemTerm term,
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    // Create unique key for tracking deletion
    final termKey = '${widget.pantryItem.id}_${term.value}_${term.source}';
    final isDeleting = _deletingTermKeys.contains(termKey);

    return AnimatedOpacity(
      key: key,
      opacity: isDeleting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.zero,
        child: ContextMenuWidget(
          menuProvider: (_) {
            return Menu(
              children: [
                MenuAction(
                  title: 'Delete',
                  image: MenuImage.icon(Icons.delete),
                  callback: () => _handleTermDeletion(term),
                ),
              ],
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: colors.groupedListBackground,
              border: border,
              borderRadius: borderRadius,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term.value,
                        style: AppTypography.fieldInput.copyWith(
                          color: colors.contentPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Source: ${term.source}',
                        style: AppTypography.caption.copyWith(
                          color: colors.contentSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Drag handle
                ReorderableDragStartListener(
                  index: widget.termsNotifier.value.indexOf(term),
                  child: Icon(
                    Icons.drag_handle,
                    color: colors.uiSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Handle term deletion with fade-out animation
  Future<void> _handleTermDeletion(PantryItemTerm term) async {
    final termKey = '${widget.pantryItem.id}_${term.value}_${term.source}';

    // Mark term as deleting (triggers fade out)
    setState(() {
      _deletingTermKeys.add(termKey);
    });

    // Wait for fade animation to complete
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Get the current terms and remove the deleted one
    final terms = List<PantryItemTerm>.from(widget.termsNotifier.value);
    terms.removeWhere((t) => t.value == term.value && t.source == term.source);

    // Update shared notifier
    widget.termsNotifier.value = terms;

    // Wait a bit then remove from deletion tracking
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    setState(() {
      _deletingTermKeys.remove(termKey);
    });
  }
}

// ============================================================================
// Page 1: Add Custom Term
// ============================================================================

WoltModalSheetPage _buildAddTermPage(
  BuildContext context,
  PantryItemEntry pantryItem,
  ValueNotifier<int> pageIndexNotifier,
  ValueNotifier<List<PantryItemTerm>> termsNotifier,
) {
  return WoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(context).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    leadingNavBarWidget: Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.back,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () {
          pageIndexNotifier.value = 0;
        },
      ),
    ),
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    child: _AddCustomTermPage(
      pantryItem: pantryItem,
      pageIndexNotifier: pageIndexNotifier,
      termsNotifier: termsNotifier,
    ),
  );
}

class _AddCustomTermPage extends ConsumerStatefulWidget {
  final PantryItemEntry pantryItem;
  final ValueNotifier<int> pageIndexNotifier;
  final ValueNotifier<List<PantryItemTerm>> termsNotifier;

  const _AddCustomTermPage({
    required this.pantryItem,
    required this.pageIndexNotifier,
    required this.termsNotifier,
  });

  @override
  ConsumerState<_AddCustomTermPage> createState() => _AddCustomTermPageState();
}

class _AddCustomTermPageState extends ConsumerState<_AddCustomTermPage> {
  late final TextEditingController _termController;
  late final FocusNode _focusNode;
  bool _hasInput = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _termController = TextEditingController();
    _focusNode = FocusNode();
    _termController.addListener(_updateHasInput);

    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _termController.removeListener(_updateHasInput);
    _termController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateHasInput() {
    final hasInput = _termController.text.trim().isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() {
        _hasInput = hasInput;
      });
    }
  }

  Future<void> _addTerm() async {
    final value = _termController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current pantry item
      final pantryItemsAsync = ref.read(pantryItemsProvider);
      final currentItem = pantryItemsAsync.whenOrNull(
        data: (items) => items.firstWhere(
          (item) => item.id == widget.pantryItem.id,
          orElse: () => widget.pantryItem,
        ),
      );

      if (currentItem == null) return;

      // Get existing terms
      final currentTerms = List<PantryItemTerm>.from(currentItem.terms ?? []);

      // Check if term already exists
      if (currentTerms.any((term) => term.value.toLowerCase() == value.toLowerCase())) {
        // Term already exists, just go back
        widget.pageIndexNotifier.value = 0;
        return;
      }

      // Create new term
      final newTerm = PantryItemTerm(
        value: value,
        source: 'user',
        sort: currentTerms.length,
      );

      // Add to list
      currentTerms.add(newTerm);

      // Update pantry item with new terms in database
      await ref.read(pantryItemsProvider.notifier).updateItem(
        id: widget.pantryItem.id,
        name: currentItem.name,
        stockStatus: currentItem.stockStatus,
        isStaple: currentItem.isStaple,
        terms: currentTerms,
      );

      // Update shared terms notifier (page 1 will rebuild automatically via listener)
      widget.termsNotifier.value = currentTerms;

      // Navigate back to main page
      widget.pageIndexNotifier.value = 0;
    } catch (e) {
      debugPrint('Error adding term: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Term for "${widget.pantryItem.name}"',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppTextFieldSimple(
                  controller: _termController,
                  focusNode: _focusNode,
                  placeholder: 'Enter matching term',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTerm(),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              AppButtonVariants.primaryFilled(
                text: 'Add',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                onPressed: (_isLoading || !_hasInput) ? null : _addTerm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
