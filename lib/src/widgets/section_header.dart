import 'package:flutter/material.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final double topSpacing;
  final double bottomSpacing;

  const SectionHeader(
    this.title, {
    super.key,
    this.topSpacing = 0,
    this.bottomSpacing = AppSpacing.xl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topSpacing,
        bottom: bottomSpacing,
      ),
      child: Text(
        title,
        style: AppTypography.h5,
      ),
    );
  }
}
