import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../widgets/folder_tile.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 0),
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

              return GridView.builder(
                clipBehavior: Clip.none,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const FixedFolderGridDelegate(
                  tileSize: 120, // Fixed size
                  spacing: 2,
                ),
                itemCount: allFolders.length,
                itemBuilder: (context, index) {
                  final folder = allFolders[index];

                  // Special handling for uncategorized folder
                  if (folder is VirtualFolder) {
                    final count = folderCounts[folder.id] ?? 0;
                    return FolderTile(
                      folderName: folder.name,
                      recipeCount: count,
                      onTap: () {
                        context.push('/recipes/folder/${folder.id}', extra: {
                          'folderTitle': folder.name,
                          'previousPageTitle': widget.currentPageTitle,
                        });
                      },
                      // No delete option for uncategorized folder
                      onDelete: () {},
                    );
                  }

                  // Regular folder handling
                  final regularFolder = folder as RecipeFolderEntry;
                  final count = folderCounts[regularFolder.id] ?? 0;
                  return FolderTile(
                    folderName: regularFolder.name,
                    recipeCount: count,
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

class FixedFolderGridDelegate extends SliverGridDelegate {
  final double tileSize; // Fixed size for both width and height
  final double spacing;

  const FixedFolderGridDelegate({
    this.tileSize = 120,
    this.spacing = 8,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final availableWidth = constraints.crossAxisExtent;

    final int columnCount =
    ((availableWidth + spacing) / (tileSize + spacing)).floor().clamp(1, double.infinity).toInt();

    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileSize + spacing,
      crossAxisStride: tileSize + spacing,
      childMainAxisExtent: tileSize,
      childCrossAxisExtent: tileSize,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(FixedFolderGridDelegate oldDelegate) =>
      tileSize != oldDelegate.tileSize || spacing != oldDelegate.spacing;
}
