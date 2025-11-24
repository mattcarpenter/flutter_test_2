import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

/// Condensed settings row matching recipe editor form style.
/// Fixed 48px height with label left, value right, chevron rightmost.
class SettingsRowCondensed extends StatefulWidget {
  final String title;
  final String? value;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;
  final bool isDestructive;
  final bool grouped;

  const SettingsRowCondensed({
    super.key,
    required this.title,
    this.value,
    this.leading,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
    this.isDestructive = false,
    this.grouped = false,
  });

  @override
  State<SettingsRowCondensed> createState() => _SettingsRowCondensedState();
}

class _SettingsRowCondensedState extends State<SettingsRowCondensed> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Determine text color
    Color titleColor;
    if (!widget.enabled) {
      titleColor = colors.textDisabled;
    } else if (widget.isDestructive) {
      titleColor = colors.error;
    } else {
      titleColor = colors.textPrimary;
    }

    final content = Container(
      height: 48,
      decoration: BoxDecoration(
        color: _isPressed && widget.enabled
            ? colors.surfaceVariant
            : colors.input,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Optional leading icon
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 12),
          ],

          // Title label
          Text(
            widget.title,
            style: AppTypography.fieldInput.copyWith(
              color: titleColor,
            ),
          ),

          const Spacer(),

          // Value text (if provided)
          if (widget.value != null) ...[
            Text(
              widget.value!,
              style: AppTypography.fieldInput.copyWith(
                color: widget.enabled ? colors.textSecondary : colors.textDisabled,
              ),
            ),
          ],

          // Chevron (if enabled)
          if (widget.showChevron && widget.onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              color: widget.enabled ? colors.textSecondary : colors.textDisabled,
              size: 16,
            ),
          ],
        ],
      ),
    );

    if (widget.onTap == null || !widget.enabled) {
      return content;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// Selection row for radio-style lists (e.g., theme mode, font size).
/// Shows checkmark when selected instead of chevron.
class SettingsSelectionRow extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool grouped;

  const SettingsSelectionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.onTap,
    this.enabled = true,
    this.grouped = false,
  });

  @override
  State<SettingsSelectionRow> createState() => _SettingsSelectionRowState();
}

class _SettingsSelectionRowState extends State<SettingsSelectionRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final content = Container(
      height: 48,
      decoration: BoxDecoration(
        color: _isPressed && widget.enabled
            ? colors.surfaceVariant
            : colors.input,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title and optional subtitle
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.fieldInput.copyWith(
                    color: widget.enabled ? colors.textPrimary : colors.textDisabled,
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: widget.enabled ? colors.textSecondary : colors.textDisabled,
                    ),
                  ),
              ],
            ),
          ),

          // Checkmark when selected
          if (widget.isSelected) ...[
            Icon(
              CupertinoIcons.checkmark,
              color: colors.primary,
              size: 20,
            ),
          ],
        ],
      ),
    );

    if (widget.onTap == null || !widget.enabled) {
      return content;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
