import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

void showAddToShoppingListModal(BuildContext context, String date) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      AddToShoppingListModalPage.build(
        context: modalContext,
        date: date,
      ),
    ],
  );
}

class AddToShoppingListModalPage {
  AddToShoppingListModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
      pageTitle: const ModalSheetTitle('Add to Shopping List'),
      child: AddToShoppingListContent(date: date),
    );
  }
}

class AddToShoppingListContent extends ConsumerWidget {
  final String date;

  const AddToShoppingListContent({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.cart_badge_plus,
            size: 64,
            color: CupertinoColors.activeBlue.resolveFrom(context),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Add to Shopping List',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'This feature will collect all ingredients from the recipes planned for this date and allow you to add them to your shopping list.',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'It will smart-check against your pantry and existing shopping list items to avoid duplicates.',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.lightbulb,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Complex shopping list integration coming soon! This will use the same smart matching as the pantry update feature.',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 14,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}