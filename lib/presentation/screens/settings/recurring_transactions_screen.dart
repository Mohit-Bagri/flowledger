import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/income.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import 'add_recurring_sheet.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/common/banner_ad_widget.dart';

/// Recurring Transactions Management Screen
class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recurringTransactions = ref.watch(recurringTransactionsProvider);
    final dueCount = ref.watch(dueRecurringCountProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final limit = FreeTierLimits.recurringTransactions;

    // Separate active and inactive
    final activeRecurring = recurringTransactions.where((r) => r.isActive).toList();
    final inactiveRecurring = recurringTransactions.where((r) => !r.isActive).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n?.recurringTransactions ?? 'Recurring Transactions'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        actions: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: recurringTransactions.length >= limit
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recurringTransactions.length}/$limit',
                    style: AppTypography.labelSmall.copyWith(
                      color: recurringTransactions.length >= limit
                          ? AppColors.warning
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (dueCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacing8),
              child: TextButton.icon(
                onPressed: () => _showPendingTransactions(context, ref),
                icon: Icon(LucideIcons.alertCircle, size: 18, color: AppColors.warning),
                label: Text(
                  '$dueCount Due',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.warning),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: recurringTransactions.isEmpty
          ? _EmptyState(isDark: isDark, l10n: l10n)
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              children: [
                // Due transactions banner
                if (dueCount > 0) ...[
                  _DueBanner(
                    dueCount: dueCount,
                    onTap: () => _showPendingTransactions(context, ref),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                ],

                // Active recurring transactions
                if (activeRecurring.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n?.active ?? 'Active',
                    count: activeRecurring.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                  ...activeRecurring.map((recurring) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                    child: _RecurringCard(
                      recurring: recurring,
                      isDark: isDark,
                      onTap: () => _showOptions(context, ref, recurring, l10n),
                    ),
                  )),
                ],

                // Inactive recurring transactions
                if (inactiveRecurring.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacing16),
                  _SectionHeader(
                    title: l10n?.paused ?? 'Paused',
                    count: inactiveRecurring.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                  ...inactiveRecurring.map((recurring) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                    child: _RecurringCard(
                      recurring: recurring,
                      isDark: isDark,
                      onTap: () => _showOptions(context, ref, recurring, l10n),
                    ),
                  )),
                ],

                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Check premium limit
          final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
            PremiumFeature.unlimitedRecurring,
            recurringTransactions.length,
          );

          if (!canAdd) {
            UpgradeDialog.show(
              context,
              feature: PremiumFeature.unlimitedRecurring,
              currentCount: recurringTransactions.length,
              limit: FreeTierLimits.recurringTransactions,
            );
            return;
          }

          AddRecurringSheet.show(context);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          l10n?.addRecurring ?? 'Add Recurring',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _showPendingTransactions(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingTransactionsScreen()),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, RecurringTransaction recurring, AppLocalizations? l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
                child: Column(
                  children: [
                    // Edit
                    ListTile(
                      leading: Icon(LucideIcons.edit, color: AppColors.primary),
                      title: Text(
                        l10n?.edit ?? 'Edit',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        AddRecurringSheet.show(context, existingRecurring: recurring);
                      },
                    ),
                    // Toggle Active
                    ListTile(
                      leading: Icon(
                        recurring.isActive ? LucideIcons.pause : LucideIcons.play,
                        color: recurring.isActive ? AppColors.warning : AppColors.success,
                      ),
                      title: Text(
                        recurring.isActive ? (l10n?.paused ?? 'Pause') : 'Resume',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await ref.read(recurringTransactionsProvider.notifier).toggleActive(
                          recurring.id,
                          !recurring.isActive,
                        );
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(recurring.isActive
                                ? 'Recurring transaction paused'
                                : 'Recurring transaction resumed'),
                          ),
                        );
                      },
                    ),
                    // Delete
                    ListTile(
                      leading: Icon(LucideIcons.trash2, color: AppColors.error),
                      title: Text(
                        l10n?.delete ?? 'Delete',
                        style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final authenticated = await BiometricService.instance.authenticateForDelete();
                        if (authenticated) {
                          await ref.read(recurringTransactionsProvider.notifier).deleteRecurring(recurring.id);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(l10n?.recurringTransactionDeleted ?? 'Recurring transaction deleted')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty State Widget
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;

  const _EmptyState({required this.isDark, this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.repeat,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            'No Recurring Transactions',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Add subscriptions, bills, or regular income\nto track them automatically',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Due Banner
class _DueBanner extends StatelessWidget {
  final int dueCount;
  final VoidCallback onTap;
  final bool isDark;

  const _DueBanner({
    required this.dueCount,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withValues(alpha: 0.15),
              AppColors.warning.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.bell, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dueCount Transaction${dueCount > 1 ? 's' : ''} Due',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to review and confirm',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Recurring Transaction Card
class _RecurringCard extends ConsumerWidget {
  final RecurringTransaction recurring;
  final bool isDark;
  final VoidCallback onTap;

  const _RecurringCard({
    required this.recurring,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = recurring.type == RecurringType.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    // Get category info
    final category = isIncome
        ? _getIncomeCategory(ref, recurring.categoryId)
        : _getExpenseCategory(ref, recurring.categoryId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: recurring.isDue
                ? AppColors.warning.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: recurring.isDue ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                // Name and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recurring.name,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${CurrencyFormatter.format(recurring.amount)}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recurring.frequency.label,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            // Next due date
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: recurring.isDue
                      ? AppColors.warning
                      : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                ),
                const SizedBox(width: 6),
                Text(
                  _getNextDueDateText(),
                  style: AppTypography.bodySmall.copyWith(
                    color: recurring.isDue
                        ? AppColors.warning
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    fontWeight: recurring.isDue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (!recurring.isActive) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.pause, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Paused',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getNextDueDateText() {
    final days = recurring.daysUntilDue;
    if (days < 0) {
      return 'Overdue by ${-days} day${-days > 1 ? 's' : ''}';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else if (days <= 7) {
      return 'Due in $days days';
    } else {
      final date = recurring.nextDueDate;
      return 'Due ${date.day}/${date.month}/${date.year}';
    }
  }

  dynamic _getIncomeCategory(WidgetRef ref, String categoryId) {
    final allCategories = ref.watch(allIncomeCategoriesProvider);
    return allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => IncomeCategories.other,
    );
  }

  dynamic _getExpenseCategory(WidgetRef ref, String categoryId) {
    final allCategories = ref.watch(allExpenseCategoriesProvider);
    return allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => ExpenseCategories.other,
    );
  }
}

/// Pending Transactions Screen - Shows due recurring transactions for user confirmation
class PendingTransactionsScreen extends ConsumerWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueTransactions = ref.watch(dueRecurringTransactionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n?.pendingTransactions ?? 'Pending Transactions'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      body: dueTransactions.isEmpty
          ? _NoPendingState(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              itemCount: dueTransactions.length,
              itemBuilder: (context, index) {
                final recurring = dueTransactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                  child: _PendingTransactionCard(
                    recurring: recurring,
                    isDark: isDark,
                    onConfirm: () => _confirmTransaction(context, ref, recurring),
                    onSkip: () => _skipTransaction(context, ref, recurring),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmTransaction(BuildContext context, WidgetRef ref, RecurringTransaction recurring) async {
    final now = DateTime.now();
    // Create the actual transaction
    if (recurring.type == RecurringType.income) {
      // Create income source entry (matches IncomeSource model like Expense)
      final income = IncomeSource(
        id: 'income_${now.millisecondsSinceEpoch}',
        sourceName: recurring.name,
        amount: recurring.amount,
        categoryId: recurring.categoryId,
        date: now,
        paymentMethodId: recurring.paymentMethodId,
        bankAccountId: recurring.bankAccountId,
        description: recurring.description,
        notes: null,
        isRecurring: true, // Mark as from recurring
        recurringTransactionId: recurring.id, // Link to recurring transaction
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(incomeSourcesProvider.notifier).addSource(income);
    } else {
      // Create expense transaction
      final expense = Expense(
        id: 'expense_${DateTime.now().millisecondsSinceEpoch}',
        name: recurring.name,
        amount: recurring.amount,
        categoryId: recurring.categoryId,
        date: DateTime.now(),
        paymentMethodId: recurring.paymentMethodId ?? '',
        bankAccountId: recurring.bankAccountId,
        description: recurring.description,
        merchantName: recurring.merchantName,
        isRecurring: true,
        recurringTransactionId: recurring.id, // Link to recurring transaction
        recurringFrequency: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(expensesProvider.notifier).addExpense(expense);

      // Check budget and send notification if threshold crossed
      await _checkBudgetAndNotify(expense, ref);
    }

    // Mark the recurring transaction as processed (advances next due date)
    await ref.read(recurringTransactionsProvider.notifier).processRecurring(recurring.id);

    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.transactionAdded ?? '${recurring.type.label} "${recurring.name}" added!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _skipTransaction(BuildContext context, WidgetRef ref, RecurringTransaction recurring) async {
    // Just advance the next due date without creating a transaction
    await ref.read(recurringTransactionsProvider.notifier).processRecurring(recurring.id);

    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.skippedForThisPeriod ?? 'Skipped "${recurring.name}" for this period'),
        ),
      );
    }
  }

  /// Check budget and send notification if threshold crossed
  Future<void> _checkBudgetAndNotify(Expense expense, WidgetRef ref) async {
    try {
      final budgets = ref.read(budgetsProvider);
      final now = DateTime.now();

      final budget = budgets.where(
        (b) => b.categoryId == expense.categoryId &&
               b.month == now.month &&
               b.year == now.year,
      ).firstOrNull;

      if (budget == null) return;

      final expenses = ref.read(expensesProvider);
      final monthlyExpenses = expenses.where(
        (e) => e.categoryId == expense.categoryId &&
               e.date.month == now.month &&
               e.date.year == now.year,
      );
      final totalSpent = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);

      final categories = ref.read(allExpenseCategoriesProvider);
      final category = categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => categories.first,
      );

      await NotificationService.instance.checkAndNotifyBudget(
        categoryId: expense.categoryId,
        categoryName: category.name,
        spent: totalSpent,
        budget: budget.amount,
      );
    } catch (e) {
      debugPrint('Error checking budget for notification: $e');
    }
  }
}

/// No Pending State
class _NoPendingState extends StatelessWidget {
  final bool isDark;

  const _NoPendingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            l10n?.allLookingGood ?? 'All Caught Up!',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'No pending transactions to confirm',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pending Transaction Card
class _PendingTransactionCard extends ConsumerWidget {
  final RecurringTransaction recurring;
  final bool isDark;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  const _PendingTransactionCard({
    required this.recurring,
    required this.isDark,
    required this.onConfirm,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isIncome = recurring.type == RecurringType.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    // Get category info
    final category = isIncome
        ? _getIncomeCategory(ref, recurring.categoryId)
        : _getExpenseCategory(ref, recurring.categoryId);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recurring.type.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (recurring.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Overdue',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Main content
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing12),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(category.icon, color: category.color, size: 24),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurring.name,
                      style: AppTypography.h4.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Amount
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacing12,
              horizontal: AppDimensions.spacing16,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(recurring.amount)}',
                  style: AppTypography.h2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Details
          _DetailRow(
            icon: LucideIcons.repeat,
            label: l10n?.frequency ?? 'Frequency',
            value: recurring.frequency.label,
            isDark: isDark,
          ),
          if (recurring.merchantName != null) ...[
            const SizedBox(height: AppDimensions.spacing8),
            _DetailRow(
              icon: LucideIcons.store,
              label: l10n?.merchant ?? 'Merchant',
              value: recurring.merchantName!,
              isDark: isDark,
            ),
          ],
          if (recurring.description != null) ...[
            const SizedBox(height: AppDimensions.spacing8),
            _DetailRow(
              icon: LucideIcons.fileText,
              label: l10n?.notes ?? 'Note',
              value: recurring.description!,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: AppDimensions.spacing20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSkip,
                  icon: Icon(LucideIcons.skipForward, size: 18),
                  label: Text(l10n?.skip ?? 'Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: Icon(LucideIcons.check, size: 18, color: Colors.white),
                  label: Text(
                    isIncome ? (l10n?.addIncome ?? 'Add Income') : (l10n?.addExpense ?? 'Add Expense'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  dynamic _getIncomeCategory(WidgetRef ref, String categoryId) {
    final allCategories = ref.watch(allIncomeCategoriesProvider);
    return allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => IncomeCategories.other,
    );
  }

  dynamic _getExpenseCategory(WidgetRef ref, String categoryId) {
    final allCategories = ref.watch(allExpenseCategoriesProvider);
    return allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => ExpenseCategories.other,
    );
  }
}

/// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
