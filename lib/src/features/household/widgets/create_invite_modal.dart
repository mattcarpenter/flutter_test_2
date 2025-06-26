import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CreateInviteModal extends StatefulWidget {
  final Future<String?> Function(String email) onCreateEmailInvite;
  final Future<String?> Function(String displayName) onCreateCodeInvite;

  const CreateInviteModal({
    super.key,
    required this.onCreateEmailInvite,
    required this.onCreateCodeInvite,
  });

  @override
  State<CreateInviteModal> createState() => _CreateInviteModalState();
}

class _CreateInviteModalState extends State<CreateInviteModal> {
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
        print('INVITE MODAL: Creating email invite for: ${_emailController.text.trim()}');
        final result = await widget.onCreateEmailInvite(_emailController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
          if (result != null) {
            _showSuccessDialog('Email invite sent successfully!');
          }
        }
      } catch (e) {
        print('INVITE MODAL: Error creating email invite: $e');
        if (mounted) {
          _showErrorDialog('Failed to create email invite: $e');
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
        print('INVITE MODAL: Creating code invite for: ${_nameController.text.trim()}');
        final inviteUrl = await widget.onCreateCodeInvite(_nameController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
          if (inviteUrl != null) {
            _showInviteCodeDialog(inviteUrl);
          } else {
            _showErrorDialog('Failed to create invite code - no URL returned');
          }
        }
      } catch (e) {
        print('INVITE MODAL: Error creating code invite: $e');
        if (mounted) {
          _showErrorDialog('Failed to create invite code: $e');
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

  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(error),
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
    return CupertinoActionSheet(
      title: const Text('Invite Member'),
      message: const Text('Choose how to invite a new member'),
      actions: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
              const SizedBox(height: 16),
              if (_selectedSegment == 0) ...[
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  enabled: !_isCreating,
                  onSubmitted: (_) => _createInvite(),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _isCreating ? null : _createInvite,
                      child: _isCreating
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Text(_selectedSegment == 0 ? 'Send Email' : 'Generate Code'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}