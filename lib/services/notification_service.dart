import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/utils/notification_localizer.dart';
import '../data/storage/storage_service.dart';

/// Smart notification service for FlowLedger
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _dailyReminderChannel = 'daily_reminder';
  static const String _budgetAlertChannel = 'budget_alert';
  static const String _weeklySummaryChannel = 'weekly_summary';
  static const String _goalProgressChannel = 'goal_progress';
  static const String _billReminderChannel = 'bill_reminder';

  // Notification IDs
  static const int dailyReminderId = 1; // 1-7 reserved for daily reminders (7 days)
  static const int budgetAlertId = 100; // 100-199 reserved for budget alerts
  static const int weeklySummaryId = 200;
  static const int goalProgressId = 300; // 300-399 reserved for goal alerts
  static const int billReminderId = 400; // 400-499 reserved for bill reminders

  // Preferences keys
  static const String _prefDailyReminderEnabled = 'notification_daily_enabled';
  static const String _prefDailyReminderHour = 'notification_daily_hour';
  static const String _prefDailyReminderMinute = 'notification_daily_minute';
  static const String _prefBudgetAlertEnabled = 'notification_budget_enabled';
  static const String _prefBudgetAlertThreshold = 'notification_budget_threshold';
  static const String _prefWeeklySummaryEnabled = 'notification_weekly_enabled';
  static const String _prefGoalProgressEnabled = 'notification_goal_enabled';
  static const String _prefBillRemindersEnabled = 'notification_bill_reminders_enabled';
  static const String _prefBillReminderDays = 'notification_bill_reminder_days';
  static const String _prefCheekyMessages = 'notification_cheeky_enabled';

  // Track already notified budgets to prevent duplicate notifications
  static const String _prefNotifiedBudgets = 'notified_budgets';

  bool _isInitialized = false;
  bool _hasPermission = false;

  /// Check if notifications permission is granted
  bool get hasPermission => _hasPermission;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Skip initialization on unsupported platforms (macOS desktop, Linux, etc.)
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Notifications not supported on this platform');
      return;
    }

    debugPrint('=== NOTIFICATION SERVICE INITIALIZING ===');

    try {
      tz.initializeTimeZones();

      // Set local timezone to device's actual timezone
      String timeZoneName = await FlutterTimezone.getLocalTimezone();

      // Handle legacy timezone names that may not exist in the database
      // Asia/Calcutta was renamed to Asia/Kolkata in 1993
      final Map<String, String> legacyTimezones = {
        'Asia/Calcutta': 'Asia/Kolkata',
        'US/Eastern': 'America/New_York',
        'US/Pacific': 'America/Los_Angeles',
        'US/Central': 'America/Chicago',
        'US/Mountain': 'America/Denver',
      };

      if (legacyTimezones.containsKey(timeZoneName)) {
        debugPrint('Converting legacy timezone $timeZoneName to ${legacyTimezones[timeZoneName]}');
        timeZoneName = legacyTimezones[timeZoneName]!;
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Timezone set to: $timeZoneName');
      } catch (e) {
        // If timezone still not found, fall back to UTC
        debugPrint('Timezone $timeZoneName not found, falling back to UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }

      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initResult = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('Notification plugin initialized: $initResult');
      _isInitialized = true;

      // Create notification channels on Android (required for Android 8.0+)
      if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        // Create the daily reminder channel with high importance
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _dailyReminderChannel,
            'Daily Reminders',
            description: 'Daily expense tracking reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        debugPrint('Daily reminder notification channel created');

        // Create budget alert channel
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _budgetAlertChannel,
            'Budget Alerts',
            description: 'Notifications when you approach budget limits',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        debugPrint('Budget alert notification channel created');

        // Create weekly summary channel
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _weeklySummaryChannel,
            'Weekly Summary',
            description: 'Weekly spending summary notifications',
            importance: Importance.high,
            playSound: true,
          ),
        );
        debugPrint('Weekly summary notification channel created');

        // Create goal progress channel
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _goalProgressChannel,
            'Goal Progress',
            description: 'Notifications about your savings goal progress',
            importance: Importance.high,
            playSound: true,
          ),
        );
        debugPrint('Goal progress notification channel created');

        // Create bill reminder channel
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _billReminderChannel,
            'Bill Reminders',
            description: 'Reminders for upcoming recurring payments',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        debugPrint('Bill reminder notification channel created');

        // Request permission for Android 13+
        final granted = await androidImpl?.requestNotificationsPermission();
        _hasPermission = granted ?? false;
        debugPrint('Android notification permission: $_hasPermission');

        // Check if notifications are enabled
        final enabled = await androidImpl?.areNotificationsEnabled();
        debugPrint('Notifications enabled in system: $enabled');
      }

      // Request permissions on iOS
      if (Platform.isIOS) {
        final iosResult = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        _hasPermission = iosResult ?? false;
        debugPrint('iOS notification permission: $_hasPermission');
      }

      debugPrint('=== NOTIFICATION SERVICE INITIALIZED ===');
      debugPrint('isInitialized: $_isInitialized, hasPermission: $_hasPermission');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Request notification permission and return whether granted
  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (Platform.isIOS) {
        final iosImpl = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _hasPermission = granted ?? false;
      } else if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        _hasPermission = granted ?? false;
      }
      return _hasPermission;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check current permission status
  Future<bool> checkPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.areNotificationsEnabled();
        _hasPermission = granted ?? false;
      } else if (Platform.isIOS) {
        // iOS doesn't have a direct check - we track it from request result
        // For now, return the last known state
      }
      return _hasPermission;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screens
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Get notification settings
  Future<NotificationSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      dailyReminderEnabled: prefs.getBool(_prefDailyReminderEnabled) ?? true,
      dailyReminderHour: prefs.getInt(_prefDailyReminderHour) ?? 20,
      dailyReminderMinute: prefs.getInt(_prefDailyReminderMinute) ?? 0,
      budgetAlertEnabled: prefs.getBool(_prefBudgetAlertEnabled) ?? true,
      budgetAlertThreshold: prefs.getInt(_prefBudgetAlertThreshold) ?? 80,
      weeklySummaryEnabled: prefs.getBool(_prefWeeklySummaryEnabled) ?? true,
      goalProgressEnabled: prefs.getBool(_prefGoalProgressEnabled) ?? true,
      billRemindersEnabled: prefs.getBool(_prefBillRemindersEnabled) ?? true,
      billReminderDays: prefs.getInt(_prefBillReminderDays) ?? 3,
      cheekyMessagesEnabled: prefs.getBool(_prefCheekyMessages) ?? true,
    );
  }

  /// Save notification settings
  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDailyReminderEnabled, settings.dailyReminderEnabled);
    await prefs.setInt(_prefDailyReminderHour, settings.dailyReminderHour);
    await prefs.setInt(_prefDailyReminderMinute, settings.dailyReminderMinute);
    await prefs.setBool(_prefBudgetAlertEnabled, settings.budgetAlertEnabled);
    await prefs.setInt(_prefBudgetAlertThreshold, settings.budgetAlertThreshold);
    await prefs.setBool(_prefWeeklySummaryEnabled, settings.weeklySummaryEnabled);
    await prefs.setBool(_prefGoalProgressEnabled, settings.goalProgressEnabled);
    await prefs.setBool(_prefBillRemindersEnabled, settings.billRemindersEnabled);
    await prefs.setInt(_prefBillReminderDays, settings.billReminderDays);
    await prefs.setBool(_prefCheekyMessages, settings.cheekyMessagesEnabled);

    // Reschedule notifications based on new settings
    await rescheduleAllNotifications(settings);
  }

  /// Reschedule all notifications based on current settings
  Future<void> rescheduleAllNotifications(NotificationSettings settings) async {
    if (!_isInitialized) return;

    debugPrint('=== RESCHEDULING NOTIFICATIONS ===');

    // Cancel all existing scheduled notifications first
    await _notifications.cancelAll();
    debugPrint('All existing notifications cancelled');

    // Small delay to ensure cancellation is complete
    await Future.delayed(const Duration(milliseconds: 100));

    if (settings.dailyReminderEnabled) {
      debugPrint('Scheduling daily reminder for ${settings.dailyReminderHour}:${settings.dailyReminderMinute}');
      await scheduleDailyReminder(
        hour: settings.dailyReminderHour,
        minute: settings.dailyReminderMinute,
        useCheekyMessages: settings.cheekyMessagesEnabled,
      );
    } else {
      debugPrint('Daily reminder disabled - not scheduling');
    }

    if (settings.weeklySummaryEnabled) {
      debugPrint('Scheduling weekly summary');
      await scheduleWeeklySummary();
    } else {
      debugPrint('Weekly summary disabled - not scheduling');
    }

    if (settings.billRemindersEnabled) {
      debugPrint('Scheduling bill reminders (${settings.billReminderDays} days ahead)');
      await scheduleBillReminders(daysAhead: settings.billReminderDays);
    } else {
      debugPrint('Bill reminders disabled - not scheduling');
    }

    debugPrint('=== RESCHEDULING COMPLETE ===');
  }

  /// Schedule daily expense reminder
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
    bool useCheekyMessages = true,
  }) async {
    if (!_isInitialized) return;

    // Get localized title
    final title = await NotificationLocalizer.getDailyReminderTitle();
    final message = useCheekyMessages
        ? await NotificationLocalizer.getRandomCheekyMessage()
        : await NotificationLocalizer.getRandomNormalMessage();

    debugPrint('Selected notification message: $message');

    final scheduledTime = _nextInstanceOfTime(hour, minute);

    // Debug logging to verify correct scheduling
    debugPrint('=== SCHEDULING DAILY REMINDER ===');
    debugPrint('Requested time: $hour:$minute');
    debugPrint('Current local time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('Scheduled for: $scheduledTime');
    debugPrint('Timezone: ${tz.local.name}');
    debugPrint('================================');

    // Schedule for 7 days ahead with different messages each day
    // This ensures varied messages while maintaining the repeating behavior
    for (int i = 0; i < 7; i++) {
      final dayMessage = useCheekyMessages
          ? await NotificationLocalizer.getRandomCheekyMessage()
          : await NotificationLocalizer.getRandomNormalMessage();

      final dayScheduledTime = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        hour,
        minute,
      ).add(Duration(days: i));

      // Skip if this time has already passed
      if (dayScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      await _notifications.zonedSchedule(
        dailyReminderId + i, // Unique ID for each day
        title,
        dayMessage,
        dayScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyReminderChannel,
            'Daily Reminders',
            channelDescription: 'Daily expense tracking reminders',
            importance: Importance.high,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_reminder',
      );

      debugPrint('Scheduled notification ${dailyReminderId + i} for $dayScheduledTime: $dayMessage');
    }

    debugPrint('Daily reminder scheduled successfully for $hour:$minute');

    // Debug: Print pending notifications after scheduling
    await debugPrintPendingNotifications();
  }

  /// Schedule weekly summary (every Sunday at 10 AM)
  Future<void> scheduleWeeklySummary() async {
    if (!_isInitialized) return;

    // Get localized strings
    final title = await NotificationLocalizer.getWeeklySummaryTitle();
    final body = await NotificationLocalizer.getWeeklySummaryReady();

    await _notifications.zonedSchedule(
      weeklySummaryId,
      title,
      body,
      _nextInstanceOfWeekday(DateTime.sunday, 10, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _weeklySummaryChannel,
          'Weekly Summary',
          channelDescription: 'Weekly spending summary notifications',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  /// Show budget alert notification
  Future<void> showBudgetAlert({
    required String categoryName,
    required int percentUsed,
    required double spent,
    required double budget,
  }) async {
    if (!_isInitialized) return;

    // Generate unique ID for this category alert
    final alertId = budgetAlertId + categoryName.hashCode % 100;

    String title;
    String body;
    final spentStr = spent.toStringAsFixed(0);
    final budgetStr = budget.toStringAsFixed(0);
    final remainingStr = (budget - spent).toStringAsFixed(0);

    if (percentUsed >= 100) {
      title = await NotificationLocalizer.getBudgetExceededTitle();
      body = await NotificationLocalizer.getBudgetExceededBody(categoryName, spentStr, budgetStr);
    } else if (percentUsed >= 90) {
      title = await NotificationLocalizer.getBudgetAlmostGoneTitle();
      body = await NotificationLocalizer.getBudgetAlmostGoneBody(categoryName, 100 - percentUsed, remainingStr);
    } else {
      title = await NotificationLocalizer.getBudgetAlertTitle();
      body = await NotificationLocalizer.getBudgetAlertBody(categoryName, percentUsed, remainingStr);
    }

    await _notifications.show(
      alertId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _budgetAlertChannel,
          'Budget Alerts',
          channelDescription: 'Notifications when you approach budget limits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'budget_alert:$categoryName',
    );
  }

  /// Check if budget alert was already sent for this category this month
  Future<bool> _wasBudgetAlertSent(String categoryId, int threshold) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = '${categoryId}_${now.year}_${now.month}_$threshold';
    final notifiedList = prefs.getStringList(_prefNotifiedBudgets) ?? [];
    return notifiedList.contains(key);
  }

  /// Mark budget alert as sent for this category this month
  Future<void> _markBudgetAlertSent(String categoryId, int threshold) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = '${categoryId}_${now.year}_${now.month}_$threshold';
    final notifiedList = prefs.getStringList(_prefNotifiedBudgets) ?? [];
    if (!notifiedList.contains(key)) {
      notifiedList.add(key);
      await prefs.setStringList(_prefNotifiedBudgets, notifiedList);
    }
  }

  /// Clear notified budgets (call at start of new month)
  Future<void> clearNotifiedBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefNotifiedBudgets);
  }

  /// Check and send budget alert if threshold crossed
  Future<void> checkAndNotifyBudget({
    required String categoryId,
    required String categoryName,
    required double spent,
    required double budget,
  }) async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.budgetAlertEnabled) return;

    final percentUsed = ((spent / budget) * 100).round();
    final threshold = settings.budgetAlertThreshold;

    // Check for threshold crossing
    if (percentUsed >= threshold) {
      final alreadyNotified = await _wasBudgetAlertSent(categoryId, threshold);
      if (!alreadyNotified) {
        await showBudgetAlert(
          categoryName: categoryName,
          percentUsed: percentUsed,
          spent: spent,
          budget: budget,
        );
        await _markBudgetAlertSent(categoryId, threshold);
      }
    }

    // Always notify when over 100%
    if (percentUsed >= 100) {
      final alreadyNotified = await _wasBudgetAlertSent(categoryId, 100);
      if (!alreadyNotified) {
        await showBudgetAlert(
          categoryName: categoryName,
          percentUsed: percentUsed,
          spent: spent,
          budget: budget,
        );
        await _markBudgetAlertSent(categoryId, 100);
      }
    }
  }

  /// Show goal progress notification
  Future<void> showGoalProgress({
    required String goalName,
    required int percentComplete,
    required double currentAmount,
    required double targetAmount,
    bool isMilestone = false,
  }) async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.goalProgressEnabled) return;

    final alertId = goalProgressId + goalName.hashCode % 100;
    String title;
    String body;
    final targetStr = targetAmount.toStringAsFixed(0);
    final remainingStr = (targetAmount - currentAmount).toStringAsFixed(0);

    if (percentComplete >= 100) {
      title = await NotificationLocalizer.getGoalAchievedTitle();
      body = await NotificationLocalizer.getGoalAchievedBody(goalName, targetStr);
    } else if (isMilestone) {
      title = await NotificationLocalizer.getMilestoneReachedTitle();
      body = await NotificationLocalizer.getMilestoneBody(goalName, percentComplete);
    } else {
      title = await NotificationLocalizer.getGoalUpdateTitle();
      body = await NotificationLocalizer.getGoalProgressBody(goalName, percentComplete, remainingStr);
    }

    await _notifications.show(
      alertId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _goalProgressChannel,
          'Goal Progress',
          channelDescription: 'Notifications about your savings goal progress',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'goal_progress:$goalName',
    );
  }

  /// Show weekly summary with actual data
  Future<void> showWeeklySummaryWithData({
    required double totalIncome,
    required double totalExpense,
    required int transactionCount,
  }) async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.weeklySummaryEnabled) return;

    final netSavings = totalIncome - totalExpense;
    final isPositive = netSavings >= 0;

    final title = await NotificationLocalizer.getWeeklySummaryTitle();
    String body;

    if (settings.cheekyMessagesEnabled) {
      body = await NotificationLocalizer.getCheekyWeeklySummary(
        income: totalIncome,
        expense: totalExpense,
        savings: netSavings,
        isPositive: isPositive,
      );
    } else {
      body = await NotificationLocalizer.getNormalWeeklySummary(
        income: totalIncome,
        expense: totalExpense,
        savings: netSavings,
        isPositive: isPositive,
      );
    }

    await _notifications.show(
      weeklySummaryId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _weeklySummaryChannel,
          'Weekly Summary',
          channelDescription: 'Weekly spending summary notifications',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'weekly_summary',
    );
  }

  String _getCheekyWeeklySummary(double income, double expense, double savings, bool isPositive) {
    final random = Random();
    final savingsStr = savings.abs().toStringAsFixed(0);
    final incomeStr = income.toStringAsFixed(0);
    final expenseStr = expense.toStringAsFixed(0);

    if (isPositive && savings > income * 0.3) {
      // Great savings (30%+)
      const messages = [
        "You saved ₹{savings} this week! Your wallet is doing a happy dance! 💃",
        "₹{savings} saved! You're basically a financial wizard at this point! 🧙",
        "Look at you saving ₹{savings}! Your future self just sent a thank you note! 💌",
        "₹{savings} in the bank! Who needs a money tree when you've got skills? 🌳",
        "Saved ₹{savings} this week. Your piggy bank is blushing! 🐷",
        "₹{savings} saved! That's some serious adulting right there! 🎓",
        "You kept ₹{savings} in your pocket this week. Impressive restraint! 👏",
        "₹{savings} saved means ₹{savings} closer to your dreams! Keep going! 🚀",
      ];
      return messages[random.nextInt(messages.length)]
          .replaceAll('{savings}', savingsStr);
    } else if (isPositive) {
      // Positive but less than 30%
      const messages = [
        "Earned ₹{income} and spent ₹{expense}. You're ₹{savings} richer! 🎉",
        "This week: +₹{income} in -₹{expense} out. Net win of ₹{savings}! 📈",
        "₹{savings} saved! Not bad at all. Every rupee counts! 💪",
        "You managed to save ₹{savings} this week. Small wins add up! 🏆",
        "Income ₹{income} vs Expenses ₹{expense}. You're ₹{savings} ahead! ✨",
        "Kept ₹{savings} safe from spending. Your wallet approves! 👍",
        "₹{savings} saved this week. The savings journey continues! 🛤️",
      ];
      return messages[random.nextInt(messages.length)]
          .replaceAll('{income}', incomeStr)
          .replaceAll('{expense}', expenseStr)
          .replaceAll('{savings}', savingsStr);
    } else if (savings.abs() > income * 0.5) {
      // Overspent significantly
      const messages = [
        "Uh oh! You overspent by ₹{savings}. Time to befriend your piggy bank! 🐷",
        "₹{savings} over budget. Your wallet needs a vacation from you! 🏖️",
        "Overspent by ₹{savings}. Maybe cook at home next week? 🍳",
        "You went ₹{savings} over. Time to channel your inner saver! 💰",
        "₹{savings} in the red. Let's make next week a revenge arc! ⚔️",
        "Spent ₹{savings} more than planned. We don't judge we just track! 📊",
        "Oops! ₹{savings} overboard. Time to tighten those purse strings! 👜",
      ];
      return messages[random.nextInt(messages.length)]
          .replaceAll('{savings}', savingsStr);
    } else {
      // Slight overspend
      const messages = [
        "Spent ₹{savings} more than you earned. Let's turn this around next week! 💪",
        "₹{savings} over but hey it happens! Fresh start next week! 🌅",
        "Slightly over by ₹{savings}. Nothing a good week can't fix! 🔧",
        "₹{savings} in the negative. Time to activate savings mode! 🎮",
        "Overspent by just ₹{savings}. You've got this next week! 💫",
        "A tiny ₹{savings} slip. Back on track from Monday! 📅",
      ];
      return messages[random.nextInt(messages.length)]
          .replaceAll('{savings}', savingsStr);
    }
  }

  /// Check and send weekly summary on Sunday
  /// Call this on app startup to send summary if it's Sunday and hasn't been sent today
  Future<void> checkAndSendWeeklySummary() async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.weeklySummaryEnabled) return;

    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    // Check if we already sent today
    final prefs = await SharedPreferences.getInstance();
    final lastSentKey = 'weekly_summary_last_sent';
    final lastSent = prefs.getString(lastSentKey);
    final todayStr = '${now.year}-${now.month}-${now.day}';

    if (lastSent == todayStr) return; // Already sent today

    // Calculate last week's data
    final weekStart = now.subtract(Duration(days: now.weekday + 6)); // Last Monday
    final weekEnd = now.subtract(Duration(days: now.weekday)); // Last Sunday

    try {
      final storage = StorageService.instance;

      // Get income for last week (using income_sources with date field)
      final incomeSources = storage.getIncomeSourcesInRange(weekStart, weekEnd.add(const Duration(days: 1)));
      final weeklyIncome = incomeSources.fold(0.0, (sum, t) => sum + t.amount);

      // Get expenses for last week
      final expenses = storage.getExpensesInRange(weekStart, weekEnd.add(const Duration(days: 1)));
      final weeklyExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

      final transactionCount = incomeSources.length + expenses.length;

      await showWeeklySummaryWithData(
        totalIncome: weeklyIncome,
        totalExpense: weeklyExpenses,
        transactionCount: transactionCount,
      );

      // Mark as sent
      await prefs.setString(lastSentKey, todayStr);
    } catch (e) {
      debugPrint('Error sending weekly summary: $e');
    }
  }

  /// Schedule bill reminders for upcoming recurring transactions
  Future<void> scheduleBillReminders({int daysAhead = 3}) async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.billRemindersEnabled) return;

    try {
      final storage = StorageService.instance;
      final recurringTransactions = storage.getRecurringTransactions();

      final now = DateTime.now();
      final targetDate = now.add(Duration(days: daysAhead));

      // Find recurring transactions due within the next 'daysAhead' days
      int scheduledCount = 0;
      for (final recurring in recurringTransactions) {
        if (!recurring.isActive) continue;

        final dueDate = recurring.nextDueDate;
        // Check if due within the next X days (not including past due)
        if (dueDate.isAfter(now) && dueDate.isBefore(targetDate.add(const Duration(days: 1)))) {
          final notificationId = billReminderId + (recurring.id.hashCode.abs() % 100);
          final daysUntilDue = dueDate.difference(now).inDays;

          // Schedule notification for 9 AM on the reminder day
          final reminderDate = dueDate.subtract(Duration(days: daysAhead - daysUntilDue));
          final scheduledTime = tz.TZDateTime(
            tz.local,
            reminderDate.year,
            reminderDate.month,
            reminderDate.day,
            9, // 9 AM
            0,
          );

          // Only schedule if the time is in the future
          if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
            final title = await _getBillReminderTitle(recurring.type, daysUntilDue);
            final body = await _getBillReminderBody(recurring, daysUntilDue);

            await _notifications.zonedSchedule(
              notificationId,
              title,
              body,
              scheduledTime,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _billReminderChannel,
                  'Bill Reminders',
                  channelDescription: 'Reminders for upcoming recurring payments',
                  importance: Importance.high,
                  priority: Priority.defaultPriority,
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'bill_reminder:${recurring.id}',
            );
            scheduledCount++;
          }
        }
      }
      debugPrint('Scheduled $scheduledCount bill reminders');
    } catch (e) {
      debugPrint('Error scheduling bill reminders: $e');
    }
  }

  Future<String> _getBillReminderTitle(dynamic type, int daysUntilDue) async {
    final isExpense = type.toString().contains('expense');
    if (daysUntilDue == 0) {
      return await NotificationLocalizer.getBillDueTodayTitle(isExpense);
    } else if (daysUntilDue == 1) {
      return await NotificationLocalizer.getBillDueTomorrowTitle(isExpense);
    } else {
      return await NotificationLocalizer.getUpcomingBillTitle(isExpense);
    }
  }

  Future<String> _getBillReminderBody(dynamic recurring, int daysUntilDue) async {
    final name = recurring.name;
    final amount = recurring.amount.toStringAsFixed(0);

    if (daysUntilDue == 0) {
      return await NotificationLocalizer.getBillDueTodayBody(name, amount);
    } else if (daysUntilDue == 1) {
      return await NotificationLocalizer.getBillDueTomorrowBody(name, amount);
    } else {
      return await NotificationLocalizer.getBillDueInDaysBody(name, amount, daysUntilDue);
    }
  }

  /// Check and send bill reminders on app startup
  Future<void> checkAndSendBillReminders() async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.billRemindersEnabled) return;

    try {
      final storage = StorageService.instance;
      final recurringTransactions = storage.getRecurringTransactions();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final recurring in recurringTransactions) {
        if (!recurring.isActive) continue;

        final dueDate = DateTime(
          recurring.nextDueDate.year,
          recurring.nextDueDate.month,
          recurring.nextDueDate.day,
        );

        final daysUntilDue = dueDate.difference(today).inDays;

        // Only show for items due today, tomorrow, or within reminder period
        if (daysUntilDue >= 0 && daysUntilDue <= settings.billReminderDays) {
          // Check if we already notified today for this item
          final prefs = await SharedPreferences.getInstance();
          final notifiedKey = 'bill_reminder_${recurring.id}_${today.toIso8601String().split('T')[0]}';

          if (prefs.getBool(notifiedKey) != true) {
            await showBillReminder(
              name: recurring.name,
              amount: recurring.amount,
              dueDate: recurring.nextDueDate,
              isExpense: recurring.type.toString().contains('expense'),
            );
            await prefs.setBool(notifiedKey, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking bill reminders: $e');
    }
  }

  /// Show an immediate bill reminder notification
  Future<void> showBillReminder({
    required String name,
    required double amount,
    required DateTime dueDate,
    required bool isExpense,
  }) async {
    if (!_isInitialized) return;

    final settings = await getSettings();
    if (!settings.billRemindersEnabled) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = due.difference(today).inDays;

    final alertId = billReminderId + name.hashCode.abs() % 100;
    final title = await _getBillReminderTitle(isExpense ? 'expense' : 'income', daysUntilDue);
    final amountStr = amount.toStringAsFixed(0);
    String body;
    if (daysUntilDue == 0) {
      body = await NotificationLocalizer.getBillDueTodayBody(name, amountStr);
    } else if (daysUntilDue == 1) {
      body = await NotificationLocalizer.getBillDueTomorrowBody(name, amountStr);
    } else {
      body = await NotificationLocalizer.getBillDueInDaysBody(name, amountStr, daysUntilDue);
    }

    await _notifications.show(
      alertId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _billReminderChannel,
          'Bill Reminders',
          channelDescription: 'Reminders for upcoming recurring payments',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'bill_reminder:$name',
    );
  }

  /// Show immediate notification (for testing or one-time alerts)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('=== showNotification called ===');
    debugPrint('id: $id, title: $title');
    debugPrint('isInitialized: $_isInitialized, hasPermission: $_hasPermission');

    if (!_isInitialized) {
      debugPrint('ERROR: Notification service not initialized!');
      return;
    }

    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyReminderChannel,
            'Daily Reminders',
            channelDescription: 'Daily expense tracking reminders',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            // Show notification even when app is in foreground
            fullScreenIntent: false,
            ticker: title,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('Notification show() completed successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR showing notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Debug: Print all pending notifications
  Future<void> debugPrintPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('=== PENDING NOTIFICATIONS (${pending.length}) ===');
    for (final notification in pending) {
      debugPrint('ID: ${notification.id}, Title: ${notification.title}, Payload: ${notification.payload}');
    }
    debugPrint('============================================');
  }

  // Helper: Get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Helper: Get next instance of a specific weekday and time
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cheeky reminder messages (50 options)
  String _getRandomCheekyMessage() {
    const messages = [
      "Your wallet called. It wants to know where the money went today. 👀",
      "Hey big spender! Don't forget to log those expenses before they log you out of your savings.",
      "Plot twist: Your expenses don't track themselves. Time to spill the financial tea! ☕",
      "Your future self will thank you for logging today's expenses. Your present self might grumble but do it anyway!",
      "Money talks but only if you write down what it says. Track those expenses! 💸",
      "Remember that coffee? That lunch? Log 'em before they become financial mysteries!",
      "Your budget is playing hide and seek. Time to find where your money went today!",
      "Breaking news: Receipts in your pocket don't automatically become data. You're needed!",
      "Hey you! Yes you with the receipts. It's expense tracking time! 📝",
      "Your bank statement is preparing a surprise. Make sure you're ready by logging expenses!",
      "Fun fact: People who track expenses are 73% more likely to have money. We made that up but log anyway!",
      "Your expenses are waiting like unopened messages. Time to check them! 💬",
      "Quick reminder: That small purchase still counts. Log it! 🛍️",
      "Your money has been on an adventure today. Care to document the journey?",
      "Even the smallest leak can sink a ship. Track those little expenses! ⛵",
      "Psst! Your expenses are gossiping about you. Better log them before they spill the beans! 🫘",
      "Your money went on a date today. Document where it went! 💕",
      "Alert: Untracked expenses detected in your pocket. Capture them now! 🎯",
      "Remember when you said I'll track it later? It's later now. ⏰",
      "Your piggy bank is judging you. Show it you're responsible! 🐷",
      "Roses are red violets are blue track your expenses your wallet thanks you! 🌹",
      "That ₹50 you spent? It misses being documented. Don't leave it hanging! 😢",
      "Your financial diary is feeling empty. Fill it with today's adventures! 📖",
      "Pro tip: Expenses logged equals stress reduced. Science probably. 🔬",
      "Your money took an Uber today. Log the trip! 🚗",
      "Knock knock! Who's there? Your untracked expenses waiting at the door! 🚪",
      "Did you buy something today? Your app wants to know! Spill it! 🍵",
      "Your expenses are playing hide and seek. Ready or not here I come to log them! 🙈",
      "Money flies but you can track its flight path! ✈️",
      "Alert: Your wallet has stories to tell. Listen and log! 👂",
      "That snack? That chai? That random purchase? Yeah log those! 🍪",
      "Your budget misses you. Visit it with today's expenses! 💝",
      "Confession time: What did you spend today? No judgment just tracking! 🙏",
      "Your expenses are sending you telepathic messages. Log them! 🧠",
      "Fun fact: Logging expenses burns 0.5 calories. Health and wealth! 💪",
      "Your bank account is curious about today's adventures. Share the story! 📚",
      "Warning: Unlogged expenses may cause financial amnesia! 🏥",
      "That thing you bought? It's lonely without its expense entry friend! 🧸",
      "Your money went shopping without telling you. Time to interrogate! 🔍",
      "Evening check: Where did your rupees run off to today? 🏃",
      "Your wallet's autobiography needs today's chapter. Write it! ✍️",
      "Expenses are like pokemon you gotta catch em all! Log now! ⚡",
      "Today's expenses are tomorrow's where did my money go moments. Track them! 🤔",
      "Your financial health called. It wants its data! 📊",
      "That impulse buy? Your budget forgives you. Just log it! 🙆",
      "Tick tock! Your expenses are waiting to be immortalized! ⌛",
      "Your money went on a solo trip today. Document its journey! 🗺️",
      "PSA: Your expenses don't have trust issues. They just need to be logged! 🤝",
      "Hey there finance superstar! Time to update your money diary! ⭐",
      "Your expenses are feeling ghosted. Give them attention! 👻",
    ];

    return messages[Random().nextInt(messages.length)];
  }

  // Normal reminder messages (12 options)
  String _getRandomNormalMessage() {
    const messages = [
      "Don't forget to log your expenses for today.",
      "Take a moment to record today's spending.",
      "Time for your daily expense check-in.",
      "Have you logged your expenses today?",
      "Keep your finances on track by logging today's expenses.",
      "A quick reminder to update your expense log.",
      "End your day right by recording your expenses.",
      "Stay organized and log any spending from today.",
      "Your daily expense reminder is here.",
      "Take 2 minutes to log today's transactions.",
      "Financial tracking reminder: Update your expenses.",
      "Keep your records current by logging today's spending.",
    ];

    return messages[Random().nextInt(messages.length)];
  }
}

/// Notification settings model
class NotificationSettings {
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool budgetAlertEnabled;
  final int budgetAlertThreshold; // Percentage (e.g., 80)
  final bool weeklySummaryEnabled;
  final bool goalProgressEnabled;
  final bool billRemindersEnabled;
  final int billReminderDays; // Days before due date to remind (1-7)
  final bool cheekyMessagesEnabled;

  const NotificationSettings({
    this.dailyReminderEnabled = true,
    this.dailyReminderHour = 20,
    this.dailyReminderMinute = 0,
    this.budgetAlertEnabled = true,
    this.budgetAlertThreshold = 80,
    this.weeklySummaryEnabled = true,
    this.goalProgressEnabled = true,
    this.billRemindersEnabled = true,
    this.billReminderDays = 3,
    this.cheekyMessagesEnabled = true,
  });

  NotificationSettings copyWith({
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? budgetAlertEnabled,
    int? budgetAlertThreshold,
    bool? weeklySummaryEnabled,
    bool? goalProgressEnabled,
    bool? billRemindersEnabled,
    int? billReminderDays,
    bool? cheekyMessagesEnabled,
  }) {
    return NotificationSettings(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      goalProgressEnabled: goalProgressEnabled ?? this.goalProgressEnabled,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      billReminderDays: billReminderDays ?? this.billReminderDays,
      cheekyMessagesEnabled: cheekyMessagesEnabled ?? this.cheekyMessagesEnabled,
    );
  }

  String get dailyReminderTimeString {
    final hour = dailyReminderHour > 12
        ? dailyReminderHour - 12
        : (dailyReminderHour == 0 ? 12 : dailyReminderHour);
    final period = dailyReminderHour >= 12 ? 'PM' : 'AM';
    final minute = dailyReminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
