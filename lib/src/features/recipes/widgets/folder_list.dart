import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/spacing.dart';
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

    // Get recipe counts for all folders
    final folderCounts = ref.watch(recipeFolderCountProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg), // 12px top, 16px bottom
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          foldersAsyncValue.when(
            data: (folders) {
              // Create a new list with regular folders plus the uncategorized folder
              final List<dynamic> allFolders = [
                // Add the virtual "Uncategorized" folder at the beginning
                _createUncategorizedFolder(),
                // Add the regular folders
                ...folders,
              ];

              // Use a simple responsive grid approach instead of WoltResponsiveLayoutGrid
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive configuration based on screen width
                  late final int columnCount;
                  late final double cardHeight;
                  late final double thumbnailSize;
                  
                  if (constraints.maxWidth < 600) {
                    // Mobile - larger thumbnails with minimal margins
                    columnCount = 2;
                    cardHeight = 70.0;
                    thumbnailSize = 58.0;  // Larger thumbnail, less margin
                  } else if (constraints.maxWidth < 900) {
                    // Large Mobile
                    columnCount = 3;
                    cardHeight = 90.0;
                    thumbnailSize = 78.0;  // Larger thumbnail, less margin
                  } else if (constraints.maxWidth < 1200) {
                    // iPad
                    columnCount = 4;
                    cardHeight = 100.0;
                    thumbnailSize = 88.0;  // Larger thumbnail, less margin
                  } else {
                    // Large/Desktop
                    columnCount = 5;
                    cardHeight = 110.0;
                    thumbnailSize = 98.0;  // Larger thumbnail, less margin
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
                        final count = folderCounts[regularFolder.id] ?? 0;
                        folderCardWidget = SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: FolderCard(
                            folderId: regularFolder.id,
                            folderName: regularFolder.name,
                            recipeCount: count,
                            thumbnailSize: thumbnailSize,
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
}

/// Class to represent a virtual folder (not stored in the database)
class VirtualFolder {
  final String id;
  final String name;

  VirtualFolder({required this.id, required this.name});
}

