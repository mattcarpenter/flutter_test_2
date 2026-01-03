import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void showCreateInviteModal(
  BuildContext context,
  Future<String?> Function(String email) onCreateEmailInvite,
  Future<String?> Function(String displayName) onCreateCodeInvite,
) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      CreateInviteModalPage.build(
        context: bottomSheetContext,
        onCreateEmailInvite: onCreateEmailInvite,
        onCreateCodeInvite: onCreateCodeInvite,
      ),
    ],
  );
}

class CreateInviteModalPage {
  CreateInviteModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required Future<String?> Function(String email) onCreateEmailInvite,
    required Future<String?> Function(String displayName) onCreateCodeInvite,
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
              context.l10n.householdInviteMemberTitle,
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            CreateInviteForm(
              onCreateEmailInvite: onCreateEmailInvite,
              onCreateCodeInvite: onCreateCodeInvite,
            ),
          ],
        ),
      ),
    );
  }
}

class CreateInviteForm extends ConsumerStatefulWidget {
  final Future<String?> Function(String email) onCreateEmailInvite;
  final Future<String?> Function(String displayName) onCreateCodeInvite;

  const CreateInviteForm({
    super.key,
    required this.onCreateEmailInvite,
    required this.onCreateCodeInvite,
  });

  @override
  ConsumerState<CreateInviteForm> createState() => _CreateInviteFormState();
}

class _CreateInviteFormState extends ConsumerState<CreateInviteForm> {
  int _selectedSegment = 0;
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isCreating = false;
  bool _hasEmailInput = false;
  bool _hasNameInput = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateEmailInput);
    _nameController.addListener(_updateNameInput);
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateEmailInput);
    _nameController.removeListener(_updateNameInput);
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateEmailInput() {
    final hasInput = _emailController.text.trim().isNotEmpty;
    if (hasInput != _hasEmailInput) {
      setState(() {
        _hasEmailInput = hasInput;
      });
    }
  }

  void _updateNameInput() {
    final hasInput = _nameController.text.trim().isNotEmpty;
    if (hasInput != _hasNameInput) {
      setState(() {
        _hasNameInput = hasInput;
      });
    }
  }

  void _handleSegmentChanged(int? value) {
    if (value != null) {
      setState(() {
        _selectedSegment = value;
      });
    }
  }

  bool get _canSubmit {
    if (_isCreating) return false;
    if (_selectedSegment == 0) {
      return _hasEmailInput;
    } else {
      return _hasNameInput;
    }
  }

  void _createInvite() async {
    if (_selectedSegment == 0) {
      // Email invite
      if (_emailController.text.trim().isEmpty) return;

      setState(() {
        _isCreating = true;
      });

      try {
        await widget.onCreateEmailInvite(_emailController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
          await SuccessDialog.show(
            context,
            message: context.l10n.householdInviteSentSuccess,
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
    } else {
      // Code invite
      if (_nameController.text.trim().isEmpty) return;

      setState(() {
        _isCreating = true;
      });

      try {
        final inviteUrl = await widget.onCreateCodeInvite(_nameController.text.trim());
        if (mounted && inviteUrl != null) {
          Navigator.of(context).pop();
          _showInviteCodeDialog(inviteUrl);
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
  }

  void _showInviteCodeDialog(String inviteUrl) {
    final l10n = context.l10n;
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.householdInviteCodeCreatedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.householdShareInviteUrl),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.of(dialogContext).surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                inviteUrl,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.of(dialogContext).textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteUrl));
              Navigator.of(dialogContext).pop();
              SuccessDialog.show(
                context,
                message: l10n.householdInviteCopiedSuccess,
              );
            },
            child: Text(l10n.householdCopyCloseButton),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.householdChooseInviteMethod,
          style: AppTypography.body.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedSegment,
          onValueChanged: _isCreating ? (_) {} : _handleSegmentChanged,
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(context.l10n.householdInviteEmail),
            ),
            1: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(context.l10n.householdInviteCode),
            ),
          },
        ),
        SizedBox(height: AppSpacing.xl),
        if (_selectedSegment == 0) ...[
          AppTextFieldSimple(
            controller: _emailController,
            placeholder: context.l10n.householdEmailPlaceholder,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofocus: true,
            enabled: !_isCreating,
            onSubmitted: (_) => _createInvite(),
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.householdEmailInviteDescription,
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textTertiary,
            ),
          ),
        ] else ...[
          AppTextFieldSimple(
            controller: _nameController,
            placeholder: context.l10n.householdDisplayNamePlaceholder,
            autofocus: true,
            enabled: !_isCreating,
            onSubmitted: (_) => _createInvite(),
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.householdCodeInviteDescription,
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textTertiary,
            ),
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        AppButtonVariants.primaryFilled(
          text: _selectedSegment == 0 ? context.l10n.householdSendInvitationButton : context.l10n.householdGenerateCodeButton,
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          fullWidth: true,
          loading: _isCreating,
          onPressed: _canSubmit ? _createInvite : null,
        ),
      ],
    );
  }
}
