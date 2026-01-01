import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/utils/grouped_list_styling.dart';

/// iOS-style settings row with title, optional subtitle, and trailing widget
/// Includes press states and proper touch handling
class SettingsRow extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;
  final bool isDestructive;
  final bool isFirst;
  final bool isLast;

  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
    this.isDestructive = false,
    this.isFirst = true,
    this.isLast = true,
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

    // Get grouped list styling
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: widget.isFirst,
      isLastInGroup: widget.isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: widget.isFirst,
      isLastInGroup: widget.isLast,
      isDragging: false,
    );

    // Determine text color
    Color titleColor;
    if (!widget.enabled) {
      titleColor = colors.textDisabled;
    } else if (widget.isDestructive) {
      titleColor = colors.error;
    } else {
      titleColor = colors.textPrimary;
    }

    Widget trailingWidget = const SizedBox.shrink();

    if (widget.trailing != null) {
      trailingWidget = widget.trailing!;
    } else if (widget.showChevron && widget.onTap != null) {
      trailingWidget = HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: widget.enabled ? colors.textTertiary : colors.textDisabled,
        size: 16,
      );
    }

    final content = Container(
      decoration: BoxDecoration(
        color: _isPressed && widget.enabled
            ? colors.surfaceVariant
            : colors.groupedListBackground,
        borderRadius: borderRadius,
        border: border,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: hasSubtitle ? AppSpacing.md : AppSpacing.lg,
      ),
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
                    color: titleColor,
                  ),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: widget.enabled
                          ? colors.textSecondary
                          : colors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != const SizedBox.shrink()) ...[
            SizedBox(width: AppSpacing.sm),
            trailingWidget,
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

/// A toggle row for settings with a CupertinoSwitch
class SettingsToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool isFirst;
  final bool isLast;

  const SettingsToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.isFirst = true,
    this.isLast = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    // Get grouped list styling
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.groupedListBackground,
        borderRadius: borderRadius,
        border: border,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: hasSubtitle ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: enabled ? colors.textPrimary : colors.textDisabled,
                  ),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: enabled ? colors.textSecondary : colors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: colors.primary,
          ),
        ],
      ),
    );
  }
}
