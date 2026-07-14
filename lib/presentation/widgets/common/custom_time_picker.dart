import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';

/// Custom Time Picker Bottom Sheet with app-consistent styling
class CustomTimePicker extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final Function(int hour, int minute) onTimeSelected;

  const CustomTimePicker({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    required this.onTimeSelected,
  });

  /// Show the custom time picker as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required int initialHour,
    required int initialMinute,
    required Function(int hour, int minute) onTimeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomTimePicker(
        initialHour: initialHour,
        initialMinute: initialMinute,
        onTimeSelected: onTimeSelected,
      ),
    );
  }

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  // Quick presets for common times
  static const List<({String label, int hour, int minute})> _presets = [
    (label: '6:00 AM', hour: 6, minute: 0),
    (label: '8:00 AM', hour: 8, minute: 0),
    (label: '12:00 PM', hour: 12, minute: 0),
    (label: '6:00 PM', hour: 18, minute: 0),
    (label: '9:00 PM', hour: 21, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _formatMinute(int minute) {
    return minute.toString().padLeft(2, '0');
  }

  void _selectPreset(int hour, int minute) {
    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
    });
    _hourController.animateToItem(
      hour,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _minuteController.animateToItem(
      minute,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
            child: Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Text(
                  'Select Time',
                  style: AppTypography.h4.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // Quick Presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
            child: Wrap(
              spacing: AppDimensions.spacing8,
              runSpacing: AppDimensions.spacing8,
              children: _presets.map((preset) {
                final isSelected = preset.hour == _selectedHour && preset.minute == _selectedMinute;
                return GestureDetector(
                  onTap: () => _selectPreset(preset.hour, preset.minute),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing12,
                      vertical: AppDimensions.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      preset.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Time Picker Wheels
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing32),
            child: Row(
              children: [
                // Hour Picker
                Expanded(
                  child: _WheelPicker(
                    controller: _hourController,
                    itemCount: 24,
                    selectedItem: _selectedHour,
                    onChanged: (value) => setState(() => _selectedHour = value),
                    itemBuilder: (index) => _formatHour(index),
                    isDark: isDark,
                  ),
                ),

                // Separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
                  child: Text(
                    ':',
                    style: AppTypography.h2.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),

                // Minute Picker
                Expanded(
                  child: _WheelPicker(
                    controller: _minuteController,
                    itemCount: 60,
                    selectedItem: _selectedMinute,
                    onChanged: (value) => setState(() => _selectedMinute = value),
                    itemBuilder: (index) => _formatMinute(index),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onTimeSelected(_selectedHour, _selectedMinute);
                  Navigator.pop(context);
                },
                child: const Text('Set Time'),
              ),
            ),
          ),

          SizedBox(height: AppDimensions.spacing16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _WheelPicker extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedItem;
  final ValueChanged<int> onChanged;
  final String Function(int) itemBuilder;
  final bool isDark;

  const _WheelPicker({
    required this.controller,
    required this.itemCount,
    required this.selectedItem,
    required this.onChanged,
    required this.itemBuilder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Selection highlight
        Center(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        // Wheel
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 48,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              final isSelected = index == selectedItem;
              return Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.h3.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  child: Text(itemBuilder(index)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
