import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_steps_view.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import '../../../settings/providers/app_settings_provider.dart';
import '../../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../../providers/recently_viewed_provider.dart';
import '../../../../providers/cook_provider.dart';
import '../../../../providers/scale_convert_provider.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/duration_formatter.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/star_rating.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cook_modal/cook_modal.dart';

import '../../../../../database/database.dart';


class RecipeView extends ConsumerStatefulWidget {
  final String recipeId;
  final bool showHeroImage;

  const RecipeView({Key? key, required this.recipeId, this.showHeroImage = true}) : super(key: key);

  @override
  ConsumerState<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<RecipeView> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch ingredient matches when the view is loaded
    Future.microtask(() {
      // First make sure the pantry data is fresh
      ref.refresh(pantryItemsProvider);

      // Then invalidate and read the ingredient matches
      ref.invalidate(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId));
      ref.read(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId).future);

      // Track this recipe as recently viewed
      ref.read(recentlyViewedProvider.notifier).addRecentlyViewed(widget.recipeId);
    });
  }

  @override
  void didUpdateWidget(RecipeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the recipe ID changes, refresh the data
    if (oldWidget.recipeId != widget.recipeId) {
      Future.microtask(() {
        ref.invalidate(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId));
        ref.read(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId).future);

        // Track the new recipe as recently viewed
        ref.read(recentlyViewedProvider.notifier).addRecentlyViewed(widget.recipeId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch pantry items to detect changes
    ref.watch(pantryItemsProvider);
    final recipeAsync = ref.watch(recipe_provider.recipeByIdStreamProvider(widget.recipeId));

    // Get font scale from settings
    final fontScale = ref.watch(recipeFontScaleProvider);
    final baseFontSize = AppTypography.body.fontSize ?? 16.0;
    final scaledFontSize = baseFontSize * fontScale;

    return recipeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading recipe: $error')),
      data: (recipe) {
        if (recipe == null) {
          return const Center(child: Text('Recipe not found'));
        }

        // Calculate total time (if both prep and cook times are available)
        String totalTime = '';
        if (recipe.prepTime != null && recipe.cookTime != null) {
          final total = recipe.prepTime! + recipe.cookTime!;
          totalTime = DurationFormatter.formatMinutes(total);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery (only show if showHeroImage is true)
            if (widget.showHeroImage && recipe.images != null && recipe.images!.isNotEmpty) ...[
              RecipeImageGallery(images: recipe.images!, recipeId: recipe.id),
              const SizedBox(height: 16),
            ],

            // Title and Cooking Button Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (takes remaining space after button)
                Expanded(
                  child: Text(
                    recipe.title,
                    style: AppTypography.h1Serif.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Space between title and button
                // Cooking Button (intrinsic width, right-aligned)
                _buildCookingButton(context, ref, recipe),
              ],
            ),

            // Description (if available)
            if (recipe.description != null && recipe.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recipe.description!,
                style: AppTypography.body.copyWith(
                  fontSize: scaledFontSize,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Recipe Info
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                if (recipe.servings != null)
                  Builder(
                    builder: (context) {
                      // Watch scale state to update servings display
                      final scaleState = ref.watch(scaleConvertProvider(widget.recipeId));
                      final scaledServings = scaleState.isScalingActive
                          ? (recipe.servings! * scaleState.scaleFactor).round()
                          : recipe.servings!;
                      return _buildInfoItem(
                        context,
                        label: 'Servings',
                        value: '$scaledServings',
                        fontScale: fontScale,
                      );
                    },
                  ),
                if (recipe.prepTime != null)
                  _buildInfoItem(
                    context,
                    label: 'Prep Time',
                    value: DurationFormatter.formatMinutes(recipe.prepTime!),
                    fontScale: fontScale,
                  ),
                if (recipe.cookTime != null)
                  _buildInfoItem(
                    context,
                    label: 'Cook Time',
                    value: DurationFormatter.formatMinutes(recipe.cookTime!),
                    fontScale: fontScale,
                  ),
                if (totalTime.isNotEmpty)
                  _buildInfoItem(
                    context,
                    label: 'Total',
                    value: totalTime,
                    fontScale: fontScale,
                  ),
                if (recipe.rating != null && recipe.rating! > 0)
                  _buildRatingItem(context, recipe.rating!),
              ],
            ),

            // Source (if available)
            if (recipe.source != null && recipe.source!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSourceWidget(context, recipe.source!, scaledFontSize),
            ],

            const SizedBox(height: 32),

            // Ingredients with pantry match indicators
            RecipeIngredientsView(
              ingredients: recipe.ingredients ?? [],
              recipeId: recipe.id,
              // Add a unique key to force rebuild
              key: ValueKey('IngredientsView-${recipe.id}'),
            ),

            const SizedBox(height: 24),

            // Steps
            RecipeStepsView(steps: recipe.steps ?? []),

            // Notes (if available)
            if (recipe.generalNotes != null && recipe.generalNotes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: AppTypography.h3Serif.copyWith(
                  color: AppColors.of(context).headingSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recipe.generalNotes!,
                style: AppTypography.body.copyWith(
                  fontSize: scaledFontSize,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
      BuildContext context, {
        required String label,
        required String value,
        double fontScale = 1.0,
      }) {
    final baseFontSize = AppTypography.body.fontSize ?? 16.0;
    final scaledFontSize = baseFontSize * fontScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontSize: scaledFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(BuildContext context, int rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: AppTypography.caption.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        StarRating(
          rating: rating,
          size: StarRatingSize.small,
          onRatingChanged: null,
        ),
      ],
    );
  }

  Widget _buildCookingButton(BuildContext context, WidgetRef ref, RecipeEntry recipe) {
    // Don't show button if recipe has no non-section steps
    final nonSectionSteps = recipe.steps?.where((s) => s.type != 'section').toList() ?? [];
    if (nonSectionSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeCook = ref.watch(activeCookForRecipeProvider(recipe.id));
    final cookNotifier = ref.read(cookNotifierProvider.notifier);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final isActive = activeCook != null;
    final buttonText = isActive ? 'Resume Cooking' : 'Start Cooking';

    return AppButton(
      text: buttonText,
      style: AppButtonStyle.outline,
      size: AppButtonSize.small,
      leadingIcon: const Icon(Icons.play_arrow, size: 18),
      onPressed: () async {
        String cookId;
        if (isActive) {
          cookId = activeCook.id;
        } else {
          // userId can be null for anonymous users - cooks work locally
          // and get synced/claimed when user signs in later
          cookId = await cookNotifier.startCook(
            recipeId: recipe.id,
            userId: userId,
            recipeName: recipe.title,
            householdId: null,
          );
        }

        if (context.mounted) {
          showCookModal(
            context,
            cookId: cookId,
            recipeId: recipe.id,
          );
        }
      },
    );
  }

  /// Check if a string is a URL
  bool _isUrl(String text) {
    final urlPattern = RegExp(
      r'^https?:\/\/',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text.trim());
  }

  /// Build the source widget - linkified if URL, plain text otherwise
  Widget _buildSourceWidget(BuildContext context, String source, double fontSize) {
    final colors = AppColors.of(context);
    final isUrl = _isUrl(source);

    if (!isUrl) {
      // Plain text source
      return Text(
        'Source: $source',
        style: AppTypography.body.copyWith(
          fontSize: fontSize,
          color: colors.textSecondary,
        ),
      );
    }

    // URL source - make it tappable with dotted underline
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(source.trim());
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Source: ',
              style: AppTypography.body.copyWith(
                fontSize: fontSize,
                color: colors.textSecondary,
              ),
            ),
            TextSpan(
              text: source,
              style: AppTypography.body.copyWith(
                fontSize: fontSize,
                color: colors.textSecondary,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: colors.textSecondary,
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
