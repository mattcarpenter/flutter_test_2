import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../localization/l10n_extension.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../theme/typography.dart';

Future<String?> showAddFolderModal(BuildContext context) {
  return WoltModalSheet.show<String>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddFolderModalPage.build(
        context: bottomSheetContext,
        onFolderAdded: (String folderName) async {
          // Get the provider container from the modal context.
          final container = ProviderScope.containerOf(bottomSheetContext);
          // Construct a RecipeFolder using the folderName.
          final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

          // Use the notifier to add the folder.
          await container
              .read(recipeFolderNotifierProvider.notifier)
              .addFolder(name: folderName, userId: userId);
          // Close the modal, optionally returning the folder name.
          if (bottomSheetContext.mounted) {
            Navigator.of(bottomSheetContext).pop(folderName);
          }
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
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.recipeFolderNew,
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            AddFolderForm(
              controller: folderNameController,
              onSubmitted: onFolderAdded,
            ),
            SizedBox(height: AppSpacing.sm),
          ],
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
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    // Check if there's initial text
    _hasInput = widget.controller.text.trim().isNotEmpty;
    // Listen to text changes
    widget.controller.addListener(_updateHasInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasInput);
    widget.controller.dispose();
    super.dispose();
  }

  void _updateHasInput() {
    final hasInput = widget.controller.text.trim().isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() {
        _hasInput = hasInput;
      });
    }
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
        AppTextFieldSimple(
          controller: widget.controller,
          placeholder: context.l10n.recipeFolderEnterName,
          autofocus: true,
          enabled: !_isCreating,
          onChanged: _onTextChanged,
          onSubmitted: (_) => _submitForm(),
          textInputAction: TextInputAction.done,
          errorText: _showError ? context.l10n.recipeFolderNameRequired : null,
        ),
        SizedBox(height: AppSpacing.lg),
        AppButtonVariants.primaryFilled(
          text: context.l10n.recipeFolderCreateNew,
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          onPressed: (_isCreating || !_hasInput) ? null : _submitForm,
          loading: _isCreating,
          fullWidth: true,
        ),
      ],
    );
  }
}
