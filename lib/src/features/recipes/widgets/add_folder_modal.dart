import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../models/recipe_folder.model.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../../../widgets/wolt/button/wolt_modal_sheet_back_button.dart';
import '../../../widgets/wolt/button/wolt_modal_sheet_close_button.dart';
import '../../../widgets/wolt/text/modal_sheet_subtitle.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

void showAddFolderModal(BuildContext context, {
  String? parentId,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddFolderModalPage.build(
        context: context,
        parentId: parentId,
        onFolderAdded: (String folderName) {
          // Get the provider container from the modal context.
          final container = ProviderScope.containerOf(bottomSheetContext);
          // Construct a RecipeFolder using the folderName and parentId.
          final folder = RecipeFolder(name: folderName, parentId: parentId);
          // Use the notifier to add the folder.
          container
              .read(recipeFolderNotifierProvider.notifier)
              .addFolder(folder);
          // Close the modal, optionally returning the folder name.
          Navigator.of(bottomSheetContext).pop(folderName);
        },
      ),
    ],
  );
}

class AddFolderModalPage {
  AddFolderModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    String? parentId, // Accept the parentId (for future use or display)
    required Function(String folderName) onFolderAdded,
  }) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController _folderNameController = TextEditingController();
    final ValueNotifier<bool> submitted = ValueNotifier<bool>(false);

    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? CupertinoTheme.of(context).barBackgroundColor : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      stickyActionBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel button closes modal.
            Expanded(
              child: WoltElevatedButton(
                theme: WoltElevatedButtonTheme.secondary,
                onPressed: () {
                  Navigator.of(_formKey.currentContext!).pop();
                },
                enabled: true,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            // Add button validates input.
            Expanded(
              child: WoltElevatedButton(
                onPressed: () {
                  if (_folderNameController.text.trim().isEmpty) {
                    submitted.value = true;
                    return;
                  }
                  onFolderAdded(_folderNameController.text.trim());
                },
                enabled: true,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
      pageTitle: const ModalSheetTitle('New Folder'),
      trailingNavBarWidget: const WoltModalSheetCloseButton(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoTextField(
              controller: _folderNameController,
              placeholder: "Enter folder name",
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (value) {
                // If user types something, clear the error.
                if (value.trim().isNotEmpty && submitted.value) {
                  submitted.value = false;
                }
              },
            ),
            const SizedBox(height: 8),
            // Fixed-height container for error message.
            Container(
              height: 28,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 8),
              child: ValueListenableBuilder<bool>(
                valueListenable: submitted,
                builder: (context, hasSubmitted, child) {
                  return Text(
                    hasSubmitted && _folderNameController.text.trim().isEmpty
                        ? "Folder name is required"
                        : " ", // Placeholder to reserve space.
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
