import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/meal_plan_provider.dart';
import '../widgets/meal_plan_date_card.dart';

class MealPlansRoot extends ConsumerStatefulWidget {
  const MealPlansRoot({super.key});

  @override
  ConsumerState<MealPlansRoot> createState() => _MealPlansRootState();
}

class _MealPlansRootState extends ConsumerState<MealPlansRoot> {

  @override
  void initState() {
    super.initState();
  }

  // Build date cards
  List<Widget> _buildDateCards() {
    final dates = ref.watch(extendedMealPlanDatesProvider);

    return dates.map((dateString) {
      final date = DateTime.parse(dateString);
      return MealPlanDateCard(
        key: ValueKey(dateString),
        date: date,
        dateString: dateString,
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final dateCards = _buildDateCards();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          final maxScrollExtent = notification.metrics.maxScrollExtent;

          // Load more dates when near the end
          if (pixels >= maxScrollExtent - 200) {
            final currentDays = ref.read(loadedDateRangeProvider);
            ref.read(loadedDateRangeProvider.notifier).state = currentDays + 30;
          }
        }
        return false;
      },
      child: AdaptiveSliverPage(
        title: 'Meal Plans',
        leading: const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => dateCards[index],
                childCount: dateCards.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
