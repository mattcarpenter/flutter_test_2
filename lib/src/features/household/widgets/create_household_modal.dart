import 'package:flutter/cupertino.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../utils/error_messages.dart';

class CreateHouseholdModal extends StatefulWidget {
  final Function(String name) onCreateHousehold;

  const CreateHouseholdModal({
    super.key,
    required this.onCreateHousehold,
  });

  @override
  State<CreateHouseholdModal> createState() => _CreateHouseholdModalState();
}

class _CreateHouseholdModalState extends State<CreateHouseholdModal> {
  final _controller = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createHousehold() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.onCreateHousehold(_controller.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        // Show success dialog for this major operation
        await SuccessDialog.show(
          context,
          message: 'Household "${_controller.text.trim()}" has been created successfully!',
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
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Create Household'),
      message: const Text('Enter a name for your household'),
      actions: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _controller,
                placeholder: 'Household name',
                autofocus: true,
                enabled: !_isCreating,
                onSubmitted: (_) => _createHousehold(),
              ),
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
                      onPressed: _isCreating ? null : _createHousehold,
                      child: _isCreating
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text('Create'),
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