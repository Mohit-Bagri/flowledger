import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../widgets/common/animated_snackbar.dart';
import '../../widgets/common/custom_time_picker.dart';
import '../../widgets/common/banner_ad_widget.dart';

/// Provider for notification settings
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(),
);

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.instance.getSettings();
    state = settings;
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    state = settings;
    await NotificationService.instance.saveSettings(settings);
  }

  Future<void> toggleDailyReminder(bool enabled) async {
    final newSettings = state.copyWith(dailyReminderEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setDailyReminderTime(int hour, int minute) async {
    final newSettings = state.copyWith(
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
    );
    await updateSettings(newSettings);
  }

  Future<void> toggleBudgetAlert(bool enabled) async {
    final newSettings = state.copyWith(budgetAlertEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setBudgetThreshold(int threshold) async {
    final newSettings = state.copyWith(budgetAlertThreshold: threshold);
    await updateSettings(newSettings);
  }

  Future<void> toggleWeeklySummary(bool enabled) async {
    final newSettings = state.copyWith(weeklySummaryEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleGoalProgress(bool enabled) async {
    final newSettings = state.copyWith(goalProgressEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> toggleBillReminders(bool enabled) async {
    final newSettings = state.copyWith(billRemindersEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setBillReminderDays(int days) async {
    final newSettings = state.copyWith(billReminderDays: days);
    await updateSettings(newSettings);
  }

  Future<void> toggleCheekyMessages(bool enabled) async {
    final newSettings = state.copyWith(cheekyMessagesEnabled: enabled);
    await updateSettings(newSettings);
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n?.notifications ?? 'Notifications',
              style: AppTypography.h3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // Daily Reminders Section
          _SectionHeader(title: l10n.dailyReminders.toUpperCase(), isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ToggleItem(
                icon: LucideIcons.bell,
                title: l10n.dailyExpenseReminder,
                subtitle: l10n.getRemindedToLogExpenses,
                value: settings.dailyReminderEnabled,
                onChanged: (value) => notifier.toggleDailyReminder(value),
                isDark: isDark,
              ),
              if (settings.dailyReminderEnabled) ...[
                _TimePickerItem(
                  icon: LucideIcons.clock,
                  title: l10n.reminderTime,
                  time: settings.dailyReminderTimeString,
                  onTap: () => _showTimePicker(
                    context,
                    settings.dailyReminderHour,
                    settings.dailyReminderMinute,
                    (hour, minute) => notifier.setDailyReminderTime(hour, minute),
                  ),
                  isDark: isDark,
                ),
                _ToggleItem(
                  icon: LucideIcons.smile,
                  title: l10n.cheekyMessages,
                  subtitle: l10n.funWittyReminderMessages,
                  value: settings.cheekyMessagesEnabled,
                  onChanged: (value) => notifier.toggleCheekyMessages(value),
                  isDark: isDark,
                  showDivider: false,
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Budget Alerts Section
          _SectionHeader(title: l10n.budgetAlerts.toUpperCase(), isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ToggleItem(
                icon: LucideIcons.alertTriangle,
                title: l10n.budgetAlerts,
                subtitle: l10n.getNotifiedBudgetLimits,
                value: settings.budgetAlertEnabled,
                onChanged: (value) => notifier.toggleBudgetAlert(value),
                isDark: isDark,
              ),
              if (settings.budgetAlertEnabled)
                _ThresholdSelector(
                  icon: LucideIcons.percent,
                  title: l10n.alertThreshold,
                  value: settings.budgetAlertThreshold,
                  onChanged: (value) => notifier.setBudgetThreshold(value),
                  isDark: isDark,
                  showDivider: false,
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Goal Progress Section
          _SectionHeader(title: l10n.goalProgress.toUpperCase(), isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ToggleItem(
                icon: LucideIcons.target,
                title: l10n.goalNotifications,
                subtitle: l10n.getNotifiedGoalMilestones,
                value: settings.goalProgressEnabled,
                onChanged: (value) => notifier.toggleGoalProgress(value),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Weekly Summary Section
          _SectionHeader(title: l10n.weeklySummary.toUpperCase(), isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ToggleItem(
                icon: LucideIcons.barChart2,
                title: l10n.weeklySummary,
                subtitle: l10n.getSpendingSummaryEverySunday,
                value: settings.weeklySummaryEnabled,
                onChanged: (value) => notifier.toggleWeeklySummary(value),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Bill Reminders Section
          _SectionHeader(title: l10n.billReminders.toUpperCase(), isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ToggleItem(
                icon: LucideIcons.receipt,
                title: l10n.billReminders,
                subtitle: l10n.getRemindedBeforePaymentsDue,
                value: settings.billRemindersEnabled,
                onChanged: (value) => notifier.toggleBillReminders(value),
                isDark: isDark,
              ),
              if (settings.billRemindersEnabled)
                _DaysSelector(
                  icon: LucideIcons.calendar,
                  title: l10n.remindMe,
                  value: settings.billReminderDays,
                  onChanged: (value) => notifier.setBillReminderDays(value),
                  isDark: isDark,
                  showDivider: false,
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Test Notification Button
          _TestNotificationButton(isDark: isDark),

          const SizedBox(height: AppDimensions.spacing32),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
            child: Text(
              l10n.notificationsHelpMessage,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacing24),
        ],
      );
        },
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    int currentHour,
    int currentMinute,
    Function(int hour, int minute) onTimeSelected,
  ) {
    CustomTimePicker.show(
      context,
      initialHour: currentHour,
      initialMinute: currentMinute,
      onTimeSelected: (hour, minute) {
        onTimeSelected(hour, minute);
        // Show confirmation snackbar
        if (context.mounted) {
          final formattedTime = _formatTimeForDisplay(hour, minute);
          AnimatedSnackbar.showReminder(context, 'Reminder set for $formattedTime');
        }
      },
    );
  }

  String _formatTimeForDisplay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: AppDimensions.spacing8,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final bool showDivider;

  const _ToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing16 + 22 + AppDimensions.spacing12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

class _TimePickerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final VoidCallback onTap;
  final bool isDark;

  const _TimePickerItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing12,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    time,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: AppDimensions.spacing16 + 22 + AppDimensions.spacing12,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ],
    );
  }
}

class _ThresholdSelector extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final bool showDivider;

  const _ThresholdSelector({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                              thumbColor: AppColors.primary,
                              overlayColor: AppColors.primary.withValues(alpha: 0.1),
                            ),
                            child: Slider(
                              value: value.toDouble(),
                              min: 50,
                              max: 100,
                              divisions: 10,
                              label: '$value%',
                              onChanged: (v) => onChanged(v.toInt()),
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getThresholdColor(value).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$value%',
                            style: AppTypography.labelMedium.copyWith(
                              color: _getThresholdColor(value),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing16 + 22 + AppDimensions.spacing12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }

  Color _getThresholdColor(int threshold) {
    if (threshold >= 90) return AppColors.error;
    if (threshold >= 80) return AppColors.warning;
    return AppColors.success;
  }
}

class _TestNotificationButton extends StatelessWidget {
  final bool isDark;

  const _TestNotificationButton({required this.isDark});

  Future<void> _sendTestNotification(BuildContext context) async {
    final service = NotificationService.instance;

    debugPrint('=== TEST NOTIFICATION DEBUG ===');
    debugPrint('isInitialized: ${service.isInitialized}');
    debugPrint('hasPermission: ${service.hasPermission}');

    // Make sure notification service is initialized
    if (!service.isInitialized) {
      debugPrint('Service not initialized, initializing now...');
      await service.initialize();
      debugPrint('After initialize - isInitialized: ${service.isInitialized}');
    }

    // First check if permission is granted
    final hasPermission = await service.checkPermissionStatus();
    debugPrint('Permission status after check: $hasPermission');

    if (!hasPermission) {
      // Show permission dialog
      if (!context.mounted) return;

      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.bellOff, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text('Notification Permission'),
            ],
          ),
          content: const Text(
            'FlowLedger needs notification permission to send you reminders and alerts.\n\n'
            'Please enable notifications to receive:\n'
            '• Daily expense reminders\n'
            '• Budget alerts\n'
            '• Weekly summaries\n'
            '• Goal progress updates',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Enable Notifications'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final granted = await service.requestPermission();
        debugPrint('Permission request result: $granted');
        if (!granted) {
          if (!context.mounted) return;
          AnimatedSnackbar.showError(
            context,
            'Please enable notifications in your device settings',
          );
          return;
        }
      } else {
        return; // User chose not to enable
      }
    }

    // Permission granted, send test notification
    debugPrint('Sending test notification...');
    try {
      await service.showNotification(
        id: 999,
        title: 'Test Notification',
        body: 'Great! Notifications are working perfectly. 🎉',
      );
      debugPrint('Test notification sent successfully');

      if (context.mounted) {
        AnimatedSnackbar.showSuccess(context, 'Test notification sent!');
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      if (context.mounted) {
        AnimatedSnackbar.showError(context, 'Failed to send notification: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing8),
      child: OutlinedButton.icon(
        onPressed: () => _sendTestNotification(context),
        icon: Icon(
          LucideIcons.bellRing,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        label: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n?.sendTestNotification ?? 'Send Test Notification',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            );
          },
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing12,
          ),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
    );
  }
}

class _DaysSelector extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final bool showDivider;

  const _DaysSelector({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          l10n?.beforeDueDate ?? 'before due date',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [1, 2, 3, 5, 7].map((days) {
                        final isSelected = value == days;
                        return GestureDetector(
                          onTap: () => onChanged(days),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBackground
                                      : AppColors.lightBackground),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              ),
                            ),
                            child: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  days == 1 ? (l10n?.oneDay ?? '1 day') : (l10n?.nDays(days) ?? '$days days'),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing16 + 22 + AppDimensions.spacing12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}
