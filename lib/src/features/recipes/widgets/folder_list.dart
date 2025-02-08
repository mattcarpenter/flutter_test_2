import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../models/recipe_folder.model.dart';

class FolderList extends ConsumerStatefulWidget {
  /// Optional parent folder id. If null, this list shows root folders.
  final String? parentId;
  /// The title of the current page (e.g. the name of the current folder).
  final String currentPageTitle;

  const FolderList({Key? key, this.parentId, required this.currentPageTitle})
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
    // Watch for folder changes using StateNotifierProvider.
    final foldersAsyncValue = ref.watch(recipeFolderNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          foldersAsyncValue.when(
            data: (folders) {
              print(folders);
              // Filter folders: if widget.parentId is null, we only show folders with no parent.
              final filteredFolders = folders
                  .where((folder) => folder.parentId == widget.parentId)
                  .toList();

              if (filteredFolders.isEmpty) {
                return const Center(child: Text('No folders available'));
              }
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredFolders.length,
                itemBuilder: (context, index) {
                  final folder = filteredFolders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(folder.name),
                      subtitle: folder.parentId != null
                          ? Text('Parent: ${folder.parentId}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => ref
                            .read(recipeFolderNotifierProvider.notifier)
                            .deleteFolder(folder),
                      ),
                      onTap: () {
                        // When tapped, navigate to a new folder page.
                        // The new page should use the tapped folder's name as its title,
                        // and the back button should display the current page's title.
                        context.push(
                          '/recipes/folder/${folder.id}',
                          extra: {
                            'folderTitle': folder.name, // New page title.
                            'previousPageTitle': widget.currentPageTitle, // Back button shows current page title.
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: ${error.toString()}')),
          ),
          // Input field and add button.
          Padding(
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
          ),
        ],
      ),
    );
  }
}
