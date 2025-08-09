import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../theme/colors.dart';
import 'app_duration_picker.dart' show DurationPickerMode;
import 'app_text_field.dart' show AppTextFieldVariant;

class AppDurationPickerCondensed extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;
  final DurationPickerMode mode;
  final bool first;
  final bool last;
  final bool grouped;

  const AppDurationPickerCondensed({
    Key? key,
    required this.controller,
    required this.placeholder,
    this.variant = AppTextFieldVariant.outline,
    this.errorText,
    this.enabled = true,
    this.mode = DurationPickerMode.hoursMinutes,
    this.first = true,
    this.last = true,
    this.grouped = false,
  }) : super(key: key);

  @override
  State<AppDurationPickerCondensed> createState() => _AppDurationPickerCondensedState();
}

class _AppDurationPickerCondensedState extends State<AppDurationPickerCondensed> {
  late TextEditingController _displayController;
  late FixedExtentScrollController _hoursScrollController;
  late FixedExtentScrollController _minutesScrollController;
  late FixedExtentScrollController _secondsScrollController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    _updateDisplayValue();
    
    final duration = _parseDuration();
    _hoursScrollController = FixedExtentScrollController(
      initialItem: duration.inHours,
    );
    _minutesScrollController = FixedExtentScrollController(
      initialItem: widget.mode == DurationPickerMode.minutesOnly
          ? duration.inMinutes
          : duration.inMinutes % 60,
    );
    _secondsScrollController = FixedExtentScrollController(
      initialItem: (duration.inSeconds % 60),
    );

    widget.controller.addListener(_updateDisplayValue);
  }

  @override
  void dispose() {
    _displayController.dispose();
    _hoursScrollController.dispose();
    _minutesScrollController.dispose();
    _secondsScrollController.dispose();
    widget.controller.removeListener(_updateDisplayValue);
    super.dispose();
  }

  Duration _parseDuration() {
    final value = widget.controller.text;
    if (value.isEmpty) return Duration.zero;
    
    final minutes = int.tryParse(value) ?? 0;
    return Duration(minutes: minutes);
  }

  void _updateDisplayValue() {
    final duration = _parseDuration();
    _displayController.text = _formatDuration(duration);
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final totalMinutes = duration.inMinutes;
    
    if (hours == 0) {
      return '$totalMinutes min';
    } else if (minutes == 0) {
      return '$hours hr';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  void _showDurationPicker() {
    if (!widget.enabled) return;
    
    HapticFeedback.selectionClick();
    
    final duration = _parseDuration();
    _hoursScrollController.jumpToItem(duration.inHours);
    _minutesScrollController.jumpToItem(
      widget.mode == DurationPickerMode.minutesOnly
          ? duration.inMinutes
          : duration.inMinutes % 60,
    );
    _secondsScrollController.jumpToItem(duration.inSeconds % 60);

    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          backgroundColor: AppColors.of(context).background,
          hasSabGradient: false,
          leadingNavBarWidget: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          trailingNavBarWidget: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            onPressed: () {
              final hours = widget.mode != DurationPickerMode.minutesOnly
                  ? _hoursScrollController.selectedItem
                  : 0;
              final minutes = widget.mode == DurationPickerMode.minutesOnly
                  ? _minutesScrollController.selectedItem
                  : _minutesScrollController.selectedItem % 60;
              final seconds = widget.mode == DurationPickerMode.hoursMinutesSeconds
                  ? _secondsScrollController.selectedItem
                  : 0;
              
              final totalMinutes = hours * 60 + minutes + (seconds > 0 ? 1 : 0);
              widget.controller.text = totalMinutes.toString();
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
          pageTitle: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          child: Container(
            height: 250,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPickerContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerContent() {
    switch (widget.mode) {
      case DurationPickerMode.hoursMinutes:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPicker(
              controller: _hoursScrollController,
              itemCount: 24,
              label: 'hours',
            ),
            const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildPicker(
              controller: _minutesScrollController,
              itemCount: 60,
              label: 'minutes',
            ),
          ],
        );
      case DurationPickerMode.minutesOnly:
        return _buildPicker(
          controller: _minutesScrollController,
          itemCount: 1000,
          label: 'minutes',
        );
      case DurationPickerMode.hoursMinutesSeconds:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPicker(
              controller: _hoursScrollController,
              itemCount: 24,
              label: 'hours',
            ),
            const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildPicker(
              controller: _minutesScrollController,
              itemCount: 60,
              label: 'minutes',
            ),
            const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildPicker(
              controller: _secondsScrollController,
              itemCount: 60,
              label: 'seconds',
            ),
          ],
        );
    }
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 40,
              onSelectedItemChanged: (_) => HapticFeedback.selectionClick(),
              children: List.generate(
                itemCount,
                (index) => Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.chipText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    if (widget.first && widget.last) {
      return BorderRadius.circular(8.0);
    } else if (widget.first && !widget.last) {
      return BorderRadius.only(
        topLeft: Radius.circular(8.0),
        topRight: Radius.circular(8.0),
      );
    } else if (!widget.first && widget.last) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(8.0),
        bottomRight: Radius.circular(8.0),
      );
    } else {
      return BorderRadius.zero;
    }
  }

  Border _getBorder() {
    final colors = AppColors.of(context);
    final borderColor = colors.border;
    const borderWidth = 1.0;

    if (widget.variant == AppTextFieldVariant.outline) {
      // Match AppTextFieldCondensed logic: first items get full border, others omit top border
      if (widget.first) {
        return Border.all(
          color: borderColor,
          width: borderWidth,
        );
      } else {
        return Border(
          left: BorderSide(color: borderColor, width: borderWidth),
          right: BorderSide(color: borderColor, width: borderWidth),
          bottom: BorderSide(color: borderColor, width: borderWidth),
        );
      }
    } else {
      // Filled variant - no border
      return Border.all(
        color: Colors.transparent,
        width: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final displayText = _displayController.text.isEmpty ? '--:--' : _displayController.text;
    
    // When grouped, render without container decoration
    if (widget.grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showDurationPicker,
            child: SizedBox(
              height: 48.0,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  
                  // Fixed label on the left
                  Text(
                    widget.placeholder,
                    style: TextStyle(
                      color: widget.errorText != null 
                          ? colors.error 
                          : colors.inputLabel,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Spacer to push chip to the right
                  const Spacer(),
                  
                  // Chip on the right
                  _buildChip(displayText),
                  
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // Error text for grouped fields
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Text(
                widget.errorText!,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      );
    }

    // Non-grouped field with container decoration
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showDurationPicker,
          child: Container(
            height: 48.0,
            decoration: BoxDecoration(
              color: widget.enabled ? colors.surface : colors.surfaceVariant,
              borderRadius: _getBorderRadius(),
              border: _getBorder(),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                
                // Fixed label on the left
                Text(
                  widget.placeholder,
                  style: TextStyle(
                    color: widget.errorText != null 
                        ? colors.error 
                        : colors.inputLabel,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Spacer to push chip to the right
                const Spacer(),
                
                // Chip on the right
                _buildChip(displayText),
                
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),

        // Error text for non-grouped fields
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: 4.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}