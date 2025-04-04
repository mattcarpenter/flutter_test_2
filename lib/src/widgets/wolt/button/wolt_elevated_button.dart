// ignore_for_file: prefer-switch-with-enums

import 'package:flutter/material.dart';
import 'package:recipe_app/src/widgets/wolt/button/wolt_elevated_button.dart';

import '../colors/wolt_color_name.dart';

export 'wolt_elevated_button_theme.dart';

class WoltElevatedButton extends StatelessWidget {
  const WoltElevatedButton({
    super.key,
    this.enabled = true,
    this.colorName = WoltColorName.blue,
    this.theme = WoltElevatedButtonTheme.primary,
    this.height = defaultHeight,
    required this.onPressed,
    required this.child,
  });

  static const defaultHeight = 56.0;

  final WoltColorName colorName;
  final WoltElevatedButtonTheme theme;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
            return states.contains(MaterialState.disabled)
                ? theme.disabledForegroundColor(colorName)
                : theme.enabledForegroundColor(colorName);
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
            return states.contains(MaterialState.disabled)
                ? theme.disabledBackgroundColor(colorName)
                : theme.enabledBackgroundColor(colorName);
          },
        ),
        overlayColor: MaterialStateProperty.all(theme.splashColor(colorName)),
        shadowColor: MaterialStateProperty.all(Colors.transparent),
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
      // To disable, press action should be null
      onPressed: enabled ? onPressed : null,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: child,
        ),
      ),
    );
  }
}
