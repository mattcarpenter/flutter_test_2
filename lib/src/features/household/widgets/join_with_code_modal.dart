import 'package:flutter/cupertino.dart';

class JoinWithCodeModal extends StatefulWidget {
  final Function(String inviteCode) onAcceptInvite;

  const JoinWithCodeModal({
    super.key,
    required this.onAcceptInvite,
  });

  @override
  State<JoinWithCodeModal> createState() => _JoinWithCodeModalState();
}

class _JoinWithCodeModalState extends State<JoinWithCodeModal> {
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
      }
    } catch (e) {
      // Error handling is done in the provider
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
    return CupertinoActionSheet(
      title: const Text('Join Household'),
      message: const Text('Enter the invitation code'),
      actions: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _controller,
                placeholder: 'Invitation code',
                autofocus: true,
                enabled: !_isJoining,
                onSubmitted: (_) => _joinHousehold(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _isJoining ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _isJoining ? null : _joinHousehold,
                      child: _isJoining
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text('Join'),
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