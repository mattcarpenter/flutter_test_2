import 'package:flutter/cupertino.dart';

class CreateInviteModal extends StatefulWidget {
  final Function(String email) onCreateEmailInvite;
  final Function(String displayName) onCreateCodeInvite;

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
        await widget.onCreateEmailInvite(_emailController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Error handling is done in the provider
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
        await widget.onCreateCodeInvite(_nameController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Error handling is done in the provider
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
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