import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../features/settings/providers/app_settings_provider.dart';
import '../../../localization/l10n_extension.dart';
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
              // Create list with uncategorized folder included
              final uncategorizedFolder = _createUncategorizedFolder(context);

              // Apply sorting to all folders (including uncategorized)
              List<dynamic> allFolders = _applySortOrder(
                folders,
                uncategorizedFolder,
                folderSortOption,
                customFolderOrder,
              );

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
  VirtualFolder _createUncategorizedFolder(BuildContext context) {
    return VirtualFolder(
      id: kUncategorizedFolderId,
      name: context.l10n.folderUncategorized,
    );
  }

  /// Apply sort order to folders based on settings (includes uncategorized folder)
  List<dynamic> _applySortOrder(
    List<RecipeFolderEntry> folders,
    VirtualFolder uncategorizedFolder,
    String sortOption,
    List<String> customOrder,
  ) {
    switch (sortOption) {
      case 'alphabetical_asc':
        // Sort all folders including uncategorized by name A-Z
        final allFolders = <dynamic>[uncategorizedFolder, ...folders];
        allFolders.sort((a, b) {
          final nameA = a is VirtualFolder ? a.name : (a as RecipeFolderEntry).name;
          final nameB = b is VirtualFolder ? b.name : (b as RecipeFolderEntry).name;
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });
        return allFolders;

      case 'alphabetical_desc':
        // Sort all folders including uncategorized by name Z-A
        final allFolders = <dynamic>[uncategorizedFolder, ...folders];
        allFolders.sort((a, b) {
          final nameA = a is VirtualFolder ? a.name : (a as RecipeFolderEntry).name;
          final nameB = b is VirtualFolder ? b.name : (b as RecipeFolderEntry).name;
          return nameB.toLowerCase().compareTo(nameA.toLowerCase());
        });
        return allFolders;

      case 'newest':
        // Newest first: uncategorized has createdAt=0, so it goes last
        // Regular folders in reverse insertion order, uncategorized at end
        return [...folders.reversed, uncategorizedFolder];

      case 'oldest':
        // Oldest first: uncategorized has createdAt=0, so it goes first
        return [uncategorizedFolder, ...folders];

      case 'custom':
        return _applyCustomOrder(folders, uncategorizedFolder, customOrder);

      default:
        // Default to alphabetical A-Z
        final allFolders = <dynamic>[uncategorizedFolder, ...folders];
        allFolders.sort((a, b) {
          final nameA = a is VirtualFolder ? a.name : (a as RecipeFolderEntry).name;
          final nameB = b is VirtualFolder ? b.name : (b as RecipeFolderEntry).name;
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });
        return allFolders;
    }
  }

  /// Apply custom order based on saved folder ID list (includes uncategorized)
  List<dynamic> _applyCustomOrder(
    List<RecipeFolderEntry> folders,
    VirtualFolder uncategorizedFolder,
    List<String> customOrder,
  ) {
    final orderedFolders = <dynamic>[];
    final folderMap = <String, dynamic>{
      uncategorizedFolder.id: uncategorizedFolder,
      for (var f in folders) f.id: f,
    };

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

