import 'package:flutter/material.dart' hide Step;

import '../../../../../database/models/steps.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';

class RecipeStepsView extends StatelessWidget {
  final List<Step> steps;

  const RecipeStepsView({Key? key, required this.steps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: AppTypography.h2Serif.copyWith(
            color: AppColors.of(context).headingSecondary,
          ),
        ),

        SizedBox(height: AppSpacing.md),

        if (steps.isEmpty)
          const Text('No instructions listed.'),

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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2, // More spacing between letters
                    color: AppColorSwatches.neutral[500],
                  ),
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
                      color: AppColorSwatches.surface[200], // Light sand - matches page's warm tint
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_getStepNumber(steps, index)}',
                      style: TextStyle(
                        color: AppColorSwatches.surface[800], // Dark taupe/mocha - matches warm tint
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Step content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step text
                        Text(
                          step.text,
                          style: const TextStyle(fontSize: 16),
                        ),

                        // Note (if available)
                        if (step.note != null && step.note!.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              step.note!,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
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
