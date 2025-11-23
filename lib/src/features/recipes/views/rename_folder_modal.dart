import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../providers/recipe_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';

/// Show the rename folder modal
Future<bool?> showRenameFolderModal(
  BuildContext context, {
  required String folderId,
  required String currentName,
}) {
  return WoltModalSheet.show<bool>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      _RenameFolderPage.build(
        context: bottomSheetContext,
        folderId: folderId,
        currentName: currentName,
      ),
    ],
  );
}

class _RenameFolderPage {
  _RenameFolderPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required String folderId,
    required String currentName,
  }) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: _RenameFolderContent(
        folderId: folderId,
        currentName: currentName,
      ),
    );
  }
}

class _RenameFolderContent extends ConsumerStatefulWidget {
  final String folderId;
  final String currentName;

  const _RenameFolderContent({
    required this.folderId,
    required this.currentName,
  });

  @override
  ConsumerState<_RenameFolderContent> createState() => _RenameFolderContentState();
}

class _RenameFolderContentState extends ConsumerState<_RenameFolderContent> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final newName = _nameController.text.trim();
    return newName.isNotEmpty && newName != widget.currentName;
  }

  Future<void> _saveChanges() async {
    if (!_canSave || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(recipeFolderNotifierProvider.notifier).renameFolder(
        widget.folderId,
        _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rename Folder',
            style: AppTypography.h4.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: AppSpacing.lg),

          // Name input
          AppTextFieldSimple(
            controller: _nameController,
            placeholder: 'Folder name',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),

          SizedBox(height: AppSpacing.xl),

          // Save button
          AppButtonVariants.primaryFilled(
            text: 'Rename',
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            loading: _isSaving,
            onPressed: _canSave ? _saveChanges : null,
          ),
        ],
      ),
    );
  }
}
