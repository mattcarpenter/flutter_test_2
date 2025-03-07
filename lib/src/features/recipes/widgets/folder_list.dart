import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../widgets/folder_tile.dart';  // Import the FolderTile widget

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
    // Ensure we load data from SQLite.
    //final baseRepository = ref.read(baseRepositoryProvider);
    //baseRepository.getAll<RecipeFolder>();
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          foldersAsyncValue.when(
            data: (folders) {
              // Filter folders: if widget.parentId is null, we show root folders.
              final filteredFolders = folders.toList();

              if (filteredFolders.isEmpty) {
                return const Center(child: Text('No folders available'));
              }

              return GridView.builder(
                clipBehavior: Clip.none,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const FixedFolderGridDelegate(
                  tileSize: 120, // Fixed size
                  spacing: 2,
                ),
                itemCount: filteredFolders.length,
                itemBuilder: (context, index) {
                  final folder = filteredFolders[index];
                  // Remove the Center wrapper so FolderTile fills the cell.
                  return FolderTile(
                    folderName: folder.name,
                    recipeCount: 0, // Replace with actual count if available.
                    onTap: () {
                      context.push('/recipes/folder/${folder.id}', extra: {
                        'folderTitle': folder.name,
                        'previousPageTitle': widget.currentPageTitle,
                      });
                    },
                    onDelete: () {
                      ref
                          .read(recipeFolderNotifierProvider.notifier)
                          .deleteFolder(folder.id);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: ${error.toString()}')),
          ),
          // Input field and add button.
          /*Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    focusNode: textFieldFocusNode,
                    controller: folderNameController,
                    placeholder: 'Enter folder name',
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton.filled(
                  onPressed: () {
                    final folderName = folderNameController.text.trim();
                    if (folderName.isNotEmpty) {
                      // Create a new folder using the widget.parentId.
                      final newFolder = RecipeFolder.create(
                        folderName,
                        parentId: widget.parentId,
                      );
                      // Pass the whole folder object to the notifier.
                      ref
                          .read(recipeFolderNotifierProvider.notifier)
                          .addFolder(newFolder);
                      folderNameController.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),*/
        ],
      ),
    );
  }
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
