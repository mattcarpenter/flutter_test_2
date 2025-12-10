import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../theme/spacing.dart';
import 'clipping_card.dart';

class ClippingList extends StatelessWidget {
  final List<ClippingEntry> clippings;
  final Function(String id) onDelete;

  const ClippingList({
    super.key,
    required this.clippings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        100, // Bottom padding for scroll clearance
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final clipping = clippings[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: ClippingCard(
                clipping: clipping,
                onTap: () {
                  context.push('/clippings/${clipping.id}');
                },
                onDelete: () => onDelete(clipping.id),
              ),
            );
          },
          childCount: clippings.length,
        ),
      ),
    );
  }
}
