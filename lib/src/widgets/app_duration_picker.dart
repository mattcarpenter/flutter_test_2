import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../theme/colors.dart';
import 'app_text_field.dart';

enum DurationPickerMode {
  hoursMinutes,    // H:M wheels (0-23h, 0-59m) - most common
  minutesOnly,     // Single wheel (0-999m) - for very short/long
  hoursMinutesSeconds, // H:M:S wheels - rare but available
}

class AppDurationPicker extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final DurationPickerMode mode;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;
  final ValueChanged<int>? onChanged; // Called with minutes

  const AppDurationPicker({
    super.key,
    required this.controller,
    required this.placeholder,
    this.mode = DurationPickerMode.hoursMinutes,
    this.variant = AppTextFieldVariant.outline,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<AppDurationPicker> createState() => _AppDurationPickerState();
}

class _AppDurationPickerState extends State<AppDurationPicker> {
  late TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    _updateDisplayText();
    widget.controller.addListener(_updateDisplayText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateDisplayText);
    _displayController.dispose();
    super.dispose();
  }

  void _updateDisplayText() {
    final minutes = int.tryParse(widget.controller.text) ?? 0;
    _displayController.text = _formatDuration(minutes);
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return "";
    
    switch (widget.mode) {
      case DurationPickerMode.minutesOnly:
        return minutes == 1 ? "1 min" : "$minutes mins";
        
      case DurationPickerMode.hoursMinutes:
        if (minutes < 60) {
          return minutes == 1 ? "1 min" : "$minutes mins";
        }
        
        final hours = minutes ~/ 60;
        final remainingMin = minutes % 60;
        
        if (remainingMin == 0) {
          return hours == 1 ? "1 hr" : "$hours hrs";
        }
        
        return "${hours}h ${remainingMin}m";
        
      case DurationPickerMode.hoursMinutesSeconds:
        // For now, treat as hours:minutes (seconds support can be added later)
        return _formatDuration(minutes);
    }
  }

  void _showDurationPicker() {
    if (!widget.enabled) return;

    HapticFeedback.lightImpact();
    
    final currentMinutes = int.tryParse(widget.controller.text) ?? 0;
    
    WoltModalSheet.show(
      useRootNavigator: true,
      context: context,
      pageListBuilder: (context) => [
        _DurationPickerModalPage.build(
          context: context,
          currentMinutes: currentMinutes,
          mode: widget.mode,
          onUpdate: (minutes) {
            widget.controller.text = minutes.toString();
            widget.onChanged?.call(minutes);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDurationPicker,
      child: AbsorbPointer(
        child: AppTextField(
          controller: _displayController,
          placeholder: widget.placeholder,
          variant: widget.variant,
          errorText: widget.errorText,
          enabled: widget.enabled,
        ),
      ),
    );
  }
}

class _DurationPickerModalPage {
  _DurationPickerModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required int currentMinutes,
    required DurationPickerMode mode,
    required ValueChanged<int> onUpdate,
  }) {
    // Create a GlobalKey to access the content widget
    final contentKey = GlobalKey<_DurationPickerContentState>();

    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      trailingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          final totalMinutes = contentKey.currentState?._totalMinutes ?? currentMinutes;
          onUpdate(totalMinutes);
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
      child: _DurationPickerContent(
        key: contentKey,
        currentMinutes: currentMinutes,
        mode: mode,
        onUpdate: onUpdate,
      ),
    );
  }
}

class _DurationPickerContent extends StatefulWidget {
  final int currentMinutes;
  final DurationPickerMode mode;
  final ValueChanged<int> onUpdate;

  const _DurationPickerContent({
    super.key,
    required this.currentMinutes,
    required this.mode,
    required this.onUpdate,
  });

  @override
  State<_DurationPickerContent> createState() => _DurationPickerContentState();
}

class _DurationPickerContentState extends State<_DurationPickerContent> {
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;
  
  late int _selectedHours;
  late int _selectedMinutes;
  late int _selectedSeconds;

  @override
  void initState() {
    super.initState();
    
    // Parse current duration
    _selectedHours = widget.currentMinutes ~/ 60;
    _selectedMinutes = widget.currentMinutes % 60;
    _selectedSeconds = 0; // For future seconds support
    
    // Initialize controllers
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(initialItem: _selectedMinutes);
    _secondsController = FixedExtentScrollController(initialItem: _selectedSeconds);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  int get _totalMinutes {
    switch (widget.mode) {
      case DurationPickerMode.minutesOnly:
        return _selectedMinutes;
      case DurationPickerMode.hoursMinutes:
      case DurationPickerMode.hoursMinutesSeconds:
        return (_selectedHours * 60) + _selectedMinutes;
    }
  }

  Widget _buildPicker({
    required String label,
    required int itemCount,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int) itemBuilder,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          width: 80,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              onSelectedItemChanged(index);
            },
            children: List.generate(
              itemCount,
              (index) => Center(
                child: Text(
                  itemBuilder(index),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.only(top: 21), // Align with picker content
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Picker wheels
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.mode != DurationPickerMode.minutesOnly) ...[
                _buildPicker(
                  label: 'Hours',
                  itemCount: 24,
                  controller: _hoursController,
                  onSelectedItemChanged: (value) {
                    setState(() => _selectedHours = value);
                  },
                  itemBuilder: (index) => index.toString(),
                ),
                _buildSeparator(),
              ],
              
              _buildPicker(
                label: widget.mode == DurationPickerMode.minutesOnly ? 'Minutes' : 'Minutes',
                itemCount: widget.mode == DurationPickerMode.minutesOnly ? 1000 : 60,
                controller: _minutesController,
                onSelectedItemChanged: (value) {
                  setState(() => _selectedMinutes = value);
                },
                itemBuilder: (index) => widget.mode == DurationPickerMode.minutesOnly
                    ? index.toString()
                    : index.toString().padLeft(2, '0'),
              ),
              
              if (widget.mode == DurationPickerMode.hoursMinutesSeconds) ...[
                _buildSeparator(),
                _buildPicker(
                  label: 'Seconds',
                  itemCount: 60,
                  controller: _secondsController,
                  onSelectedItemChanged: (value) {
                    setState(() => _selectedSeconds = value);
                  },
                  itemBuilder: (index) => index.toString().padLeft(2, '0'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}