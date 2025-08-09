import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../theme/colors.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

void showCheckPantryModal(BuildContext context, String date) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      CheckPantryModalPage.build(
        context: modalContext,
        date: date,
      ),
    ],
  );
}

class CheckPantryModalPage {
  CheckPantryModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
      pageTitle: const ModalSheetTitle('Check Pantry'),
      child: CheckPantryContent(date: date),
    );
  }
}

class CheckPantryContent extends ConsumerWidget {
  final String date;

  const CheckPantryContent({
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
            CupertinoIcons.checkmark_seal,
            size: 64,
            color: CupertinoColors.activeGreen.resolveFrom(context),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Check Pantry',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'This feature will check which recipes can be made with your current pantry items and show ingredient availability for the recipes planned on this date.',
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
              color: CupertinoColors.systemYellow.resolveFrom(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemYellow.resolveFrom(context).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info,
                  color: CupertinoColors.systemYellow.resolveFrom(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Coming soon! This will integrate with your pantry to show recipe availability.',
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