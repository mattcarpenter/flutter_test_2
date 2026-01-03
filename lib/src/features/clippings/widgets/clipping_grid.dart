import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../database/database.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import 'clipping_card.dart';

/// Groups clippings by date and displays them in a responsive grid layout.
class ClippingGrid extends StatelessWidget {
  final List<ClippingEntry> clippings;
  final Function(String id) onDelete;

  const ClippingGrid({
    super.key,
    required this.clippings,
    required this.onDelete,
  });

  /// Groups clippings into date sections: "Today", "Previous 7 Days", then month names
  Map<String, List<ClippingEntry>> _groupByDate(
    List<ClippingEntry> clippings, {
    required String todayLabel,
    required String previous7DaysLabel,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    final grouped = <String, List<ClippingEntry>>{};

    // Sort clippings by updatedAt descending first
    final sorted = List<ClippingEntry>.from(clippings)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    for (final clipping in sorted) {
      final timestamp = clipping.updatedAt;
      if (timestamp == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final dateOnly = DateTime(date.year, date.month, date.day);

      String section;
      if (dateOnly == today) {
        section = todayLabel;
      } else if (dateOnly.isAfter(sevenDaysAgo)) {
        section = previous7DaysLabel;
      } else {
        // Format as "December 2024"
        section = DateFormat('MMMM yyyy').format(date);
      }

      grouped.putIfAbsent(section, () => []);
      grouped[section]!.add(clipping);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedClippings = _groupByDate(
      clippings,
      todayLabel: context.l10n.clippingsToday,
      previous7DaysLabel: context.l10n.clippingsPrevious7Days,
    );

    // Build list of slivers: alternating section headers and grids
    final slivers = <Widget>[];

    for (final entry in groupedClippings.entries) {
      final sectionTitle = entry.key;
      final sectionClippings = entry.value;

      // Section header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              slivers.isEmpty ? AppSpacing.md : AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              sectionTitle,
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
          ),
        ),
      );

      // Grid of clippings for this section
      slivers.add(
        SliverToBoxAdapter(
          child: _ClippingGridSection(
            clippings: sectionClippings,
            onDelete: onDelete,
          ),
        ),
      );
    }

    // Add bottom padding
    slivers.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: 100),
      ),
    );

    return SliverMainAxisGroup(slivers: slivers);
  }
}

/// A responsive grid section for a group of clippings
class _ClippingGridSection extends StatelessWidget {
  final List<ClippingEntry> clippings;
  final Function(String id) onDelete;

  const _ClippingGridSection({
    required this.clippings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive configuration based on screen width
        late final int columnCount;
        late final double cardHeight;

        if (constraints.maxWidth < 600) {
          // Mobile - 2 columns
          columnCount = 2;
          cardHeight = 140.0;
        } else if (constraints.maxWidth < 900) {
          // Large Mobile - 3 columns
          columnCount = 3;
          cardHeight = 150.0;
        } else if (constraints.maxWidth < 1200) {
          // iPad - 4 columns
          columnCount = 4;
          cardHeight = 160.0;
        } else {
          // Large/Desktop - 5 columns
          columnCount = 5;
          cardHeight = 170.0;
        }

        const spacing = 12.0;
        const horizontalMargin = 16.0;
        final availableWidth = constraints.maxWidth -
            (spacing * (columnCount - 1)) -
            (horizontalMargin * 2);
        final cardWidth = availableWidth / columnCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: clippings.map((clipping) {
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: ClippingCard(
                  clipping: clipping,
                  onTap: () {
                    context.push('/clippings/${clipping.id}');
                  },
                  onDelete: () => onDelete(clipping.id),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
