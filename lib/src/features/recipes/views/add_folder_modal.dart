import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../providers/recipe_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../theme/typography.dart';

void showAddFolderModal(BuildContext context) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddFolderModalPage.build(
        context: context,
        onFolderAdded: (String folderName) {
          // Get the provider container from the modal context.
          final container = ProviderScope.containerOf(bottomSheetContext);
          // Construct a RecipeFolder using the folderName.
          final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

          // Use the notifier to add the folder.
          container
              .read(recipeFolderNotifierProvider.notifier)
              .addFolder(name: folderName, userId: userId);
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
    required Function(String folderName) onFolderAdded,
  }) {
    final TextEditingController folderNameController = TextEditingController();
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: true,
      topBarTitle: Text(
        'New Recipe Folder',
        style: AppTypography.h5.copyWith(
          color: AppColors.of(context).textPrimary,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        child: AddFolderForm(
          controller: folderNameController,
          onSubmitted: onFolderAdded,
        ),
      ),
    );
  }
}

class AddFolderForm extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String folderName) onSubmitted;

  const AddFolderForm({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  ConsumerState<AddFolderForm> createState() => _AddFolderFormState();
}

class _AddFolderFormState extends ConsumerState<AddFolderForm> {
  bool _isCreating = false;
  bool _showError = false;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  void _submitForm() async {
    final folderName = widget.controller.text.trim();
    if (folderName.isEmpty) {
      setState(() {
        _showError = true;
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _showError = false;
    });

    try {
      widget.onSubmitted(folderName);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _onTextChanged(String value) {
    // Clear error when user starts typing
    if (_showError && value.trim().isNotEmpty) {
      setState(() {
        _showError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: widget.controller,
          placeholder: 'Enter folder name',
          autofocus: true,
          enabled: !_isCreating,
          onChanged: _onTextChanged,
          onSubmitted: (_) => _submitForm(),
          textInputAction: TextInputAction.done,
        ),
        if (_showError) ...[
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg),
            child: Text(
              'Folder name is required',
              style: AppTypography.fieldError.copyWith(
                color: AppColors.of(context).error,
              ),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButtonVariants.mutedOutline(
                text: 'Cancel',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                onPressed: _isCreating ? null : () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButtonVariants.primaryFilled(
                text: 'Add',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                onPressed: _isCreating ? null : _submitForm,
                loading: _isCreating,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
