import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'tag_selection_view_model.dart';
import 'tag_selection_pages.dart';

/// Show the multi-page tag selection modal
void showTagSelectionModal(
  BuildContext context, {
  required List<String> currentTagIds,
  required ValueChanged<List<String>> onTagIdsChanged,
  required WidgetRef ref,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalDecorator: (child) {
      return provider.ChangeNotifierProvider<TagSelectionViewModel>(
        create: (_) => TagSelectionViewModel(
          ref: ref,
          initialTagIds: currentTagIds,
          onTagIdsChanged: onTagIdsChanged,
        ),
        child: child,
      );
    },
    pageListBuilder: (bottomSheetContext) => [
      TagSelectionPage.build(bottomSheetContext),    // Page 0: Select tags
      CreateTagPage.build(bottomSheetContext),       // Page 1: Create new tag
    ],
  );
}

