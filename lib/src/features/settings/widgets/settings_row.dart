import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// iOS-style settings row with title, optional subtitle, and trailing widget
/// Includes hover states and proper touch handling
class SettingsRow extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;

  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
  });

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasSubtitle = widget.subtitle != null && widget.subtitle!.isNotEmpty;
    
    Widget trailingWidget = const SizedBox.shrink();
    
    if (widget.trailing != null) {
      trailingWidget = widget.trailing!;
    } else if (widget.showChevron && widget.onTap != null) {
      trailingWidget = Icon(
        Icons.chevron_right,
        color: widget.enabled ? colors.textSecondary : colors.textDisabled,
        size: 20,
      );
    }

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: hasSubtitle ? AppSpacing.md : AppSpacing.sm,
      ),
      color: _isPressed && widget.enabled 
          ? colors.surfaceVariant 
          : colors.surface,
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.body.copyWith(
                    color: widget.enabled 
                        ? colors.textPrimary 
                        : colors.textDisabled,
                  ),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: widget.enabled 
                          ? colors.textSecondary 
                          : colors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          trailingWidget,
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
      child: content,
    );
  }
}