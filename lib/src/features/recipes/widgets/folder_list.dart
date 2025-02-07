// folder_list.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../models/recipe_folder.model.dart';
import '../../../repositories/base_repository.dart';

class FolderList extends ConsumerStatefulWidget {
  const FolderList({Key? key}) : super(key: key);

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
    BaseRepository().getAll<RecipeFolder>();
  }

  @override
  void dispose() {
    folderNameController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for folder changes and get repository for actions.
    final foldersAsyncValue = ref.watch(recipeFolderNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Folder list section.
          foldersAsyncValue.when(
            data: (folders) {
              if (folders.isEmpty) {
                return const Center(child: Text('No folders available'));
              }
              // Use a ListView that does not scroll on its own.
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
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
                        // Handle tap if needed.
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: ${error.toString()}')),
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
                      ref.read(recipeFolderNotifierProvider.notifier)
                          .addFolder(folderName);
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
