import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/generated/app_localizations_ar.dart';
import '../../l10n/generated/app_localizations_de.dart';
import '../../l10n/generated/app_localizations_en.dart';
import '../../l10n/generated/app_localizations_es.dart';
import '../../l10n/generated/app_localizations_fr.dart';
import '../../l10n/generated/app_localizations_hi.dart';
import '../../l10n/generated/app_localizations_it.dart';
import '../../l10n/generated/app_localizations_ja.dart';
import '../../l10n/generated/app_localizations_ko.dart';
import '../../l10n/generated/app_localizations_pt.dart';
import '../../l10n/generated/app_localizations_ru.dart';
import '../../l10n/generated/app_localizations_zh.dart';

/// Provides localized notification strings without requiring BuildContext.
/// Uses the saved locale preference from SharedPreferences.
class NotificationLocalizer {
  static const String _localeKey = 'selected_locale';

  /// Get the AppLocalizations instance for the current saved locale
  static Future<AppLocalizations> getLocalizations() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    return _getLocalizationsForCode(localeCode);
  }

  /// Get AppLocalizations for a specific locale code
  static AppLocalizations _getLocalizationsForCode(String code) {
    switch (code) {
      case 'ar':
        return AppLocalizationsAr();
      case 'de':
        return AppLocalizationsDe();
      case 'es':
        return AppLocalizationsEs();
      case 'fr':
        return AppLocalizationsFr();
      case 'hi':
        return AppLocalizationsHi();
      case 'it':
        return AppLocalizationsIt();
      case 'ja':
        return AppLocalizationsJa();
      case 'ko':
        return AppLocalizationsKo();
      case 'pt':
        return AppLocalizationsPt();
      case 'ru':
        return AppLocalizationsRu();
      case 'zh':
        return AppLocalizationsZh();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  /// Get a random cheeky daily reminder message
  static Future<String> getRandomCheekyMessage() async {
    final l10n = await getLocalizations();
    final messages = [
      l10n.cheekyMsg1,
      l10n.cheekyMsg2,
      l10n.cheekyMsg3,
      l10n.cheekyMsg4,
      l10n.cheekyMsg5,
      l10n.cheekyMsg6,
      l10n.cheekyMsg7,
      l10n.cheekyMsg8,
      l10n.cheekyMsg9,
      l10n.cheekyMsg10,
      l10n.cheekyMsg11,
      l10n.cheekyMsg12,
      l10n.cheekyMsg13,
      l10n.cheekyMsg14,
      l10n.cheekyMsg15,
      l10n.cheekyMsg16,
      l10n.cheekyMsg17,
      l10n.cheekyMsg18,
      l10n.cheekyMsg19,
      l10n.cheekyMsg20,
    ];
    return messages[Random().nextInt(messages.length)];
  }

  /// Get a random normal daily reminder message
  static Future<String> getRandomNormalMessage() async {
    final l10n = await getLocalizations();
    final messages = [
      l10n.normalMsg1,
      l10n.normalMsg2,
      l10n.normalMsg3,
      l10n.normalMsg4,
      l10n.normalMsg5,
      l10n.normalMsg6,
      l10n.normalMsg7,
      l10n.normalMsg8,
      l10n.normalMsg9,
      l10n.normalMsg10,
      l10n.normalMsg11,
      l10n.normalMsg12,
    ];
    return messages[Random().nextInt(messages.length)];
  }

  /// Get daily reminder title
  static Future<String> getDailyReminderTitle() async {
    final l10n = await getLocalizations();
    return l10n.dailyReminderTitle;
  }

  /// Get weekly summary title
  static Future<String> getWeeklySummaryTitle() async {
    final l10n = await getLocalizations();
    return l10n.weeklySummaryTitle;
  }

  /// Get weekly summary ready message
  static Future<String> getWeeklySummaryReady() async {
    final l10n = await getLocalizations();
    return l10n.weeklySummaryReady;
  }

  /// Get budget exceeded title
  static Future<String> getBudgetExceededTitle() async {
    final l10n = await getLocalizations();
    return l10n.budgetExceededTitle;
  }

  /// Get budget almost gone title
  static Future<String> getBudgetAlmostGoneTitle() async {
    final l10n = await getLocalizations();
    return l10n.budgetAlmostGoneTitle;
  }

  /// Get budget alert title
  static Future<String> getBudgetAlertTitle() async {
    final l10n = await getLocalizations();
    return l10n.budgetAlertTitleNotif;
  }

  /// Get budget exceeded body
  static Future<String> getBudgetExceededBody(String category, String spent, String budget) async {
    final l10n = await getLocalizations();
    return l10n.budgetExceededBody(category, spent, budget);
  }

  /// Get budget almost gone body
  static Future<String> getBudgetAlmostGoneBody(String category, int percentLeft, String remaining) async {
    final l10n = await getLocalizations();
    return l10n.budgetAlmostGoneBody(category, percentLeft, remaining);
  }

  /// Get budget alert body
  static Future<String> getBudgetAlertBody(String category, int percentUsed, String remaining) async {
    final l10n = await getLocalizations();
    return l10n.budgetAlertBody(category, percentUsed, remaining);
  }

  /// Get goal achieved title
  static Future<String> getGoalAchievedTitle() async {
    final l10n = await getLocalizations();
    return l10n.goalAchievedTitle;
  }

  /// Get milestone reached title
  static Future<String> getMilestoneReachedTitle() async {
    final l10n = await getLocalizations();
    return l10n.milestoneReachedTitle;
  }

  /// Get goal update title
  static Future<String> getGoalUpdateTitle() async {
    final l10n = await getLocalizations();
    return l10n.goalUpdateTitle;
  }

  /// Get goal achieved body
  static Future<String> getGoalAchievedBody(String goalName, String amount) async {
    final l10n = await getLocalizations();
    return l10n.goalAchievedBody(goalName, amount);
  }

  /// Get milestone body
  static Future<String> getMilestoneBody(String goalName, int percent) async {
    final l10n = await getLocalizations();
    return l10n.milestoneBody(goalName, percent);
  }

  /// Get goal progress body
  static Future<String> getGoalProgressBody(String goalName, int percent, String remaining) async {
    final l10n = await getLocalizations();
    return l10n.goalProgressBody(goalName, percent, remaining);
  }

  /// Get bill due today title
  static Future<String> getBillDueTodayTitle(bool isExpense) async {
    final l10n = await getLocalizations();
    return isExpense ? l10n.billDueTodayTitle : l10n.incomeDueTodayTitle;
  }

  /// Get bill due tomorrow title
  static Future<String> getBillDueTomorrowTitle(bool isExpense) async {
    final l10n = await getLocalizations();
    return isExpense ? l10n.billDueTomorrowTitle : l10n.incomeDueTomorrowTitle;
  }

  /// Get upcoming bill title
  static Future<String> getUpcomingBillTitle(bool isExpense) async {
    final l10n = await getLocalizations();
    return isExpense ? l10n.upcomingBillTitle : l10n.upcomingIncomeTitle;
  }

  /// Get bill due today body
  static Future<String> getBillDueTodayBody(String name, String amount) async {
    final l10n = await getLocalizations();
    return l10n.billDueTodayBody(name, amount);
  }

  /// Get bill due tomorrow body
  static Future<String> getBillDueTomorrowBody(String name, String amount) async {
    final l10n = await getLocalizations();
    return l10n.billDueTomorrowBody(name, amount);
  }

  /// Get bill due in days body
  static Future<String> getBillDueInDaysBody(String name, String amount, int days) async {
    final l10n = await getLocalizations();
    return l10n.billDueInDaysBody(name, amount, days);
  }

  /// Get cheeky weekly summary message based on savings performance
  static Future<String> getCheekyWeeklySummary({
    required double income,
    required double expense,
    required double savings,
    required bool isPositive,
  }) async {
    final l10n = await getLocalizations();
    final random = Random();
    final savingsStr = savings.abs().toStringAsFixed(0);
    final incomeStr = income.toStringAsFixed(0);
    final expenseStr = expense.toStringAsFixed(0);

    if (isPositive && savings > income * 0.3) {
      // Great savings (30%+)
      final messages = [
        l10n.weeklySummaryGreat1(savingsStr),
        l10n.weeklySummaryGreat2(savingsStr),
        l10n.weeklySummaryGreat3(savingsStr),
        l10n.weeklySummaryGreat4(savingsStr),
      ];
      return messages[random.nextInt(messages.length)];
    } else if (isPositive) {
      // Positive but less than 30%
      final messages = [
        l10n.weeklySummaryGood1(incomeStr, expenseStr, savingsStr),
        l10n.weeklySummaryGood2(incomeStr, expenseStr, savingsStr),
        l10n.weeklySummaryGood3(savingsStr),
        l10n.weeklySummaryGood4(savingsStr),
      ];
      return messages[random.nextInt(messages.length)];
    } else if (savings.abs() > income * 0.5) {
      // Overspent significantly
      final messages = [
        l10n.weeklySummaryBad1(savingsStr),
        l10n.weeklySummaryBad2(savingsStr),
        l10n.weeklySummaryBad3(savingsStr),
        l10n.weeklySummaryBad4(savingsStr),
      ];
      return messages[random.nextInt(messages.length)];
    } else {
      // Slight overspend
      final messages = [
        l10n.weeklySummarySlight1(savingsStr),
        l10n.weeklySummarySlight2(savingsStr),
        l10n.weeklySummarySlight3(savingsStr),
        l10n.weeklySummarySlight4(savingsStr),
      ];
      return messages[random.nextInt(messages.length)];
    }
  }

  /// Get normal weekly summary message
  static Future<String> getNormalWeeklySummary({
    required double income,
    required double expense,
    required double savings,
    required bool isPositive,
  }) async {
    final l10n = await getLocalizations();
    final incomeStr = income.toStringAsFixed(0);
    final expenseStr = expense.toStringAsFixed(0);
    final savingsStr = savings.abs().toStringAsFixed(0);

    return l10n.weeklySummaryNormal(
      incomeStr,
      expenseStr,
      isPositive ? l10n.saved : l10n.over,
      savingsStr,
    );
  }
}
