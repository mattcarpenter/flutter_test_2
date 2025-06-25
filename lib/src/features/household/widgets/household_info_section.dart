import 'package:flutter/cupertino.dart';
import '../../../../database/database.dart';

class HouseholdInfoSection extends StatelessWidget {
  final HouseholdEntry household;

  const HouseholdInfoSection({
    super.key,
    required this.household,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.house_fill,
                color: CupertinoTheme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  household.name,
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Household ID: ${household.id}',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}