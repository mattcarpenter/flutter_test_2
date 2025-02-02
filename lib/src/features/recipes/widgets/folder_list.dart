// folder_list.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../models/recipe_folder.model.dart';

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
  }

  @override
  void dispose() {
    folderNameController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the stream of folders
    final foldersAsyncValue = ref.watch(recipeFolderStreamProvider);
    // Get the repository for add/delete actions
    final repository = ref.watch(recipeFolderRepositoryProvider);

    return Column(
      children: [
        Expanded(
          child: foldersAsyncValue.when(
            data: (folders) {
              if (folders.isEmpty) {
                return const Center(child: Text('No folders available'));
              }
              return ListView.builder(
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return Card(
                    child: ListTile(
                      title: Text(folder.name),
                      subtitle: folder.parentId != null
                          ? Text('Parent: ${folder.parentId}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => repository.deleteFolder(folder),
                      ),
                      onTap: () {
                        // Handle tap if needed
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
        ),
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
                    // Create a new RecipeFolder model
                    final newFolder = RecipeFolder.create(folderName);
                    // Call the repository; the stream will update when done.
                    repository.addFolder(newFolder);
                    folderNameController.clear();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
