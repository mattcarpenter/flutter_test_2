import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'adaptive_pull_down/adaptive_pull_down.dart';
import 'adaptive_pull_down/adaptive_menu_item.dart';

/// A minimalist overflow button with no background.
/// 
/// This button displays a horizontal ellipsis (more_horiz) icon in the primary
/// color and shows a dropdown menu when tapped. The simple design keeps the
/// UI clean and uncluttered.
class AppOverflowButton extends StatelessWidget {
  /// The list of menu items to display when the button is tapped.
  final List<AdaptiveMenuItem> items;
  
  /// The size of the button's tap target. Defaults to 36.0.
  final double size;
  
  /// Whether the button is enabled. When false, the button appears disabled
  /// and won't respond to taps.
  final bool enabled;

  const AppOverflowButton({
    Key? key,
    required this.items,
    this.size = 36.0,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    // Use primary color for the dots directly (no background)
    final iconColor = enabled 
        ? colors.primary  // Use primary color for visibility
        : colors.textDisabled;
    
    final button = SizedBox(
      height: size,
      width: size,
      child: Center(
        child: Icon(
          Icons.more_horiz,
          color: iconColor,
          size: 24.0,  // Larger dots for better visibility without background
        ),
      ),
    );
    
    // If disabled, just return the button without the pull down functionality
    if (!enabled) {
      return button;
    }
    
    // Wrap with AdaptivePullDownButton for the menu functionality
    return AdaptivePullDownButton(
      items: items,
      child: button,
    );
  }
}