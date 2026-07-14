import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';

/// Date Range Selector Widget
class DateRangeSelector extends ConsumerWidget {
  final bool isDark;

  const DateRangeSelector({
    super.key,
    required this.isDark,
  });

  /// Get localized display label for the date range
  String _getLocalizedDisplayLabel(BuildContext context, DateRangeState dateRange) {
    final l10n = AppLocalizations.of(context);
    if (dateRange.preset == DateRangePreset.custom) {
      return dateRange.shortDateRangeLabel;
    }
    switch (dateRange.preset) {
      case DateRangePreset.thisMonth:
        return l10n?.thisMonth ?? 'This Month';
      case DateRangePreset.lastMonth:
        return l10n?.lastMonth ?? 'Last Month';
      case DateRangePreset.last3Months:
        return l10n?.last3Months ?? 'Last 3 Months';
      case DateRangePreset.custom:
        return dateRange.shortDateRangeLabel;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);

    return GestureDetector(
      onTap: () => _showDateRangePicker(context, ref, dateRange),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing8,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _getLocalizedDisplayLabel(context, dateRange),
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext mainContext, WidgetRef ref, DateRangeState currentRange) {
    final isDark = Theme.of(mainContext).brightness == Brightness.dark;

    showModalBottomSheet(
      context: mainContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DateRangePickerSheet(
        isDark: isDark,
        currentRange: currentRange,
        onPresetSelected: (preset) {
          ref.read(dateRangeProvider.notifier).setPreset(preset);
          Navigator.pop(context);
        },
        onCustomRangeSelected: (start, end) {
          ref.read(dateRangeProvider.notifier).setCustomRange(
            start,
            DateTime(end.year, end.month, end.day, 23, 59, 59),
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _DateRangePickerSheet extends StatefulWidget {
  final bool isDark;
  final DateRangeState currentRange;
  final void Function(DateRangePreset preset) onPresetSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;

  const _DateRangePickerSheet({
    required this.isDark,
    required this.currentRange,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
  });

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late DateRangePreset _selectedPreset;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.currentRange.preset;
    _startDate = widget.currentRange.startDate;
    _endDate = widget.currentRange.endDate;
  }

  void _updateDatesForPreset(DateRangePreset preset) {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case DateRangePreset.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case DateRangePreset.lastMonth:
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case DateRangePreset.last3Months:
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case DateRangePreset.custom:
          // Keep current dates for custom
          break;
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialStart = _startDate;
    final initialEnd = _endDate.isAfter(now) ? now : _endDate;

    final config = CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.range,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
      currentDate: now,
      selectedDayHighlightColor: AppColors.primary,
      selectedRangeHighlightColor: AppColors.primary.withValues(alpha: 0.15),
      dayTextStyle: TextStyle(
        color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      selectedDayTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      weekdayLabelTextStyle: TextStyle(
        color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontWeight: FontWeight.w600,
      ),
      controlsTextStyle: TextStyle(
        color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      disabledDayTextStyle: TextStyle(
        color: widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
      okButtonTextStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      cancelButtonTextStyle: TextStyle(
        color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
      // Rounded selection for days
      dayBorderRadius: BorderRadius.circular(20),
      // Rounded highlight for range between selected days
      rangeBidirectional: true,
      selectedRangeDayTextStyle: TextStyle(
        color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w500,
      ),
    );

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: config,
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      value: [initialStart, initialEnd],
      dialogBackgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );

    if (results != null && results.length == 2 && mounted) {
      setState(() {
        _selectedPreset = DateRangePreset.custom;
        _startDate = results[0]!;
        _endDate = results[1]!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
              color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Title
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.selectDateRange ?? 'Select Date Range',
                style: AppTypography.h4.copyWith(
                  color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing20),

          // Preset Options
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
                child: Column(
                  children: DateRangePreset.values.where((p) => p != DateRangePreset.custom).map((preset) {
                    final isSelected = _selectedPreset == preset;
                    final dates = _getDatesForPreset(preset);

                    // Get localized label for preset
                    String presetLabel;
                    switch (preset) {
                      case DateRangePreset.thisMonth:
                        presetLabel = l10n?.thisMonth ?? 'This Month';
                        break;
                      case DateRangePreset.lastMonth:
                        presetLabel = l10n?.lastMonth ?? 'Last Month';
                        break;
                      case DateRangePreset.last3Months:
                        presetLabel = l10n?.last3Months ?? 'Last 3 Months';
                        break;
                      case DateRangePreset.custom:
                        presetLabel = l10n?.customRange ?? 'Custom Range';
                        break;
                    }

                    return GestureDetector(
                      onTap: () => _updateDatesForPreset(preset),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                        padding: const EdgeInsets.all(AppDimensions.spacing16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: AppDimensions.spacing12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    presetLabel,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatDate(dates.$1)} - ${_formatDate(dates.$2)}',
                                    style: AppTypography.caption.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Custom Range Option
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
                child: InkWell(
                  onTap: () {
                    _pickCustomRange();
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    decoration: BoxDecoration(
                      color: _selectedPreset == DateRangePreset.custom
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: _selectedPreset == DateRangePreset.custom
                            ? AppColors.primary
                            : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: _selectedPreset == DateRangePreset.custom ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedPreset == DateRangePreset.custom ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: _selectedPreset == DateRangePreset.custom
                                  ? AppColors.primary
                                  : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: 2,
                            ),
                          ),
                          child: _selectedPreset == DateRangePreset.custom
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Icon(
                                  LucideIcons.calendar,
                                  size: 12,
                                  color: widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.customRange ?? 'Custom Range',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontWeight: _selectedPreset == DateRangePreset.custom ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedPreset == DateRangePreset.custom
                                    ? '${_formatDate(_startDate)} - ${_formatDate(_endDate)}'
                                    : (l10n?.tapToSelectDates ?? 'Tap to select dates'),
                                style: AppTypography.caption.copyWith(
                                  color: _selectedPreset == DateRangePreset.custom
                                      ? AppColors.primary
                                      : (widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.spacing20),

          // Apply Button
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedPreset == DateRangePreset.custom) {
                        widget.onCustomRangeSelected(_startDate, _endDate);
                      } else {
                        widget.onPresetSelected(_selectedPreset);
                      }
                    },
                    child: Text(l10n?.apply ?? 'Apply'),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: AppDimensions.spacing16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  (DateTime, DateTime) _getDatesForPreset(DateRangePreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case DateRangePreset.thisMonth:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
      case DateRangePreset.lastMonth:
        return (DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0));
      case DateRangePreset.last3Months:
        return (DateTime(now.year, now.month - 2, 1), DateTime(now.year, now.month + 1, 0));
      case DateRangePreset.custom:
        return (_startDate, _endDate);
    }
  }
}
