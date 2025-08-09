import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../theme/colors.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../utils/error_messages.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Join Household'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          message: 'You have successfully joined the household!',
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: HouseholdErrorMessages.getDisplayMessage(e.toString()),
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
        const Text(
          'Enter the invitation code',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _controller,
          placeholder: 'Invitation code',
          autofocus: true,
          enabled: !_isJoining,
          onSubmitted: (_) => _joinHousehold(),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _isJoining
              ? const CupertinoButton(
                  onPressed: null,
                  child: CupertinoActivityIndicator(color: CupertinoColors.white),
                )
              : WoltElevatedButton(
                  onPressed: _joinHousehold,
                  child: const Text('Join Household'),
                ),
        ),
      ],
    );
  }
}