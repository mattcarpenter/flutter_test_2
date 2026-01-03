import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../utils/error_messages.dart';
import '../../../services/logging/app_logger.dart';

void showJoinWithCodeModal(BuildContext context, Function(String inviteCode) onAcceptInvite) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      JoinWithCodeModalPage.build(
        context: bottomSheetContext,
        onAcceptInvite: onAcceptInvite,
      ),
    ],
  );
}

class JoinWithCodeModalPage {
  JoinWithCodeModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required Function(String inviteCode) onAcceptInvite,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      leadingNavBarWidget: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(context.l10n.commonCancel),
      ),
      pageTitle: ModalSheetTitle(context.l10n.householdJoinTitle),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: JoinWithCodeForm(onAcceptInvite: onAcceptInvite),
      ),
    );
  }
}

class JoinWithCodeForm extends ConsumerStatefulWidget {
  final Function(String inviteCode) onAcceptInvite;

  const JoinWithCodeForm({
    super.key,
    required this.onAcceptInvite,
  });

  @override
  ConsumerState<JoinWithCodeForm> createState() => _JoinWithCodeFormState();
}

class _JoinWithCodeFormState extends ConsumerState<JoinWithCodeForm> {
  final _controller = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _joinHousehold() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await widget.onAcceptInvite(_controller.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        // Show success dialog for this major operation
        await SuccessDialog.show(
          context,
          message: context.l10n.householdJoinedSuccess,
        );
      }
    } catch (e) {
      AppLogger.warning('Join household with code failed', e);
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: HouseholdErrorMessages.getDisplayMessage(e.toString(), context.l10n),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
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
          context.l10n.householdEnterInviteCode,
          style: AppTypography.body.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        CupertinoTextField(
          controller: _controller,
          placeholder: context.l10n.householdInviteCodePlaceholder,
          autofocus: true,
          enabled: !_isJoining,
          onSubmitted: (_) => _joinHousehold(),
          padding: EdgeInsets.all(AppSpacing.md),
        ),
        SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: _isJoining
              ? const CupertinoButton(
                  onPressed: null,
                  child: CupertinoActivityIndicator(color: CupertinoColors.white),
                )
              : WoltElevatedButton(
                  onPressed: _joinHousehold,
                  child: Text(context.l10n.householdJoinButton),
                ),
        ),
      ],
    );
  }
}