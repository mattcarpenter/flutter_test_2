import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../utils/error_messages.dart';

void showCreateHouseholdModal(BuildContext context, Function(String name) onCreateHousehold) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      CreateHouseholdModalPage.build(
        context: bottomSheetContext,
        onCreateHousehold: onCreateHousehold,
      ),
    ],
  );
}

class CreateHouseholdModalPage {
  CreateHouseholdModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required Function(String name) onCreateHousehold,
  }) {
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
              context.l10n.householdCreateTitle,
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            CreateHouseholdForm(onCreateHousehold: onCreateHousehold),
          ],
        ),
      ),
    );
  }
}

class CreateHouseholdForm extends ConsumerStatefulWidget {
  final Function(String name) onCreateHousehold;

  const CreateHouseholdForm({
    super.key,
    required this.onCreateHousehold,
  });

  @override
  ConsumerState<CreateHouseholdForm> createState() => _CreateHouseholdFormState();
}

class _CreateHouseholdFormState extends ConsumerState<CreateHouseholdForm> {
  final _controller = TextEditingController();
  bool _isCreating = false;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateInput);
    _controller.dispose();
    super.dispose();
  }

  void _updateInput() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() {
        _hasInput = hasInput;
      });
    }
  }

  bool get _canSubmit => !_isCreating && _hasInput;

  void _createHousehold() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.onCreateHousehold(_controller.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        await SuccessDialog.show(
          context,
          message: context.l10n.householdCreatedSuccess(_controller.text.trim()),
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: HouseholdErrorMessages.getDisplayMessage(e.toString(), context.l10n),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.householdEnterName,
          style: AppTypography.body.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppTextFieldSimple(
          controller: _controller,
          placeholder: context.l10n.householdNamePlaceholder,
          autofocus: true,
          enabled: !_isCreating,
          onSubmitted: (_) => _createHousehold(),
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: AppSpacing.xl),
        AppButtonVariants.primaryFilled(
          text: context.l10n.householdCreateButton,
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          fullWidth: true,
          loading: _isCreating,
          onPressed: _canSubmit ? _createHousehold : null,
        ),
      ],
    );
  }
}
