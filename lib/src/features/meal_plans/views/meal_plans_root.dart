import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Meal Plans'),
      ),
      child: SafeArea(
        child: NotificationListener<ScrollNotification>(
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
          child: CustomScrollView(
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
        ),
      ),
    );
  }
}
