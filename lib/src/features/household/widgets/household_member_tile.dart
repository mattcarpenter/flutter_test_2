import 'package:flutter/cupertino.dart';
import '../models/household_member.dart';

class HouseholdMemberTile extends StatelessWidget {
  final HouseholdMember member;
  final bool isCurrentUser;
  final bool canRemove;
  final VoidCallback? onRemove;

  const HouseholdMemberTile({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.canRemove,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
              ? CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.3)
              : CupertinoColors.separator,
          width: isCurrentUser ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.userName ?? member.userEmail ?? member.userId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      const Text(
                        '(You)',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildRoleBadge(),
                    const Spacer(),
                    Text(
                      'Joined ${_formatDate(member.joinedAt)}',
                      style: const TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canRemove && onRemove != null) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () => _showRemoveConfirmation(context),
              child: const Icon(
                CupertinoIcons.minus_circle,
                color: CupertinoColors.destructiveRed,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          (member.userName ?? member.userEmail ?? member.userId).substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoTheme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color color;
    IconData icon;
    String text;
    
    switch (member.role) {
      case HouseholdRole.owner:
        color = CupertinoColors.systemYellow;
        icon = CupertinoIcons.star_circle;
        text = 'Owner';
        break;
      case HouseholdRole.member:
        color = CupertinoColors.systemGreen;
        icon = CupertinoIcons.person;
        text = 'Member';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.userName ?? member.userEmail ?? member.userId} from the household?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onRemove?.call();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}