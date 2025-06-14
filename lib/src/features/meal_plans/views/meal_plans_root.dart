import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/meal_plan_provider.dart';
import '../widgets/meal_plan_date_card.dart';

class MealPlansRoot extends ConsumerStatefulWidget {
  const MealPlansRoot({super.key});

  @override
  ConsumerState<MealPlansRoot> createState() => _MealPlansRootState();
}

class _MealPlansRootState extends ConsumerState<MealPlansRoot> {
  
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        // Load more dates when near the end
        final currentDays = ref.read(loadedDateRangeProvider);
        ref.read(loadedDateRangeProvider.notifier).state = currentDays + 30;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(extendedMealPlanDatesProvider);
    
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: AdaptiveSliverPage(
        title: 'Meal Plans',
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dateString = dates[index];
                  final date = DateTime.parse(dateString);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: MealPlanDateCard(
                      date: date,
                      dateString: dateString,
                    ),
                  );
                },
                childCount: dates.length,
              ),
            ),
          ),
          // Loading indicator at the bottom
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
