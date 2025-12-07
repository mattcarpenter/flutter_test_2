import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../database/models/steps.dart';
import '../../../settings/providers/app_settings_provider.dart';
import '../../../timers/widgets/start_timer_dialog.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../utils/recipe_text_renderer.dart';

class RecipeStepsView extends ConsumerWidget {
  final List<Step> steps;
  final String recipeId;
  final String recipeName;

  /// When true, duration expressions in step text are rendered as tappable
  /// links that allow starting timers. Defaults to true.
  final bool enableTimerLinks;

  const RecipeStepsView({
    Key? key,
    required this.steps,
    required this.recipeId,
    required this.recipeName,
    this.enableTimerLinks = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    // Get font scale from settings - use AppTypography.body as the base for consistency
    final fontScale = ref.watch(recipeFontScaleProvider);
    final baseBodyStyle = AppTypography.body;
    final scaledFontSize = (baseBodyStyle.fontSize ?? 15.0) * fontScale;

    // Calculate total non-section steps for timer display
    final totalSteps = steps.where((s) => s.type != 'section').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: AppTypography.h3Serif.copyWith(
            color: colors.headingSecondary,
          ),
        ),

        SizedBox(height: AppSpacing.md),

        if (steps.isEmpty)
          Text(
            'No instructions listed.',
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final step = steps[index];

            // Section header
            if (step.type == 'section') {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 20.0, // More space above for hierarchy
                  bottom: 8.0, // Less space below
                ),
                child: Text(
                  step.text.toUpperCase(),
                  style: AppTypography.sectionLabel,
                ),
              );
            }

            // Regular step
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : 12.0,
                bottom: 12.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number (for non-section steps)
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isLight
                          ? AppColorSwatches.surface[200]  // Light sand in light mode
                          : AppColorSwatches.neutral[800]!, // Dark gray in dark mode
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_getStepNumber(steps, index)}',
                      style: AppTypography.caption.copyWith(
                        color: isLight
                            ? AppColorSwatches.surface[800]  // Dark taupe in light mode
                            : AppColorSwatches.neutral[300]!, // Light gray in dark mode
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Step content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step text with rich formatting support
                        RecipeTextRenderer(
                          text: step.text,
                          baseStyle: baseBodyStyle.copyWith(
                            fontSize: scaledFontSize,
                            color: colors.contentPrimary,
                          ),
                          enableRecipeLinks: true,
                          enableDurationLinks: enableTimerLinks,
                          onDurationTap: enableTimerLinks
                              ? (duration, detectedText) {
                                  final stepNumber = _getStepNumber(steps, index);
                                  showStartTimerDialog(
                                    context,
                                    recipeId: recipeId,
                                    recipeName: recipeName,
                                    stepId: step.id,
                                    stepNumber: stepNumber,
                                    totalSteps: totalSteps,
                                    duration: duration,
                                    detectedText: detectedText,
                                  );
                                }
                              : null,
                        ),

                        // Note (if available)
                        if (step.note != null && step.note!.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(
                              step.note!,
                              style: AppTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ],

                        // Timer (if available)
                        if (step.timerDurationSeconds != null && step.timerDurationSeconds! > 0) ...[
                          SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(step.timerDurationSeconds!),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Calculate the step number (excluding sections)
  int _getStepNumber(List<Step> steps, int currentIndex) {
    int number = 1;
    for (int i = 0; i < currentIndex; i++) {
      if (steps[i].type != 'section') {
        number++;
      }
    }
    return number;
  }

  // Format seconds to mm:ss or hh:mm:ss
  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }
}
