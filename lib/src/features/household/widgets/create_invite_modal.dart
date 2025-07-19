import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
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
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Invite Member'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: CreateInviteForm(
          onCreateEmailInvite: onCreateEmailInvite,
          onCreateCodeInvite: onCreateCodeInvite,
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

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSegmentChanged(int? value) {
    if (value != null) {
      setState(() {
        _selectedSegment = value;
      });
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
          _showSuccessDialog('Invitation email has been sent!');
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
            message: HouseholdErrorMessages.getDisplayMessage(e.toString()),
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

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInviteCodeDialog(String inviteUrl) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Invite Code Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this URL with the person you want to invite:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                inviteUrl,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteUrl));
              Navigator.of(context).pop();
              _showSuccessDialog('Invite URL copied to clipboard!');
            },
            child: const Text('Copy & Close'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
        const Text(
          'Choose how to invite a new member',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedSegment,
          onValueChanged: _isCreating ? (_) {} : _handleSegmentChanged,
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Email'),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Code'),
            ),
          },
        ),
        const SizedBox(height: 24),
        if (_selectedSegment == 0) ...[
          CupertinoTextField(
            controller: _emailController,
            placeholder: 'Email address',
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            enabled: !_isCreating,
            onSubmitted: (_) => _createInvite(),
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 8),
          const Text(
            'An invitation email will be sent to this address',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 12,
            ),
          ),
        ] else ...[
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Display name',
            autofocus: true,
            enabled: !_isCreating,
            onSubmitted: (_) => _createInvite(),
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 8),
          const Text(
            'A shareable invitation code will be generated',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _isCreating
              ? const CupertinoButton(
                  onPressed: null,
                  child: CupertinoActivityIndicator(color: CupertinoColors.white),
                )
              : WoltElevatedButton(
                  onPressed: _createInvite,
                  child: Text(_selectedSegment == 0 ? 'Send Email' : 'Generate Code'),
                ),
        ),
      ],
    );
  }
}