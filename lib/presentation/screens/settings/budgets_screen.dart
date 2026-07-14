import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../data/models/budget.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/expense.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/currency_provider.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import '../../widgets/common/banner_ad_widget.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  String _getMonthName(int month, AppLocalizations? l10n) {
    final months = [
      l10n?.january ?? 'January',
      l10n?.february ?? 'February',
      l10n?.march ?? 'March',
      l10n?.april ?? 'April',
      l10n?.may ?? 'May',
      l10n?.june ?? 'June',
      l10n?.july ?? 'July',
      l10n?.august ?? 'August',
      l10n?.september ?? 'September',
      l10n?.october ?? 'October',
      l10n?.november ?? 'November',
      l10n?.december ?? 'December'
    ];
    return months[month - 1];
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgets = ref.watch(budgetsProvider);
    // Filter out "Other" category since it's for uncategorized expenses
    final allCategories = ref.watch(allExpenseCategoriesProvider)
        .where((c) => c.id != 'other')
        .toList();
    final expenses = ref.watch(expensesProvider);

    // Get default currency for new budgets
    final defaultCurrency = ref.watch(currencyProvider);
    final defaultCurrencyCode = defaultCurrency.code;

    // Filter budgets for selected month (only show budgets in default currency)
    final monthBudgets = budgets
        .where((b) => b.month == _selectedMonth &&
                      b.year == _selectedYear &&
                      b.currencyCode == defaultCurrencyCode)
        .toList();

    // Calculate spending for selected month
    final monthStart = DateTime(_selectedYear, _selectedMonth, 1);
    final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);
    final monthExpenses = expenses.where(
      (e) => e.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
             e.date.isBefore(monthEnd.add(const Duration(seconds: 1))),
    ).toList();

    // Calculate spending by category, but only for expenses matching the default currency
    final spendingByCategory = <String, double>{};
    for (final expense in monthExpenses) {
      // Only count expenses in the default currency towards budget
      if (expense.currencyCode == defaultCurrencyCode) {
        spendingByCategory[expense.categoryId] =
            (spendingByCategory[expense.categoryId] ?? 0) + expense.amount;
      }
    }

    // Build budget map for quick lookup
    final budgetMap = <String, CategoryBudget>{};
    for (final budget in monthBudgets) {
      budgetMap[budget.categoryId] = budget;
    }

    // Calculate totals (only for default currency)
    final totalBudgeted = monthBudgets.fold(0.0, (sum, b) => sum + b.amount);
    final currencyFilteredExpenses = monthExpenses.where((e) => e.currencyCode == defaultCurrencyCode);
    final totalSpent = currencyFilteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final isPremium = ref.watch(isPremiumProvider);
    final limit = FreeTierLimits.budgets;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.budgets ?? 'Budgets'),
        actions: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: monthBudgets.length >= limit
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${monthBudgets.length}/$limit',
                    style: AppTypography.labelSmall.copyWith(
                      color: monthBudgets.length >= limit
                          ? AppColors.warning
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(LucideIcons.copy),
            tooltip: l10n?.copyFromPreviousMonth ?? 'Copy from previous month',
            onPressed: () => _copyFromPreviousMonth(context, l10n),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_getMonthName(_selectedMonth, l10n)} $_selectedYear',
                  style: AppTypography.h4.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.all(AppDimensions.spacing16),
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SummaryItem(
                      label: l10n?.budgeted ?? 'Budgeted',
                      amount: totalBudgeted,
                      color: Colors.white,
                      currencySymbol: defaultCurrency.symbol,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _SummaryItem(
                      label: l10n?.spent ?? 'Spent',
                      amount: totalSpent,
                      color: Colors.white,
                      currencySymbol: defaultCurrency.symbol,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _SummaryItem(
                      label: l10n?.remaining ?? 'Remaining',
                      amount: totalBudgeted - totalSpent,
                      color: totalSpent > totalBudgeted
                          ? AppColors.error
                          : Colors.white,
                      currencySymbol: defaultCurrency.symbol,
                    ),
                  ],
                ),
                if (totalBudgeted > 0) ...[
                  const SizedBox(height: AppDimensions.spacing12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (totalSpent / totalBudgeted).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalSpent > totalBudgeted
                                ? AppColors.error
                                : Colors.white,
                          ),
                          minHeight: 6,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  Text(
                    l10n?.percentUsed(((totalSpent / totalBudgeted) * 100).toStringAsFixed(1)) ??
                        '${((totalSpent / totalBudgeted) * 100).toStringAsFixed(1)}% used',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing16,
              ),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final category = allCategories[index];
                final budget = budgetMap[category.id];
                final spent = spendingByCategory[category.id] ?? 0;

                return _BudgetCategoryTile(
                  category: category,
                  budgetAmount: budget?.amount ?? 0,
                  spentAmount: spent,
                  isDark: isDark,
                  currencySymbol: defaultCurrency.symbol,
                  onTap: () => _showSetBudgetSheet(context, category, budget, l10n),
                  l10n: l10n,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSetBudgetSheet(
    BuildContext context,
    ExpenseCategory category,
    CategoryBudget? currentBudget,
    AppLocalizations? l10n,
  ) {
    // Check premium limit for adding new budget (not editing existing)
    if (currentBudget == null) {
      final allBudgets = ref.read(budgetsProvider);
      final monthBudgets = allBudgets
          .where((b) => b.month == _selectedMonth && b.year == _selectedYear)
          .toList();
      final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
        PremiumFeature.unlimitedBudgets,
        monthBudgets.length,
      );

      if (!canAdd) {
        UpgradeDialog.show(
          context,
          feature: PremiumFeature.unlimitedBudgets,
          currentCount: monthBudgets.length,
          limit: FreeTierLimits.budgets,
        );
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SetBudgetSheet(
        category: category,
        currentAmount: currentBudget?.amount ?? 0,
        month: _selectedMonth,
        year: _selectedYear,
        currencyCode: ref.read(currencyProvider).code,
        l10n: l10n,
        onSave: (amount) async {
          if (amount > 0) {
            await ref.read(budgetsProvider.notifier).setBudgetForCategory(
              categoryId: category.id,
              amount: amount,
              month: _selectedMonth,
              year: _selectedYear,
              currencyCode: ref.read(currencyProvider).code,
            );
          } else if (currentBudget != null) {
            // Remove budget if amount is 0
            await ref.read(budgetsProvider.notifier).deleteBudget(currentBudget.id);
          }
        },
      ),
    );
  }

  void _copyFromPreviousMonth(BuildContext context, AppLocalizations? l10n) async {
    final prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    final prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;

    final budgets = ref.read(budgetsProvider);
    final prevBudgets = budgets
        .where((b) => b.month == prevMonth && b.year == prevYear)
        .toList();

    if (prevBudgets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.noBudgetsFoundFor(_getMonthName(prevMonth, l10n), prevYear.toString()) ??
                'No budgets found for ${_getMonthName(prevMonth, l10n)} $prevYear'),
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.copyBudgets ?? 'Copy Budgets'),
        content: Text(
          l10n?.copyBudgetsConfirm(prevBudgets.length.toString(), _getMonthName(prevMonth, l10n), prevYear.toString(), _getMonthName(_selectedMonth, l10n), _selectedYear.toString()) ??
          'Copy ${prevBudgets.length} budget(s) from ${_getMonthName(prevMonth, l10n)} $prevYear to ${_getMonthName(_selectedMonth, l10n)} $_selectedYear?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.copy ?? 'Copy'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(budgetsProvider.notifier).copyBudgetsToMonth(
        prevMonth,
        prevYear,
        _selectedMonth,
        _selectedYear,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.copiedBudgets(prevBudgets.length) ?? 'Copied ${prevBudgets.length} budget(s)'),
          ),
        );
      }
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currencySymbol;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    this.currencySymbol = '₹',
  });

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currencySymbol${_formatAmount(amount)}',
          style: AppTypography.h4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  final ExpenseCategory category;
  final double budgetAmount;
  final double spentAmount;
  final bool isDark;
  final String currencySymbol;
  final VoidCallback onTap;
  final AppLocalizations? l10n;

  const _BudgetCategoryTile({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.isDark,
    this.currencySymbol = '₹',
    required this.onTap,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasbudget = budgetAmount > 0;
    final percentUsed = hasbudget ? (spentAmount / budgetAmount) : 0.0;
    final isOverBudget = spentAmount > budgetAmount && hasbudget;
    final isNearLimit = percentUsed >= 0.8 && !isOverBudget && hasbudget;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isOverBudget
              ? AppColors.error.withValues(alpha: 0.5)
              : isNearLimit
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (hasbudget)
                            Text(
                              '$currencySymbol${spentAmount.toStringAsFixed(0)} of $currencySymbol${budgetAmount.toStringAsFixed(0)}',
                              style: AppTypography.caption.copyWith(
                                color: isOverBudget
                                    ? AppColors.error
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            )
                          else
                            Text(
                              l10n?.noBudgetSet ?? 'No budget set',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasbudget) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(percentUsed * 100).toStringAsFixed(0)}%',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOverBudget
                                  ? AppColors.error
                                  : isNearLimit
                                      ? AppColors.warning
                                      : AppColors.success,
                            ),
                          ),
                          if (isOverBudget)
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.alertTriangle,
                                  size: 12,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n?.over ?? 'Over',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ] else
                      Icon(
                        LucideIcons.plus,
                        size: 20,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                  ],
                ),
                if (hasbudget) ...[
                  const SizedBox(height: AppDimensions.spacing12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percentUsed.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverBudget
                                ? AppColors.error
                                : isNearLimit
                                    ? AppColors.warning
                                    : category.color,
                          ),
                          minHeight: 6,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetBudgetSheet extends StatefulWidget {
  final ExpenseCategory category;
  final double currentAmount;
  final int month;
  final int year;
  final String currencyCode;
  final Future<void> Function(double amount) onSave;
  final AppLocalizations? l10n;

  const _SetBudgetSheet({
    required this.category,
    required this.currentAmount,
    required this.month,
    required this.year,
    required this.currencyCode,
    required this.onSave,
    this.l10n,
  });

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAmount > 0 ? widget.currentAmount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getMonthName(int month) {
    final l10n = widget.l10n;
    final months = [
      l10n?.january ?? 'January',
      l10n?.february ?? 'February',
      l10n?.march ?? 'March',
      l10n?.april ?? 'April',
      l10n?.may ?? 'May',
      l10n?.june ?? 'June',
      l10n?.july ?? 'July',
      l10n?.august ?? 'August',
      l10n?.september ?? 'September',
      l10n?.october ?? 'October',
      l10n?.november ?? 'November',
      l10n?.december ?? 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    widget.category.icon,
                    color: widget.category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n?.setBudget ?? 'Set Budget',
                        style: AppTypography.h4.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${widget.category.name} - ${_getMonthName(widget.month)} ${widget.year}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // Amount Input
            Text(
              widget.l10n?.monthlyBudgetCurrency(widget.currencyCode) ?? 'Monthly Budget (${widget.currencyCode})',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '${Currencies.getByCode(widget.currencyCode).symbol} ',
                hintText: widget.l10n?.enterBudgetAmount ?? 'Enter budget amount',
                suffixIcon: widget.currentAmount > 0
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _controller.clear();
                        },
                      )
                    : null,
              ),
            ),

            const SizedBox(height: AppDimensions.spacing8),
            Text(
              widget.l10n?.setTo0ToRemoveBudget ?? 'Set to 0 or empty to remove budget for this category',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // Quick Amount Buttons
            Text(
              widget.l10n?.quickSet ?? 'Quick Set',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Wrap(
              spacing: AppDimensions.spacing8,
              runSpacing: AppDimensions.spacing8,
              children: [1000, 2000, 5000, 10000, 15000, 20000, 25000, 50000]
                  .map((amount) => _QuickAmountChip(
                        amount: amount.toDouble(),
                        currencySymbol: Currencies.getByCode(widget.currencyCode).symbol,
                        onTap: () {
                          _controller.text = amount.toString();
                        },
                      ))
                  .toList(),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        final amount = double.tryParse(_controller.text) ?? 0;
                        await widget.onSave(amount);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                amount > 0
                                    ? (widget.l10n?.budgetSetFor(widget.category.name) ?? 'Budget set for ${widget.category.name}')
                                    : (widget.l10n?.budgetRemovedFor(widget.category.name) ?? 'Budget removed for ${widget.category.name}'),
                              ),
                            ),
                          );
                        }
                      },
                child: Text(_isSaving ? (widget.l10n?.saving ?? 'Saving...') : (widget.l10n?.saveBudget ?? 'Save Budget')),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final double amount;
  final String currencySymbol;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.amount,
    this.currencySymbol = '₹',
    required this.onTap,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '$currencySymbol${_formatAmount(amount)}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
