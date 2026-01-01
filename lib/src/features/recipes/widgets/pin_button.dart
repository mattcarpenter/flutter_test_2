import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/recipe_provider.dart';

class PinButton extends ConsumerWidget {
  final String recipeId;
  
  const PinButton({
    super.key,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific recipe to get its current pin status
    final recipeAsync = ref.watch(recipeByIdStreamProvider(recipeId));
    
    return recipeAsync.when(
      loading: () => const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (recipe) {
        if (recipe == null) return const SizedBox.shrink();
        
        final isPinned = (recipe.pinned ?? 0) == 1;
        
        return GestureDetector(
          onTap: () {
            ref.read(recipeNotifierProvider.notifier).togglePin(recipeId);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            child: isPinned
                ? const Icon(
                    CupertinoIcons.bookmark_fill,
                    color: Colors.white,
                    size: 20,
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedBookmark01,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        );
      },
    );
  }
}