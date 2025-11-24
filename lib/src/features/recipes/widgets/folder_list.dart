import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../features/settings/providers/app_settings_provider.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../providers/smart_folder_provider.dart';
import '../../../theme/spacing.dart';
import '../views/edit_smart_folder_modal.dart';
import '../views/rename_folder_modal.dart';
import 'folder_card.dart';

class FolderList extends ConsumerStatefulWidget {
  /// The title of the current page (e.g. the name of the current folder).
  final String currentPageTitle;

  const FolderList({Key? key, required this.currentPageTitle})
      : super(key: key);

  @override
  ConsumerState<FolderList> createState() => _FolderListState();
}

class _FolderListState extends ConsumerState<FolderList> {
  late final TextEditingController folderNameController;
  late final FocusNode textFieldFocusNode;

  @override
  void initState() {
    super.initState();
    folderNameController = TextEditingController();
    textFieldFocusNode = FocusNode();
  }

  @override
  void dispose() {
    folderNameController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for folder changes using the StateNotifierProvider.
    final foldersAsyncValue = ref.watch(recipeFolderNotifierProvider);

    // Get recipe counts for all folders (normal folders counted by assignment)
    final folderCounts = ref.watch(recipeFolderCountProvider);

    // Get recipe counts for smart folders (counted by matching criteria)
    final smartFolderCountsAsync = ref.watch(smartFolderCountsProvider);
    final smartFolderCounts = smartFolderCountsAsync.valueOrNull ?? {};

    // Get folder display settings
    final folderSortOption = ref.watch(folderSortOptionProvider);
    final customFolderOrder = ref.watch(customFolderOrderProvider);
    final showFolders = ref.watch(showFoldersProvider);
    final showFoldersCount = ref.watch(showFoldersCountProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg), // 12px top, 16px bottom
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          foldersAsyncValue.when(
            data: (folders) {
              // Apply sorting to folders
              final sortedFolders = _applySortOrder(folders, folderSortOption, customFolderOrder);

              // Create a new list with uncategorized folder plus sorted regular folders
              List<dynamic> allFolders = [
                // Add the virtual "Uncategorized" folder at the beginning
                _createUncategorizedFolder(),
                // Add the sorted regular folders
                ...sortedFolders,
              ];

              // Apply folder limit if set to 'firstN'
              if (showFolders == 'firstN' && allFolders.length > showFoldersCount) {
                allFolders = allFolders.take(showFoldersCount).toList();
              }

              // Use a simple responsive grid approach instead of WoltResponsiveLayoutGrid
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive configuration based on screen width
                  late final int columnCount;
                  late final double cardHeight;
                  late final double thumbnailSize;
                  
                  if (constraints.maxWidth < 600) {
                    // Mobile - shorter cards with smaller square thumbnails
                    columnCount = 2;
                    cardHeight = 70.0;
                    thumbnailSize = 46.0;  // Reduced for equal margins
                  } else if (constraints.maxWidth < 900) {
                    // Large Mobile
                    columnCount = 3;
                    cardHeight = 90.0;
                    thumbnailSize = 66.0;  // Reduced for equal margins
                  } else if (constraints.maxWidth < 1200) {
                    // iPad
                    columnCount = 4;
                    cardHeight = 100.0;
                    thumbnailSize = 76.0;  // Reduced for equal margins
                  } else {
                    // Large/Desktop
                    columnCount = 5;
                    cardHeight = 110.0;
                    thumbnailSize = 86.0;  // Reduced for equal margins
                  }

                  final spacing = 12.0;
                  final horizontalMargin = 16.0;
                  final availableWidth = constraints.maxWidth - (spacing * (columnCount - 1)) - (horizontalMargin * 2);
                  final cardWidth = availableWidth / columnCount;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                    children: allFolders.map<Widget>((folder) {
                      Widget folderCardWidget;
                      
                      // Special handling for uncategorized folder
                      if (folder is VirtualFolder) {
                        final count = folderCounts[folder.id] ?? 0;
                        folderCardWidget = SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: FolderCard(
                            folderId: folder.id,
                            folderName: folder.name,
                            recipeCount: count,
                            thumbnailSize: thumbnailSize,
                            onTap: () {
                              context.push('/recipes/folder/${folder.id}', extra: {
                                'folderTitle': folder.name,
                                'previousPageTitle': widget.currentPageTitle,
                              });
                            },
                            // No delete option for uncategorized folder
                            onDelete: () {},
                          ),
                        );
                      } else {
                        // Regular folder handling
                        final regularFolder = folder as RecipeFolderEntry;
                        final isSmartFolder = regularFolder.folderType != 0;
                        // Use smart folder counts for smart folders, normal folder counts otherwise
                        final count = isSmartFolder
                            ? (smartFolderCounts[regularFolder.id] ?? 0)
                            : (folderCounts[regularFolder.id] ?? 0);

                        folderCardWidget = SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: FolderCard(
                            folderId: regularFolder.id,
                            folderName: regularFolder.name,
                            recipeCount: count,
                            thumbnailSize: thumbnailSize,
                            folderType: regularFolder.folderType,
                            onTap: () {
                              context.push('/recipes/folder/${regularFolder.id}', extra: {
                                'folderTitle': regularFolder.name,
                                'previousPageTitle': widget.currentPageTitle,
                              });
                            },
                            onDelete: () {
                              ref
                                  .read(recipeFolderNotifierProvider.notifier)
                                  .deleteFolder(regularFolder.id);
                            },
                            // Pass edit callback for smart folders
                            onEdit: isSmartFolder
                                ? () => showEditSmartFolderModal(context, regularFolder)
                                : null,
                            // Pass rename callback for all folders
                            onRename: () => showRenameFolderModal(
                              context,
                              folderId: regularFolder.id,
                              currentName: regularFolder.name,
                            ),
                          ),
                        );
                      }

                      return folderCardWidget;
                    }).toList(),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: ${error.toString()}')),
          ),
        ],
      ),
    );
  }

  // Helper method to create the uncategorized virtual folder
  VirtualFolder _createUncategorizedFolder() {
    return VirtualFolder(
      id: kUncategorizedFolderId,
      name: kUncategorizedFolderName,
    );
  }

  /// Apply sort order to folders based on settings
  List<RecipeFolderEntry> _applySortOrder(
    List<RecipeFolderEntry> folders,
    String sortOption,
    List<String> customOrder,
  ) {
    // Create a mutable copy
    final sortedFolders = List<RecipeFolderEntry>.from(folders);

    switch (sortOption) {
      case 'alphabetical_asc':
        sortedFolders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'alphabetical_desc':
        sortedFolders.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'newest':
        // Note: RecipeFolderEntry doesn't have createdAt, so newest uses insertion order (no change)
        // Folders are returned from DB in insertion order, so we reverse for newest first
        return sortedFolders.reversed.toList();
      case 'oldest':
        // Oldest = original insertion order (no change needed)
        break;
      case 'custom':
        return _applyCustomOrder(sortedFolders, customOrder);
      default:
        // Default to alphabetical A-Z
        sortedFolders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return sortedFolders;
  }

  /// Apply custom order based on saved folder ID list
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
}

/// Class to represent a virtual folder (not stored in the database)
class VirtualFolder {
  final String id;
  final String name;

  VirtualFolder({required this.id, required this.name});
}

