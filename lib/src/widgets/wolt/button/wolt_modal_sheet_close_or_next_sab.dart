
import 'package:flutter/material.dart';
import 'package:recipe_app/src/widgets/wolt/button/wolt_elevated_button.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../colors/wolt_color_name.dart';

class WoltModalSheetCloseOrNextSab extends StatelessWidget {
  const WoltModalSheetCloseOrNextSab({
    this.colorName = WoltColorName.blue,
    super.key,
  });

  final WoltColorName colorName;

  @override
  Widget build(BuildContext context) {
    final totalPageCount = WoltModalSheet.of(context).pages.length;
    final currentPageIndex = WoltModalSheet.of(context).currentPageIndex;
    final bool isAtLastPage = WoltModalSheet.of(context).isAtLastPage;
    return WoltElevatedButton(
      onPressed: isAtLastPage
          ? Navigator.of(context).pop
          : WoltModalSheet.of(context).showNext,
      child: Text(isAtLastPage
          ? "Close"
          : "Next (${currentPageIndex + 1}/$totalPageCount)"),
    );
  }
}
