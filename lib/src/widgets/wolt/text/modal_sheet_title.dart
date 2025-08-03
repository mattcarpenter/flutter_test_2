import 'package:flutter/material.dart';
import 'package:recipe_app/src/theme/typography.dart';
import 'package:recipe_app/src/theme/colors.dart';

class ModalSheetTitle extends StatelessWidget {
  const ModalSheetTitle(
    this.text, {
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String text;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Text(
        text,
        textAlign: textAlign,
        style: AppTypography.h4.copyWith(
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
