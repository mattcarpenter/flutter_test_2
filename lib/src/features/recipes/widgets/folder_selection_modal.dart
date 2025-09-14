import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'folder_selection_view_model.dart';
import 'folder_selection_pages.dart';

/// Show the multi-page folder selection modal
void showFolderSelectionModal(
  BuildContext context, {
  required List<String> currentFolderIds,
  required ValueChanged<List<String>> onFolderIdsChanged,
  required WidgetRef ref,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalDecorator: (child) {
      return provider.ChangeNotifierProvider<FolderSelectionViewModel>(
        create: (_) => FolderSelectionViewModel(
          ref: ref,
          initialFolderIds: currentFolderIds,
          onFolderIdsChanged: onFolderIdsChanged,
        ),
        child: child,
      );
    },
    pageListBuilder: (bottomSheetContext) => [
      FolderSelectionPage.build(bottomSheetContext),    // Page 0: Select folders
      CreateFolderPage.build(bottomSheetContext),       // Page 1: Create new folder
    ],
  );
}
