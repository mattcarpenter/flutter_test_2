import 'package:flutter/cupertino.dart';
import '../models/household_member.dart';

class LeaveHouseholdModal extends StatefulWidget {
  final bool isOwner;
  final List<HouseholdMember> otherMembers;
  final Function(String? newOwnerId) onLeaveHousehold;

  const LeaveHouseholdModal({
    super.key,
    required this.isOwner,
    required this.otherMembers,
    required this.onLeaveHousehold,
  });

  @override
  State<LeaveHouseholdModal> createState() => _LeaveHouseholdModalState();
}

class _LeaveHouseholdModalState extends State<LeaveHouseholdModal> {
  HouseholdMember? _selectedNewOwner;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.otherMembers.isNotEmpty) {
      _selectedNewOwner = widget.otherMembers.first;
    }
  }

  void _leaveHousehold() async {
    if (widget.isOwner && _selectedNewOwner == null) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      await widget.onLeaveHousehold(_selectedNewOwner?.userId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error handling is done in the provider
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwner) {
      // Simple confirmation for non-owners
      return CupertinoAlertDialog(
        title: const Text('Leave Household'),
        content: const Text('Are you sure you want to leave this household?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: _leaveHousehold,
            child: const Text('Leave'),
          ),
        ],
      );
    }

    // Owner transfer modal
    return CupertinoActionSheet(
      title: const Text('Transfer Ownership'),
      message: const Text('As the owner, you must transfer ownership to another member before leaving.'),
      actions: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select new owner:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: CupertinoPicker(
                  itemExtent: 44,
                  onSelectedItemChanged: _isLeaving ? null : (index) {
                    setState(() {
                      _selectedNewOwner = widget.otherMembers[index];
                    });
                  },
                  children: widget.otherMembers.map((member) => Center(
                    child: Text(
                      member.userName ?? member.userId,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _isLeaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _isLeaving ? null : _leaveHousehold,
                      child: _isLeaving
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text('Transfer & Leave'),
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