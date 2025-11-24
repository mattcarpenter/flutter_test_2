import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Wrapper class to unify RecipeFolderEntry and virtual folders in drag list
class _FolderItem {
  final String id;
  final String name;
  final int folderType; // 0 = regular, -1 = uncategorized virtual folder, >0 = smart folder

  const _FolderItem({
    required this.id,
    required this.name,
    required this.folderType,
  });

  factory _FolderItem.fromFolder(RecipeFolderEntry folder) {
    return _FolderItem(
      id: folder.id,
      name: folder.name,
      folderType: folder.folderType,
    );
  }

  factory _FolderItem.uncategorized() {
    return _FolderItem(
      id: kUncategorizedFolderId,
      name: kUncategorizedFolderName,
      folderType: -1, // Special type for uncategorized
    );
  }

  bool get isUncategorized => folderType == -1;
  bool get isSmartFolder => folderType > 0;
}

/// Page for selecting folder sort option with custom drag-and-drop ordering
class SortFoldersPage extends ConsumerStatefulWidget {
  const SortFoldersPage({super.key});

  @override
  ConsumerState<SortFoldersPage> createState() => _SortFoldersPageState();
}

class _SortFoldersPageState extends ConsumerState<SortFoldersPage> {
  // Local state for custom order (used during drag operations)
  List<String>? _localCustomOrder;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currentSortOption = ref.watch(folderSortOptionProvider);
    final customOrder = ref.watch(customFolderOrderProvider);
    final foldersAsync = ref.watch(recipeFolderNotifierProvider);

    final sortOptions = [
      _SortOption(
        value: 'alphabetical_asc',
        title: 'Alphabetical (A-Z)',
        icon: CupertinoIcons.sort_up,
      ),
      _SortOption(
        value: 'alphabetical_desc',
        title: 'Alphabetical (Z-A)',
        icon: CupertinoIcons.sort_down,
      ),
      _SortOption(
        value: 'newest',
        title: 'Newest First',
        icon: CupertinoIcons.time,
      ),
      _SortOption(
        value: 'oldest',
        title: 'Oldest First',
        icon: CupertinoIcons.clock,
      ),
      _SortOption(
        value: 'custom',
        title: 'Custom',
        icon: CupertinoIcons.hand_draw,
      ),
    ];

    return AdaptiveSliverPage(
      title: 'Sort Folders',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Layout',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              // Sort options
              SettingsGroupCondensed(
                children: sortOptions.map((option) {
                  final isSelected = currentSortOption == option.value;

                  return SettingsSelectionRow(
                    title: option.title,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setFolderSortOption(option.value);
                    },
                  );
                }).toList(),
              ),

