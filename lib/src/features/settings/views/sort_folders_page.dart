import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';

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
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              // Sort options
              SettingsGroup(
                children: sortOptions.indexed.map((indexed) {
                  final (index, option) = indexed;
                  final isSelected = currentSortOption == option.value;

                  return SettingsRow(
                    title: option.title,
                    leading: Icon(
                      option.icon,
                      size: 22,
                      color: colors.primary,
                    ),
                    trailing: isSelected
                        ? Icon(
                            CupertinoIcons.checkmark,
                            color: colors.primary,
                            size: 20,
                          )
                        : null,
                    showChevron: false,
                    isFirst: index == 0,
                    isLast: index == sortOptions.length - 1,
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
    final orderedFolders = _applyCustomOrder(folders, customOrder);

    return SettingsGroup(
      header: 'Drag to Reorder',
      footer: 'Drag folders to set your preferred order. New folders will appear at the bottom.',
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.groupedListBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.groupedListBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: orderedFolders.length,
            itemBuilder: (context, index) {
              final folder = orderedFolders[index];
              final isFirst = index == 0;
              final isLast = index == orderedFolders.length - 1;

              return _DraggableFolderItem(
                key: ValueKey(folder.id),
                folder: folder,
                index: index,
                isFirst: isFirst,
                isLast: isLast,
              );
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = Tween<double>(begin: 0, end: 6).evaluate(animation);
                  return Material(
                    elevation: elevation,
                    color: colors.groupedListBackground,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  );
                },
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              _handleReorder(orderedFolders, oldIndex, newIndex);
            },
          ),
        ),
      ],
    );
  }

  List<RecipeFolderEntry> _applyCustomOrder(
    List<RecipeFolderEntry> folders,
    List<String> customOrder,
  ) {
    final orderedFolders = <RecipeFolderEntry>[];
    final folderMap = {for (var f in folders) f.id: f};

    // Add folders in custom order
    for (final id in customOrder) {
      if (folderMap.containsKey(id)) {
        orderedFolders.add(folderMap.remove(id)!);
      }
    }

    // Append remaining (new) folders at bottom
    orderedFolders.addAll(folderMap.values);

    return orderedFolders;
  }

  void _handleReorder(
    List<RecipeFolderEntry> orderedFolders,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Create new order list
    final newOrderedFolders = List<RecipeFolderEntry>.from(orderedFolders);
    final item = newOrderedFolders.removeAt(oldIndex);
    newOrderedFolders.insert(newIndex, item);

    // Extract IDs for the new order
    final newOrder = newOrderedFolders.map((f) => f.id).toList();

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

/// Draggable folder item for the custom order list
class _DraggableFolderItem extends StatelessWidget {
  final RecipeFolderEntry folder;
  final int index;
  final bool isFirst;
  final bool isLast;

  const _DraggableFolderItem({
    super.key,
    required this.folder,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isSmartFolder = (folder.folderType ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: colors.groupedListBorder,
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                color: colors.textTertiary,
                size: 20,
              ),
            ),
            SizedBox(width: AppSpacing.md),

            // Folder icon
            Icon(
              isSmartFolder ? CupertinoIcons.wand_stars : CupertinoIcons.folder,
              color: colors.primary,
              size: 22,
            ),
            SizedBox(width: AppSpacing.md),

            // Folder name
            Expanded(
              child: Text(
                folder.name,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
