import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CookActionButton extends ConsumerWidget {
  final String recipeId;
  final String recipeName;
  final String? householdId;

  const CookActionButton({
    super.key,
    required this.recipeId,
    required this.recipeName,
    this.householdId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCook = ref.watch(activeCookForRecipeProvider(recipeId));
    final cookNotifier = ref.read(cookNotifierProvider.notifier);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final isActive = activeCook != null;
    final buttonText = isActive ? 'Resume Cooking' : 'Start Cooking';

    return ElevatedButton(
      onPressed: () async {
        String cookId;
        if (isActive) {
          cookId = activeCook.id;
        } else {
          cookId = await cookNotifier.startCook(
            recipeId: recipeId,
            userId: userId,
            recipeName: recipeName,
            householdId: householdId,
          );
        }

        // Show your modal here, passing cookId
        /*showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => CookModal(cookId: cookId),
        );*/
      },
      child: Text(buttonText),
    );
  }
}