              // Custom order drag list (only show when custom is selected)
              if (currentSortOption == 'custom') ...[
                SizedBox(height: AppSpacing.xl),
                foldersAsync.when(
                  data: (folders) => _buildCustomOrderSection(
                    context,
                    colors,
                    folders,
                    _localCustomOrder ?? customOrder,
                  ),
                  loading: () => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (_, __) => Text(
                    'Error loading folders',
                    style: AppTypography.body.copyWith(color: colors.error),
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomOrderSection(
    BuildContext context,
    AppColors colors,
    List<RecipeFolderEntry> folders,
    List<String> customOrder,
  ) {
    // Build ordered list: folders in customOrder first, then new folders at end
    // Includes the virtual Uncategorized folder
    final orderedItems = _applyCustomOrder(folders, customOrder);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.sm),
            child: Text(
              'CUSTOM ORDER',
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Drag list with connected borders like IngredientsSection
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: orderedItems.length,
              itemBuilder: (context, index) {
                final item = orderedItems[index];
                final isFirst = index == 0;
                final isLast = index == orderedItems.length - 1;

                return _DraggableFolderItem(
                  key: ValueKey(item.id),
                  item: item,
                  index: index,
                  isFirst: isFirst,
                  isLast: isLast,
                  totalCount: orderedItems.length,
                );
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final elevation = Tween<double>(begin: 0, end: 6).evaluate(animation);
                    return Material(
                      elevation: elevation,
                      color: colors.input,
                      borderRadius: BorderRadius.circular(8),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                _handleReorder(orderedItems, oldIndex, newIndex);
              },
            ),
          ),

          // Footer
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg, top: AppSpacing.sm),
            child: Text(
              'Drag folders to set your preferred order.',
              style: AppTypography.caption.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_FolderItem> _applyCustomOrder(
    List<RecipeFolderEntry> folders,
    List<String> customOrder,
  ) {
    final orderedItems = <_FolderItem>[];

    // Create map of all folder items including uncategorized
    final uncategorized = _FolderItem.uncategorized();
    final itemMap = <String, _FolderItem>{
      uncategorized.id: uncategorized,
      for (var f in folders) f.id: _FolderItem.fromFolder(f),
    };

    // Add items in custom order
    for (final id in customOrder) {
      if (itemMap.containsKey(id)) {
        orderedItems.add(itemMap.remove(id)!);
      }
    }

    // Append remaining (new) items at bottom
    orderedItems.addAll(itemMap.values);

    return orderedItems;
  }

  void _handleReorder(
    List<_FolderItem> orderedItems,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Create new order list
    final newOrderedItems = List<_FolderItem>.from(orderedItems);
    final item = newOrderedItems.removeAt(oldIndex);
    newOrderedItems.insert(newIndex, item);

    // Extract IDs for the new order
    final newOrder = newOrderedItems.map((f) => f.id).toList();

    // Update local state immediately for responsive UI
    setState(() {
      _localCustomOrder = newOrder;
    });

    // Save to settings
    ref.read(appSettingsProvider.notifier).setCustomFolderOrder(newOrder);
  }
}

class _SortOption {
  final String value;
  final String title;
  final IconData icon;

  const _SortOption({
    required this.value,
    required this.title,
    required this.icon,
  });
}

/// Draggable folder item for the custom order list with connected borders
class _DraggableFolderItem extends StatelessWidget {
  final _FolderItem item;
  final int index;
  final bool isFirst;
  final bool isLast;
  final int totalCount;

  const _DraggableFolderItem({
    super.key,
    required this.item,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.totalCount,
  });

  // Border radius calculation for connected group styling
  BorderRadius _getBorderRadius() {
    if (isFirst && isLast) {
      return BorderRadius.circular(8.0);
    } else if (isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(8.0),
        topRight: Radius.circular(8.0),
      );
    } else if (isLast) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(8.0),
        bottomRight: Radius.circular(8.0),
      );
    } else {
      return BorderRadius.zero;
    }
  }

  // Border calculation - omit top border for non-first items to prevent double borders
  Border _getBorder(AppColors colors) {
    final borderColor = colors.borderStrong;
    const borderWidth = 1.0;

    if (isFirst) {
      return Border.all(color: borderColor, width: borderWidth);
    } else {
      return Border(
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: borderColor, width: borderWidth),
        bottom: BorderSide(color: borderColor, width: borderWidth),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Determine icon based on folder type
    IconData folderIcon;
    if (item.isUncategorized) {
      folderIcon = CupertinoIcons.tray;
    } else if (item.isSmartFolder) {
      folderIcon = CupertinoIcons.wand_stars;
    } else {
      folderIcon = CupertinoIcons.folder;
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.input,
        border: _getBorder(colors),
        borderRadius: _getBorderRadius(),
      ),
      child: Row(
        children: [
          SizedBox(width: AppSpacing.md),

          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                color: colors.textTertiary,
                size: 20,
              ),
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          // Folder icon
          Icon(
            folderIcon,
            color: colors.primary,
            size: 20,
          ),

          SizedBox(width: AppSpacing.md),

          // Folder name
          Expanded(
            child: Text(
              item.name,
              style: AppTypography.body.copyWith(
                color: colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}
