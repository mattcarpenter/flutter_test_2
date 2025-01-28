import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../models/recipe_folder.dart';

class FolderList extends ConsumerStatefulWidget {
  const FolderList({super.key});

  @override
  ConsumerState<FolderList> createState() => _FolderListState();
}

class _FolderListState extends ConsumerState<FolderList> {

  final TextEditingController folderNameController = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(recipeFolderNotifierProvider);
    final folderNotifier = ref.read(recipeFolderNotifierProvider.notifier);

    return Column(
      children: [
        // List of folders
        Expanded(
          child: folders.isEmpty
              ? const Center(child: Text('No folders available'))
              : ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Card(
                child: ListTile(
                  title: Text(folder.name),
                  subtitle: folder.parentId != null
                      ? Text('Parent: ${folder.parentId}')
                      : null,
                  onTap: () {
                    // Handle tap (no action for now)
                  },
                ),
              );
            },
          ),
        ),
        // Input for adding folders
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
                    folderNotifier.addFolder(
                      RecipeFolder.newFolder(folderName),
                    );
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
