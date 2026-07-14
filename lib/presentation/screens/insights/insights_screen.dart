import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/income.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/bank_account.dart';
import '../../../data/models/budget.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/auto_scroll_text.dart';
import '../../widgets/common/upgrade_dialog.dart';
import '../../widgets/common/premium_blur_overlay.dart';
import '../../widgets/common/banner_ad_widget.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/health_score_calculator.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  int _touchedPieIndex = -1;

  // Filters
  String? _selectedPaymentMethodId;
  String? _selectedBankAccountId;
  Set<String> _selectedCategoryIds = {};
  bool _showFilters = false;

  // Comparison
  late TabController _comparisonTabController;
  List<String> _comparisonPaymentMethods = [];
  List<String> _comparisonMerchants = [];
  List<String> _comparisonCategories = [];

  // Pie Chart toggle (expense vs income)
  bool _showExpensePieChart = true; // true = expenses, false = income
  Set<String> _selectedPieCategories = {}; // Empty means all categories

  // Spending Patterns
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _comparisonTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _comparisonTabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1, 1))) {
      setState(() {
        _selectedMonth = nextMonth;
      });
    }
  }

  String _getMonthYear() {
    return DateFormat('MMMM yyyy').format(_selectedMonth);
  }

  List<Expense> _getMonthExpenses(List<Expense> allExpenses) {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    return allExpenses.where((e) =>
      e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
      e.date.isBefore(end.add(const Duration(seconds: 1)))
    ).toList();
  }

  List<IncomeSource> _getMonthIncome(List<IncomeSource> allIncome) {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    return allIncome.where((i) =>
      i.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
      i.date.isBefore(end.add(const Duration(seconds: 1)))
    ).toList();
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    var filtered = expenses;

    if (_selectedPaymentMethodId != null) {
      filtered = filtered.where((e) => e.paymentMethodId == _selectedPaymentMethodId).toList();
    }

    if (_selectedBankAccountId != null) {
      filtered = filtered.where((e) => e.bankAccountId == _selectedBankAccountId).toList();
    }

    if (_selectedCategoryIds.isNotEmpty) {
      filtered = filtered.where((e) => _selectedCategoryIds.contains(e.categoryId)).toList();
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _selectedPaymentMethodId = null;
      _selectedBankAccountId = null;
      _selectedCategoryIds = {};
    });
  }

  bool get _hasActiveFilters =>
    _selectedPaymentMethodId != null ||
    _selectedBankAccountId != null ||
    _selectedCategoryIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allIncomeSources = ref.watch(incomeSourcesProvider);
    final allExpenses = ref.watch(expensesProvider);
    final customCategories = ref.watch(customExpenseCategoriesProvider);
    final customIncomeCategories = ref.watch(customIncomeCategoriesProvider);
    final paymentMethods = ref.watch(paymentMethodsProvider);
    final bankAccounts = ref.watch(bankAccountsProvider);
    final budgets = ref.watch(budgetsProvider);
    final merchants = ref.watch(merchantsProvider);

    final monthExpenses = _getMonthExpenses(allExpenses);
    final monthIncome = _getMonthIncome(allIncomeSources);

    // Sum all amounts regardless of currency - currency is just for UI display
    final filteredExpenses = _applyFilters(monthExpenses);

    return Scaffold(
      body: SafeArea(
        child: PremiumBlurOverlay(
          featureName: l10n?.advancedInsights ?? 'Advanced Insights',
          description: l10n?.getDetailedAnalytics ?? 'Get detailed analytics, spending patterns, and financial health scores',
          child: CustomScrollView(
          slivers: [
            // Header with Month Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.insights ?? 'Insights',
                      style: AppTypography.h2.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        // Filter Button (Premium Feature)
                        GestureDetector(
                          onTap: () {
                            final isPremium = ref.read(isPremiumProvider);
                            if (!isPremium) {
                              UpgradeDialog.show(context, feature: PremiumFeature.advancedInsights);
                              return;
                            }
                            setState(() => _showFilters = !_showFilters);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _hasActiveFilters
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : (isDark ? AppColors.darkCard : AppColors.lightCard),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _hasActiveFilters
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.filter,
                                  size: 16,
                                  color: _hasActiveFilters
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${(_selectedPaymentMethodId != null ? 1 : 0) + (_selectedBankAccountId != null ? 1 : 0) + _selectedCategoryIds.length}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MonthSelector(
                          isDark: isDark,
                          monthYear: _getMonthYear(),
                          onPrevious: _previousMonth,
                          onNext: _nextMonth,
                          canGoNext: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1)
                              .isBefore(DateTime(DateTime.now().year, DateTime.now().month + 1, 1)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filters Section (Collapsible)
            if (_showFilters) ...[
              SliverToBoxAdapter(
                child: _FiltersSection(
                  isDark: isDark,
                  l10n: l10n,
                  paymentMethods: paymentMethods,
                  bankAccounts: bankAccounts,
                  customCategories: customCategories,
                  selectedPaymentMethodId: _selectedPaymentMethodId,
                  selectedBankAccountId: _selectedBankAccountId,
                  selectedCategoryIds: _selectedCategoryIds,
                  onPaymentMethodChanged: (id) => setState(() => _selectedPaymentMethodId = id),
                  onBankAccountChanged: (id) => setState(() => _selectedBankAccountId = id),
                  onCategoryToggled: (id) {
                    setState(() {
                      if (_selectedCategoryIds.contains(id)) {
                        _selectedCategoryIds.remove(id);
                      } else {
                        _selectedCategoryIds.add(id);
                      }
                    });
                  },
                  onClearFilters: _clearFilters,
                  hasActiveFilters: _hasActiveFilters,
                ),
              ),
              // Gap between filter section and summary boxes
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing16)),
            ],

            // Quick Stats Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _QuickStatsSummary(
                  isDark: isDark,
                  l10n: l10n,
                  monthIncome: monthIncome,
                  monthExpenses: filteredExpenses,
                  isFiltered: _hasActiveFilters,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Financial Health Score
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _FinancialHealthCard(
                  isDark: isDark,
                  l10n: l10n,
                  incomeSources: monthIncome,
                  expenses: filteredExpenses,
                  allExpenses: allExpenses,
                  budgets: budgets.where((b) =>
                    b.month == _selectedMonth.month && b.year == _selectedMonth.year
                  ).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Comparison Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(
                  title: l10n?.compareAndAnalyze ?? 'Compare & Analyze',
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'NEW',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: _ComparisonSection(
                isDark: isDark,
                l10n: l10n,
                expenses: monthExpenses,
                paymentMethods: paymentMethods,
                bankAccounts: bankAccounts,
                customCategories: customCategories,
                merchants: merchants,
                tabController: _comparisonTabController,
                selectedPaymentMethods: _comparisonPaymentMethods,
                selectedMerchants: _comparisonMerchants,
                selectedCategories: _comparisonCategories,
                onPaymentMethodsChanged: (list) => setState(() => _comparisonPaymentMethods = list),
                onMerchantsChanged: (list) => setState(() => _comparisonMerchants = list),
                onCategoriesChanged: (list) => setState(() => _comparisonCategories = list),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Category Pie Chart with Income/Expense Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader(title: _showExpensePieChart ? (l10n?.expensesByCategory ?? 'Expenses by Category') : (l10n?.incomeByCategory ?? 'Income by Category'), isDark: isDark),
                    // Toggle button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _showExpensePieChart = true;
                              _selectedPieCategories = {};
                              _touchedPieIndex = -1;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _showExpensePieChart ? AppColors.error.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              ),
                              child: Text(
                                l10n?.expense ?? 'Expense',
                                style: AppTypography.labelSmall.copyWith(
                                  color: _showExpensePieChart ? AppColors.error : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontWeight: _showExpensePieChart ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _showExpensePieChart = false;
                              _selectedPieCategories = {};
                              _touchedPieIndex = -1;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_showExpensePieChart ? AppColors.success.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              child: Text(
                                l10n?.income ?? 'Income',
                                style: AppTypography.labelSmall.copyWith(
                                  color: !_showExpensePieChart ? AppColors.success : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontWeight: !_showExpensePieChart ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _CategoryPieChartWithSelection(
                  isDark: isDark,
                  l10n: l10n,
                  showExpenses: _showExpensePieChart,
                  expenses: filteredExpenses,
                  income: monthIncome,
                  customExpenseCategories: customCategories,
                  customIncomeCategories: customIncomeCategories,
                  touchedIndex: _touchedPieIndex,
                  onTouch: (index) => setState(() => _touchedPieIndex = index),
                  selectedCategories: _selectedPieCategories,
                  onCategoryToggle: (categoryId) => setState(() {
                    if (_selectedPieCategories.contains(categoryId)) {
                      _selectedPieCategories.remove(categoryId);
                    } else {
                      _selectedPieCategories.add(categoryId);
                    }
                    _touchedPieIndex = -1;
                  }),
                  onClearSelection: () => setState(() {
                    _selectedPieCategories = {};
                    _touchedPieIndex = -1;
                  }),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Bank Account Analysis
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(title: l10n?.bankAccountAnalysis ?? 'Bank Account Analysis', isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _BankAccountAnalysis(
                  isDark: isDark,
                  l10n: l10n,
                  expenses: monthExpenses,
                  income: monthIncome,
                  bankAccounts: bankAccounts,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Monthly Trend - Bar Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(title: l10n?.sixMonthTrend ?? '6-Month Trend', isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _MonthlyTrendChart(
                  isDark: isDark,
                  l10n: l10n,
                  allExpenses: allExpenses,
                  allIncome: allIncomeSources,
                  currentMonth: _selectedMonth,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // AI Insights
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: Row(
                  children: [
                    _SectionHeader(title: l10n?.aiInsights ?? 'AI Insights', isDark: isDark),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AI',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: _AIInsightsSection(
                isDark: isDark,
                l10n: l10n,
                expenses: filteredExpenses,
                allExpenses: allExpenses,
                incomeSources: monthIncome,
                customCategories: customCategories,
                budgets: budgets,
                selectedMonth: _selectedMonth,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Spending Patterns - Interactive Daily View
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(title: l10n?.dailySpendingPattern ?? 'Daily Spending Pattern', isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _InteractiveSpendingPatternsCard(
                  isDark: isDark,
                  l10n: l10n,
                  expenses: filteredExpenses,
                  selectedMonth: _selectedMonth,
                  selectedDayIndex: _selectedDayIndex,
                  onDaySelected: (index) => setState(() {
                    _selectedDayIndex = _selectedDayIndex == index ? null : index;
                  }),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Payment Method Analysis
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(title: l10n?.paymentMethods ?? 'Payment Methods', isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _PaymentMethodAnalysis(
                  isDark: isDark,
                  l10n: l10n,
                  expenses: filteredExpenses,
                  paymentMethods: paymentMethods,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Merchant Analysis
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(title: l10n?.topMerchants ?? 'Top Merchants', isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _MerchantAnalysis(
                  isDark: isDark,
                  l10n: l10n,
                  expenses: filteredExpenses,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing24)),

            // Daily Spending Line Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _SectionHeader(title: l10n?.dailySpending ?? 'Daily Spending', isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
                child: _DailySpendingChart(
                  isDark: isDark,
                  l10n: l10n,
                  expenses: filteredExpenses,
                  selectedMonth: _selectedMonth,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing32)),
          ],
        ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

// ============================================
// Filters Section
// ============================================

class _FiltersSection extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<PaymentMethod> paymentMethods;
  final List<BankAccount> bankAccounts;
  final List<ExpenseCategory> customCategories;
  final String? selectedPaymentMethodId;
  final String? selectedBankAccountId;
  final Set<String> selectedCategoryIds;
  final Function(String?) onPaymentMethodChanged;
  final Function(String?) onBankAccountChanged;
  final Function(String) onCategoryToggled;
  final VoidCallback onClearFilters;
  final bool hasActiveFilters;

  const _FiltersSection({
    required this.isDark,
    required this.l10n,
    required this.paymentMethods,
    required this.bankAccounts,
    required this.customCategories,
    required this.selectedPaymentMethodId,
    required this.selectedBankAccountId,
    required this.selectedCategoryIds,
    required this.onPaymentMethodChanged,
    required this.onBankAccountChanged,
    required this.onCategoryToggled,
    required this.onClearFilters,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    final allCategories = [...ExpenseCategories.all, ...customCategories];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.filters ?? 'Filters',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasActiveFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: Text(
                    l10n?.clearAll ?? 'Clear All',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment Method Filter
          Text(
            l10n?.paymentMethod ?? 'Payment Method',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n?.all ?? 'All',
                  isSelected: selectedPaymentMethodId == null,
                  onTap: () => onPaymentMethodChanged(null),
                  isDark: isDark,
                ),
                ...paymentMethods.map((method) => _FilterChip(
                  label: method.name,
                  isSelected: selectedPaymentMethodId == method.id,
                  onTap: () => onPaymentMethodChanged(
                    selectedPaymentMethodId == method.id ? null : method.id
                  ),
                  isDark: isDark,
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bank Account Filter
          Text(
            l10n?.bankAccount ?? 'Bank Account',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n?.all ?? 'All',
                  isSelected: selectedBankAccountId == null,
                  onTap: () => onBankAccountChanged(null),
                  isDark: isDark,
                ),
                ...bankAccounts.map((account) => _BankAccountFilterChip(
                  bankName: account.bankName,
                  accountType: account.accountTypeLabel,
                  isSelected: selectedBankAccountId == account.id,
                  onTap: () => onBankAccountChanged(
                    selectedBankAccountId == account.id ? null : account.id
                  ),
                  isDark: isDark,
                  color: account.color,
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Filter
          Text(
            l10n?.selectCategories ?? 'Categories (select multiple)',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCategories.map((category) => _FilterChip(
              label: category.name,
              isSelected: selectedCategoryIds.contains(category.id),
              onTap: () => onCategoryToggled(category.id),
              isDark: isDark,
              color: category.color,
              showCheck: true,
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;
  final bool showCheck;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.color,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
            ? (color ?? AppColors.primary).withValues(alpha: 0.2)
            : (isDark ? AppColors.darkSurface : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
              ? (color ?? AppColors.primary)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck && isSelected) ...[
              Icon(LucideIcons.check, size: 12, color: color ?? AppColors.primary),
              const SizedBox(width: 4),
            ],
            if (color != null && !isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                  ? (color ?? AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bank Account Filter Chip with Auto-Scroll
class _BankAccountFilterChip extends StatelessWidget {
  final String bankName;
  final String accountType;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  const _BankAccountFilterChip({
    required this.bankName,
    required this.accountType,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 120),
        decoration: BoxDecoration(
          color: isSelected
            ? color.withValues(alpha: 0.2)
            : (isDark ? AppColors.darkSurface : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: SizedBox(
                width: 80,
                child: AutoScrollText(
                  text: '$bankName ($accountType)',
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                      ? color
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Comparison Section
// ============================================

class _ComparisonSection extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;
  final List<PaymentMethod> paymentMethods;
  final List<BankAccount> bankAccounts;
  final List<ExpenseCategory> customCategories;
  final List<String> merchants;
  final TabController tabController;
  final List<String> selectedPaymentMethods;
  final List<String> selectedMerchants;
  final List<String> selectedCategories;
  final Function(List<String>) onPaymentMethodsChanged;
  final Function(List<String>) onMerchantsChanged;
  final Function(List<String>) onCategoriesChanged;

  const _ComparisonSection({
    required this.isDark,
    required this.l10n,
    required this.expenses,
    required this.paymentMethods,
    required this.bankAccounts,
    required this.customCategories,
    required this.merchants,
    required this.tabController,
    required this.selectedPaymentMethods,
    required this.selectedMerchants,
    required this.selectedCategories,
    required this.onPaymentMethodsChanged,
    required this.onMerchantsChanged,
    required this.onCategoriesChanged,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingHorizontal),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.cardRadius)),
            ),
            child: TabBar(
              controller: tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTypography.labelMedium,
              tabs: [
                Tab(text: l10n?.payment ?? 'Payment'),
                Tab(text: l10n?.merchant ?? 'Merchant'),
                Tab(text: l10n?.category ?? 'Category'),
              ],
            ),
          ),
          // Tab Content
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: tabController,
              children: [
                // Payment Methods Comparison
                _ComparisonTab(
                  isDark: isDark,
                  l10n: l10n,
                  title: l10n?.comparePayment ?? 'Compare Payment Methods',
                  items: paymentMethods.map((m) => _ComparisonItem(m.id, m.name, m.type.icon)).toList(),
                  selectedIds: selectedPaymentMethods,
                  onSelectionChanged: onPaymentMethodsChanged,
                  expenses: expenses,
                  getExpenseFilter: (id) => (e) => e.paymentMethodId == id,
                  formatAmount: _formatAmount,
                ),
                // Merchants Comparison
                _ComparisonTab(
                  isDark: isDark,
                  l10n: l10n,
                  title: l10n?.compareMerchant ?? 'Compare Merchants',
                  items: _getUniqueMerchants(expenses).map((m) => _ComparisonItem(m, m, LucideIcons.store)).toList(),
                  selectedIds: selectedMerchants,
                  onSelectionChanged: onMerchantsChanged,
                  expenses: expenses,
                  getExpenseFilter: (id) => (e) => e.merchantName == id,
                  formatAmount: _formatAmount,
                ),
                // Categories Comparison
                _ComparisonTab(
                  isDark: isDark,
                  l10n: l10n,
                  title: l10n?.compareCategory ?? 'Compare Categories',
                  items: [...ExpenseCategories.all, ...customCategories]
                      .map((c) => _ComparisonItem(c.id, c.name, c.icon, c.color))
                      .toList(),
                  selectedIds: selectedCategories,
                  onSelectionChanged: onCategoriesChanged,
                  expenses: expenses,
                  getExpenseFilter: (id) => (e) => e.categoryId == id,
                  formatAmount: _formatAmount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueMerchants(List<Expense> expenses) {
    final merchantSet = <String>{};
    for (final e in expenses) {
      if (e.merchantName != null && e.merchantName!.isNotEmpty) {
        merchantSet.add(e.merchantName!);
      }
    }
    return merchantSet.toList()..sort();
  }
}

class _ComparisonItem {
  final String id;
  final String name;
  final IconData icon;
  final Color? color;

  _ComparisonItem(this.id, this.name, this.icon, [this.color]);
}

class _ComparisonTab extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final String title;
  final List<_ComparisonItem> items;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;
  final List<Expense> expenses;
  final bool Function(Expense) Function(String) getExpenseFilter;
  final String Function(double) formatAmount;

  const _ComparisonTab({
    required this.isDark,
    required this.l10n,
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.expenses,
    required this.getExpenseFilter,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals for selected items
    final comparisonData = <String, double>{};
    for (final id in selectedIds) {
      final filtered = expenses.where(getExpenseFilter(id)).toList();
      comparisonData[id] = filtered.fold<double>(0, (sum, e) => sum + e.amount);
    }

    final maxAmount = comparisonData.values.isEmpty ? 0.0 : comparisonData.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Selection chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIds.contains(item.id);
                return GestureDetector(
                  onTap: () {
                    final newList = List<String>.from(selectedIds);
                    if (isSelected) {
                      newList.remove(item.id);
                    } else if (newList.length < 4) {
                      newList.add(item.id);
                    } else {
                      // Show snackbar when trying to select 5th item
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.maxItemsCompareError ?? 'Maximum 4 items can be compared at a time'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                      return;
                    }
                    onSelectionChanged(newList);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? (item.color ?? AppColors.primary).withValues(alpha: 0.2)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                          ? (item.color ?? AppColors.primary)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 14, color: item.color ?? AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          item.name,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                              ? (item.color ?? AppColors.primary)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Comparison bars
          Expanded(
            child: selectedIds.isEmpty
              ? Center(
                  child: Text(
                    l10n?.selectUpTo4Items ?? 'Select up to 4 items to compare',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: selectedIds.length,
                  itemBuilder: (context, index) {
                    final id = selectedIds[index];
                    final item = items.firstWhere((i) => i.id == id, orElse: () => _ComparisonItem(id, id, LucideIcons.circle));
                    final amount = comparisonData[id] ?? 0;
                    final percent = maxAmount > 0 ? amount / maxAmount : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(item.icon, size: 16, color: item.color ?? AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.name,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formatAmount(amount),
                                style: AppTypography.labelMedium.copyWith(
                                  color: item.color ?? AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: (item.color ?? AppColors.primary).withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(item.color ?? AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Bank Account Analysis
// ============================================

class _BankAccountAnalysis extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;
  final List<IncomeSource> income;
  final List<BankAccount> bankAccounts;

  const _BankAccountAnalysis({
    required this.isDark,
    required this.l10n,
    required this.expenses,
    required this.income,
    required this.bankAccounts,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total inflow and outflow across all bank accounts
    double totalInflow = 0;
    double totalOutflow = 0;

    // Per-bank breakdown
    final bankBreakdown = <String, Map<String, double>>{};

    for (final i in income) {
      if (i.bankAccountId != null) {
        totalInflow += i.amount;
        if (!bankBreakdown.containsKey(i.bankAccountId)) {
          bankBreakdown[i.bankAccountId!] = {'income': 0.0, 'expense': 0.0};
        }
        bankBreakdown[i.bankAccountId]!['income'] = (bankBreakdown[i.bankAccountId]!['income'] ?? 0) + i.amount;
      }
    }

    for (final e in expenses) {
      if (e.bankAccountId != null) {
        totalOutflow += e.amount;
        if (!bankBreakdown.containsKey(e.bankAccountId)) {
          bankBreakdown[e.bankAccountId!] = {'income': 0.0, 'expense': 0.0};
        }
        bankBreakdown[e.bankAccountId]!['expense'] = (bankBreakdown[e.bankAccountId]!['expense'] ?? 0) + e.amount;
      }
    }

    if (totalInflow == 0 && totalOutflow == 0) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.building2, message: l10n?.noBankTransactionsThisMonth ?? 'No bank transactions this month');
    }

    final netFlow = totalInflow - totalOutflow;
    final total = totalInflow + totalOutflow;
    final inflowPercent = total > 0 ? (totalInflow / total * 100).round() : 0;

    // Get bank accounts with transactions
    final activeAccounts = bankAccounts.where((b) => bankBreakdown.containsKey(b.id)).toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Net flow header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                netFlow >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: netFlow >= 0 ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                netFlow >= 0 ? '+${_formatAmount(netFlow)}' : _formatAmount(netFlow),
                style: AppTypography.h3.copyWith(
                  color: netFlow >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            l10n?.netBankFlow ?? 'Net Bank Flow',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 16),
          // Flow bar
          Row(
            children: [
              if (inflowPercent > 0)
                Expanded(
                  flex: inflowPercent,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(6),
                        right: inflowPercent >= 100 ? const Radius.circular(6) : Radius.zero,
                      ),
                    ),
                  ),
                ),
              if (inflowPercent < 100)
                Expanded(
                  flex: 100 - inflowPercent,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.horizontal(
                        left: inflowPercent <= 0 ? const Radius.circular(6) : Radius.zero,
                        right: const Radius.circular(6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Combined In/Out details
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.arrowDownLeft, size: 20, color: AppColors.success),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(totalInflow),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n?.moneyIn ?? 'Money In',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.arrowUpRight, size: 20, color: AppColors.error),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(totalOutflow),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n?.moneyOut ?? 'Money Out',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Per-bank breakdown
          if (activeAccounts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 12),
            Text(
              l10n?.accountBreakdown ?? 'Account Breakdown',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...activeAccounts.map((account) {
              final data = bankBreakdown[account.id]!;
              final accountIncome = data['income'] ?? 0.0;
              final accountExpense = data['expense'] ?? 0.0;
              final accountNet = accountIncome - accountExpense;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: account.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: account.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: account.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoScrollText(
                            text: '${account.bankName} (${account.accountTypeLabel})',
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Net amount
                        Text(
                          accountNet >= 0 ? '+${_formatAmount(accountNet)}' : _formatAmount(accountNet),
                          style: AppTypography.labelMedium.copyWith(
                            color: accountNet >= 0 ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Income
                        Expanded(
                          child: Row(
                            children: [
                              Icon(LucideIcons.arrowDownLeft, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                '+${_formatAmount(accountIncome)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Expense
                        Expanded(
                          child: Row(
                            children: [
                              Icon(LucideIcons.arrowUpRight, size: 12, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                '-${_formatAmount(accountExpense)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ============================================
// Merchant Analysis
// ============================================

class _MerchantAnalysis extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;

  const _MerchantAnalysis({
    required this.isDark,
    required this.l10n,
    required this.expenses,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals by merchant
    final merchantTotals = <String, Map<String, dynamic>>{};

    for (final e in expenses) {
      final merchant = e.merchantName ?? (l10n?.unknown ?? 'Unknown');
      if (!merchantTotals.containsKey(merchant)) {
        merchantTotals[merchant] = {'amount': 0.0, 'count': 0};
      }
      merchantTotals[merchant]!['amount'] = (merchantTotals[merchant]!['amount'] as double) + e.amount;
      merchantTotals[merchant]!['count'] = (merchantTotals[merchant]!['count'] as int) + 1;
    }

    if (merchantTotals.isEmpty) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.store, message: l10n?.noMerchantData ?? 'No merchant data');
    }

    // Sort by amount
    final sortedMerchants = merchantTotals.entries.toList()
      ..sort((a, b) => (b.value['amount'] as double).compareTo(a.value['amount'] as double));

    final topMerchants = sortedMerchants.take(8).toList();
    final maxAmount = topMerchants.first.value['amount'] as double;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: topMerchants.asMap().entries.map((entry) {
          final index = entry.key;
          final merchant = entry.value;
          final amount = merchant.value['amount'] as double;
          final count = merchant.value['count'] as int;
          final percent = maxAmount > 0 ? amount / maxAmount : 0.0;

          // Gradient colors based on rank
          final colors = [
            AppColors.primary,
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
            const Color(0xFFF59E0B),
            const Color(0xFF10B981),
            const Color(0xFF3B82F6),
            const Color(0xFF6366F1),
            const Color(0xFF14B8A6),
          ];
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              merchant.key,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatAmount(amount),
                            style: AppTypography.labelMedium.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: color.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count txn${count > 1 ? 's' : ''}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================
// Section Header
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? trailing;

  const _SectionHeader({required this.title, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

// ============================================
// Month Selector
// ============================================

class _MonthSelector extends StatelessWidget {
  final bool isDark;
  final String monthYear;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  const _MonthSelector({
    required this.isDark,
    required this.monthYear,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
          InkWell(
            onTap: onPrevious,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              monthYear,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: canGoNext ? onNext : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: canGoNext
                    ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                    : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Quick Stats Summary
// ============================================

class _QuickStatsSummary extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<IncomeSource> monthIncome;
  final List<Expense> monthExpenses;
  final bool isFiltered;

  const _QuickStatsSummary({
    required this.isDark,
    required this.l10n,
    required this.monthIncome,
    required this.monthExpenses,
    this.isFiltered = false,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.formatCompact(amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = monthIncome.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netBalance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? ((netBalance / totalIncome) * 100).round() : 0;

    return Column(
      children: [
        if (isFiltered)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.filter, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  l10n?.showingFilteredResults ?? 'Showing filtered results',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                isDark: isDark,
                icon: LucideIcons.trendingUp,
                iconColor: AppColors.success,
                label: l10n?.income ?? 'Income',
                value: _formatAmount(totalIncome),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                isDark: isDark,
                icon: LucideIcons.trendingDown,
                iconColor: AppColors.error,
                label: isFiltered ? (l10n?.filter ?? 'Filtered') : (l10n?.expenses ?? 'Expenses'),
                value: _formatAmount(totalExpenses),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                isDark: isDark,
                icon: LucideIcons.piggyBank,
                iconColor: netBalance >= 0 ? AppColors.primary : AppColors.error,
                label: l10n?.savings ?? 'Savings',
                value: '$savingsRate%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Financial Health Card
// ============================================

class _FinancialHealthCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<IncomeSource> incomeSources;
  final List<Expense> expenses;
  final List<Expense> allExpenses;
  final List<CategoryBudget> budgets;

  const _FinancialHealthCard({
    required this.isDark,
    required this.l10n,
    required this.incomeSources,
    required this.expenses,
    required this.allExpenses,
    required this.budgets,
  });

  /// Get localized health label
  String _getLocalizedHealthLabel(String label, AppLocalizations? l10n) {
    switch (label) {
      case 'Excellent':
        return l10n?.excellent ?? 'Excellent';
      case 'Good':
        return l10n?.good ?? 'Good';
      case 'Fair':
        return l10n?.fair ?? 'Fair';
      case 'Needs Work':
        return l10n?.needsWork ?? 'Needs Work';
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use shared calculator for consistent health score
    final healthResult = HealthScoreCalculator.calculate(
      incomeSources: incomeSources,
      expenses: expenses,
      allExpenses: allExpenses,
      budgets: budgets.isNotEmpty ? budgets : null,
      includeFactors: true,
    );

    final healthScore = healthResult.score;
    final healthLabel = healthResult.label;
    final factors = healthResult.factors
        .map((f) => _HealthFactor(f.label, f.points, f.isPositive, f.detail))
        .toList();

    final healthColor = HealthScoreCalculator.getHealthColor(
      healthScore,
      success: AppColors.success,
      warning: AppColors.warning,
      error: AppColors.error,
    );

    IconData healthIcon;
    if (healthScore >= 80) {
      healthIcon = LucideIcons.trophy;
    } else if (healthScore >= 60) {
      healthIcon = LucideIcons.thumbsUp;
    } else if (healthScore >= 40) {
      healthIcon = LucideIcons.alertCircle;
    } else {
      healthIcon = LucideIcons.alertTriangle;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            healthColor.withValues(alpha: isDark ? 0.15 : 0.1),
            AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: healthColor.withValues(alpha: 0.1),
                  border: Border.all(color: healthColor, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$healthScore',
                      style: AppTypography.h2.copyWith(
                        color: healthColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '/100',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(healthIcon, color: healthColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.financialHealth ?? 'Financial Health',
                          style: AppTypography.labelLarge.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      ),
                      child: Text(
                        _getLocalizedHealthLabel(healthLabel, l10n),
                        style: AppTypography.labelMedium.copyWith(
                          color: healthColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...factors.map((f) => _HealthFactorRow(factor: f, isDark: isDark)),
          ],
        ],
      ),
    );
  }
}

class _HealthFactor {
  final String label;
  final String points;
  final bool isPositive;
  final String detail;

  _HealthFactor(this.label, this.points, this.isPositive, this.detail);
}

class _HealthFactorRow extends StatelessWidget {
  final _HealthFactor factor;
  final bool isDark;

  const _HealthFactorRow({required this.factor, required this.isDark});

  /// Get localized label for health factors
  String _getLocalizedLabel(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context);
    switch (label) {
      case 'Excellent savings rate':
        return l10n?.excellentSavingsRate ?? label;
      case 'Good savings rate':
        return l10n?.goodSavingsRate ?? label;
      case 'Moderate savings':
        return l10n?.moderateSavings ?? label;
      case 'Overspending':
        return l10n?.overspending ?? label;
      case 'Low savings':
        return l10n?.lowSavings ?? label;
      case 'Recurring income':
        return l10n?.recurringIncome ?? label;
      case 'Multiple income entries':
        return l10n?.multipleIncomeEntries ?? label;
      case 'Budget discipline':
        return l10n?.budgetDiscipline ?? label;
      case 'Budget overruns':
        return l10n?.budgetOverruns ?? label;
      case 'Many micro-transactions':
        return l10n?.manyMicroTransactions ?? label;
      case 'Consistent spending':
        return l10n?.consistentSpending ?? label;
      case 'Spending improved':
        return l10n?.spendingImproved ?? label;
      case 'Spending increased':
        return l10n?.spendingIncreased ?? label;
      default:
        return label;
    }
  }

  /// Get localized detail for health factors
  String _getLocalizedDetail(BuildContext context, String detail) {
    final l10n = AppLocalizations.of(context);

    // Handle dynamic details with patterns
    final savingsPattern = RegExp(r'Saving (\d+)% of income');
    final recurringPattern = RegExp(r'(\d+) recurring source\(s\)');
    final entriesPattern = RegExp(r'(\d+) entries');
    final budgetsOnTrackPattern = RegExp(r'All (\d+) budget\(s\) on track');
    final budgetsExceededPattern = RegExp(r'(\d+) budget\(s\) exceeded');
    final microPattern = RegExp(r'(\d+) purchases under ₹200');
    final lessAvgPattern = RegExp(r'(\d+)% less than average');
    final moreAvgPattern = RegExp(r'(\d+)% more than average');

    if (savingsPattern.hasMatch(detail)) {
      final match = savingsPattern.firstMatch(detail);
      final percent = int.parse(match!.group(1)!);
      return l10n?.savingPercentOfIncome(percent) ?? detail;
    } else if (detail == 'Spending more than earning') {
      return l10n?.spendingMoreThanEarning ?? detail;
    } else if (detail == 'Try to save at least 20%') {
      return l10n?.tryToSaveAtLeast20 ?? detail;
    } else if (recurringPattern.hasMatch(detail)) {
      final match = recurringPattern.firstMatch(detail);
      final count = int.parse(match!.group(1)!);
      return l10n?.nRecurringSources(count) ?? detail;
    } else if (entriesPattern.hasMatch(detail)) {
      final match = entriesPattern.firstMatch(detail);
      final count = int.parse(match!.group(1)!);
      return l10n?.nEntries(count) ?? detail;
    } else if (budgetsOnTrackPattern.hasMatch(detail)) {
      final match = budgetsOnTrackPattern.firstMatch(detail);
      final count = int.parse(match!.group(1)!);
      return l10n?.allBudgetsOnTrack(count) ?? detail;
    } else if (budgetsExceededPattern.hasMatch(detail)) {
      final match = budgetsExceededPattern.firstMatch(detail);
      final count = int.parse(match!.group(1)!);
      return l10n?.nBudgetsExceeded(count) ?? detail;
    } else if (microPattern.hasMatch(detail)) {
      final match = microPattern.firstMatch(detail);
      final count = int.parse(match!.group(1)!);
      return l10n?.nPurchasesUnder200(count) ?? detail;
    } else if (detail == 'No unusual spikes') {
      return l10n?.noUnusualSpikes ?? detail;
    } else if (lessAvgPattern.hasMatch(detail)) {
      final match = lessAvgPattern.firstMatch(detail);
      final percent = int.parse(match!.group(1)!);
      return l10n?.percentLessThanAverage(percent) ?? detail;
    } else if (moreAvgPattern.hasMatch(detail)) {
      final match = moreAvgPattern.firstMatch(detail);
      final percent = int.parse(match!.group(1)!);
      return l10n?.percentMoreThanAverage(percent) ?? detail;
    }

    return detail;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            factor.isPositive ? LucideIcons.checkCircle : LucideIcons.alertCircle,
            size: 16,
            color: factor.isPositive ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedLabel(context, factor.label),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  _getLocalizedDetail(context, factor.detail),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (factor.isPositive ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              factor.points,
              style: AppTypography.labelSmall.copyWith(
                color: factor.isPositive ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Monthly Trend Bar Chart
// ============================================

class _MonthlyTrendChart extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> allExpenses;
  final List<IncomeSource> allIncome;
  final DateTime currentMonth;

  const _MonthlyTrendChart({
    required this.isDark,
    required this.l10n,
    required this.allExpenses,
    required this.allIncome,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final months = <DateTime>[];
    final incomeData = <double>[];
    final expenseData = <double>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(currentMonth.year, currentMonth.month - i, 1);
      months.add(month);

      final monthStart = month;
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final monthIncome = allIncome
          .where((i) => i.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
                        i.createdAt.isBefore(monthEnd.add(const Duration(seconds: 1))))
          .fold<double>(0, (sum, i) => sum + i.amount);

      final monthExpense = allExpenses
          .where((e) => e.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
                        e.date.isBefore(monthEnd.add(const Duration(seconds: 1))))
          .fold<double>(0, (sum, e) => sum + e.amount);

      incomeData.add(monthIncome);
      expenseData.add(monthExpense);
    }

    final maxValue = [...incomeData, ...expenseData].reduce((a, b) => a > b ? a : b);

    if (maxValue == 0) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.barChart2, message: l10n?.noDataForTrendAnalysis ?? 'No data for trend analysis');
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final amount = rod.toY;
                      final label = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.formatCompact(amount)}',
                        AppTypography.labelSmall.copyWith(
                          color: rodIndex == 0 ? AppColors.success : AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(months[index]),
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}K',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: incomeData[index],
                        color: AppColors.success,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: expenseData[index],
                        color: AppColors.primary,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(color: AppColors.success, label: l10n?.income ?? 'Income', isDark: isDark),
              const SizedBox(width: 24),
              _ChartLegend(color: AppColors.primary, label: l10n?.expenses ?? 'Expenses', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _ChartLegend({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================
// AI Insights Section
// ============================================

class _AIInsightsSection extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;
  final List<Expense> allExpenses;
  final List<IncomeSource> incomeSources;
  final List<ExpenseCategory> customCategories;
  final List<dynamic> budgets;
  final DateTime selectedMonth;

  const _AIInsightsSection({
    required this.isDark,
    required this.l10n,
    required this.expenses,
    required this.allExpenses,
    required this.incomeSources,
    required this.customCategories,
    required this.budgets,
    required this.selectedMonth,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final insights = <_AIInsight>[];
    final totalIncome = incomeSources.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome * 100).round() : 0;

    if (expenses.isNotEmpty) {
      final avgExpense = totalExpenses / expenses.length;
      final unusualExpenses = expenses.where((e) => e.amount > avgExpense * 3).toList();
      if (unusualExpenses.isNotEmpty) {
        final total = unusualExpenses.fold<double>(0, (sum, e) => sum + e.amount);
        insights.add(_AIInsight(
          icon: LucideIcons.alertTriangle,
          color: AppColors.warning,
          title: l10n?.unusualSpendingDetected ?? 'Unusual Spending Detected',
          description: '${unusualExpenses.length} transaction(s) significantly above your average (${_formatAmount(total)} total).',
          priority: 1,
        ));
      }
    }

    if (allExpenses.length > 10) {
      final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
      final prevMonthEnd = DateTime(selectedMonth.year, selectedMonth.month, 0, 23, 59, 59);

      final prevMonthExpenses = allExpenses.where((e) =>
        e.date.isAfter(prevMonth.subtract(const Duration(seconds: 1))) &&
        e.date.isBefore(prevMonthEnd.add(const Duration(seconds: 1)))
      ).toList();

      if (prevMonthExpenses.isNotEmpty && expenses.isNotEmpty) {
        final currentCatTotals = <String, double>{};
        final prevCatTotals = <String, double>{};

        for (final e in expenses) {
          currentCatTotals[e.categoryId] = (currentCatTotals[e.categoryId] ?? 0) + e.amount;
        }
        for (final e in prevMonthExpenses) {
          prevCatTotals[e.categoryId] = (prevCatTotals[e.categoryId] ?? 0) + e.amount;
        }

        String? biggestIncreaseCategory;
        double biggestIncrease = 0;

        for (final cat in currentCatTotals.keys) {
          final current = currentCatTotals[cat] ?? 0;
          final prev = prevCatTotals[cat] ?? 0;
          if (prev > 0) {
            final increase = ((current - prev) / prev) * 100;
            if (increase > 30 && increase > biggestIncrease) {
              biggestIncrease = increase;
              biggestIncreaseCategory = cat;
            }
          }
        }

        if (biggestIncreaseCategory != null) {
          final category = ExpenseCategories.getByIdWithCustom(biggestIncreaseCategory, customCategories);
          insights.add(_AIInsight(
            icon: LucideIcons.trendingUp,
            color: AppColors.error,
            title: '${category.name} Up ${biggestIncrease.round()}%',
            description: l10n?.spendingIncreasedVsLastMonth ?? 'Spending increased significantly vs last month.',
            priority: 2,
          ));
        }
      }
    }

    if (savingsRate >= 30) {
      insights.add(_AIInsight(
        icon: LucideIcons.trophy,
        color: AppColors.success,
        title: l10n?.excellentSavings ?? 'Excellent Savings!',
        description: l10n?.savingPercentOfIncome(savingsRate) ?? 'You\'re saving $savingsRate% of your income.',
        priority: 5,
      ));
    } else if (savingsRate < 0) {
      insights.add(_AIInsight(
        icon: LucideIcons.alertOctagon,
        color: AppColors.error,
        title: l10n?.spendingExceedsIncome ?? 'Spending Exceeds Income',
        description: l10n?.immediateActionRecommended ?? 'Immediate action recommended.',
        priority: 1,
      ));
    }

    if (expenses.isEmpty && incomeSources.isEmpty) {
      insights.add(_AIInsight(
        icon: LucideIcons.sparkles,
        color: AppColors.primary,
        title: l10n?.startTracking ?? 'Start Tracking',
        description: l10n?.addIncomeExpensesForInsights ?? 'Add income and expenses for insights.',
        priority: 10,
      ));
    }

    insights.sort((a, b) => a.priority.compareTo(b.priority));

    if (insights.isEmpty) {
      insights.add(_AIInsight(
        icon: LucideIcons.sparkles,
        color: AppColors.success,
        title: l10n?.allLookingGood ?? 'All Looking Good!',
        description: l10n?.yourFinancesAreHealthy ?? 'Your finances are healthy.',
        priority: 10,
      ));
    }

    return Column(
      children: insights.take(3).map((insight) => _AIInsightCard(insight: insight, isDark: isDark)).toList(),
    );
  }
}

class _AIInsight {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final int priority;

  _AIInsight({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.priority,
  });
}

class _AIInsightCard extends StatelessWidget {
  final _AIInsight insight;
  final bool isDark;

  const _AIInsightCard({required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppDimensions.screenPaddingHorizontal,
        right: AppDimensions.screenPaddingHorizontal,
        bottom: AppDimensions.spacing12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: insight.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(insight.icon, color: insight.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  insight.description,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Payment Method Analysis
// ============================================

class _PaymentMethodAnalysis extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;
  final List<PaymentMethod> paymentMethods;

  const _PaymentMethodAnalysis({
    required this.isDark,
    required this.l10n,
    required this.expenses,
    required this.paymentMethods,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.creditCard, message: l10n?.noPaymentData ?? 'No payment data');
    }

    final typeTotals = <PaymentMethodType, double>{};
    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    for (final e in expenses) {
      final method = paymentMethods.where((m) => m.id == e.paymentMethodId).firstOrNull;
      final type = method?.type ?? PaymentMethodType.cash;
      typeTotals[type] = (typeTotals[type] ?? 0) + e.amount;
    }

    final sortedTypes = typeTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final cashTotal = typeTotals[PaymentMethodType.cash] ?? 0;
    final digitalTotal = totalAmount - cashTotal;
    final digitalPercent = totalAmount > 0 ? (digitalTotal / totalAmount * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: max(1, digitalPercent),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(4),
                      right: digitalPercent >= 100 ? const Radius.circular(4) : Radius.zero,
                    ),
                  ),
                ),
              ),
              if (digitalPercent < 100)
                Expanded(
                  flex: max(1, 100 - digitalPercent),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.horizontal(
                        left: digitalPercent <= 0 ? const Radius.circular(4) : Radius.zero,
                        right: const Radius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${l10n?.digital ?? 'Digital'}: $digitalPercent%', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
              Text('${l10n?.cash ?? 'Cash'}: ${100 - digitalPercent}%', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ...sortedTypes.take(4).map((entry) {
            final percent = (entry.value / totalAmount * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(entry.key.icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatAmount(entry.value),
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================
// Daily Spending Line Chart
// ============================================

class _DailySpendingChart extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;
  final DateTime selectedMonth;

  const _DailySpendingChart({
    required this.isDark,
    required this.l10n,
    required this.expenses,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.lineChart, message: l10n?.noDailyData ?? 'No daily data');
    }

    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyTotals = List<double>.filled(daysInMonth, 0);

    for (final e in expenses) {
      final dayIndex = e.date.day - 1;
      if (dayIndex >= 0 && dayIndex < daysInMonth) {
        dailyTotals[dayIndex] += e.amount;
      }
    }

    final maxDaily = dailyTotals.reduce((a, b) => a > b ? a : b);
    if (maxDaily == 0) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.lineChart, message: l10n?.noDailyData ?? 'No daily data');
    }

    final nonZeroDays = dailyTotals.where((d) => d > 0).length;
    final avgDaily = nonZeroDays > 0 ? dailyTotals.reduce((a, b) => a + b) / nonZeroDays : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n?.avg ?? 'Avg'}: ${CurrencyFormatter.format(avgDaily)}',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                '${l10n?.peak ?? 'Peak'}: ${CurrencyFormatter.format(maxDaily)}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxDaily / 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt() + 1;
                        // Show dates at regular intervals: 1, 5, 10, 15, 20, 25, and last day
                        if (day == 1 || day == 5 || day == 10 || day == 15 ||
                            day == 20 || day == 25 || day == daysInMonth) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$day',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (daysInMonth - 1).toDouble(),
                minY: 0,
                maxY: maxDaily * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, avgDaily.toDouble()),
                      FlSpot((daysInMonth - 1).toDouble(), avgDaily.toDouble()),
                    ],
                    isCurved: false,
                    color: AppColors.warning.withValues(alpha: 0.5),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [4, 4],
                  ),
                  LineChartBarData(
                    spots: List.generate(daysInMonth, (i) => FlSpot(i.toDouble(), dailyTotals[i])),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: AppColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Empty Card
// ============================================

class _EmptyCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;

  const _EmptyCard({
    required this.isDark,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding * 1.5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Interactive Spending Patterns Card
// ============================================

class _InteractiveSpendingPatternsCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final List<Expense> expenses;
  final DateTime selectedMonth;
  final int? selectedDayIndex;
  final Function(int) onDaySelected;

  const _InteractiveSpendingPatternsCard({
    required this.isDark,
    required this.l10n,
    required this.expenses,
    required this.selectedMonth,
    required this.selectedDayIndex,
    required this.onDaySelected,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _EmptyCard(isDark: isDark, icon: LucideIcons.barChart2, message: l10n?.noSpendingData ?? 'No spending data');
    }

    // Get the number of days in the selected month
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final today = DateTime.now();

    // Calculate daily totals
    final dayTotals = List<double>.filled(daysInMonth, 0);
    for (final e in expenses) {
      if (e.date.year == selectedMonth.year && e.date.month == selectedMonth.month) {
        final dayIndex = e.date.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          dayTotals[dayIndex] += e.amount;
        }
      }
    }

    final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);
    final totalSpending = dayTotals.reduce((a, b) => a + b);
    final avgDaily = daysInMonth > 0 ? totalSpending / daysInMonth : 0.0;

    // Find highest spending day
    final highestDayIndex = dayTotals.indexOf(maxDay);
    final highestDayName = DateFormat('d MMM').format(DateTime(selectedMonth.year, selectedMonth.month, highestDayIndex + 1));

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.trendingUp, size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          'Peak: $highestDayName',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatAmount(maxDay),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg: ${_formatAmount(avgDaily)}/day',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedDayIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('d MMM').format(DateTime(selectedMonth.year, selectedMonth.month, selectedDayIndex! + 1)),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatAmount(dayTotals[selectedDayIndex!]),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.tapOnBarsToSeeDailySpending ?? 'Tap on bars to see daily spending',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // Scrollable bar chart
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(daysInMonth, (index) {
                  final dayDate = DateTime(selectedMonth.year, selectedMonth.month, index + 1);
                  final isToday = dayDate.year == today.year &&
                                  dayDate.month == today.month &&
                                  dayDate.day == today.day;
                  final isFuture = dayDate.isAfter(today);
                  final isSelected = selectedDayIndex == index;
                  final percent = maxDay > 0 ? dayTotals[index] / maxDay : 0.0;
                  final isHighest = index == highestDayIndex && dayTotals[index] > 0;
                  final hasSpending = dayTotals[index] > 0;

                  return GestureDetector(
                    onTap: isFuture ? null : () => onDaySelected(index),
                    child: Container(
                      width: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: max(4, 60 * percent),
                            width: 20,
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3)
                                  : isSelected
                                      ? AppColors.primary
                                      : isHighest
                                          ? AppColors.error
                                          : hasSpending
                                              ? AppColors.primary.withValues(alpha: 0.4)
                                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Day number
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            decoration: isToday
                                ? BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              '${index + 1}',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9,
                                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.normal,
                                color: isToday
                                    ? Colors.white
                                    : isSelected
                                        ? AppColors.primary
                                        : isFuture
                                            ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withValues(alpha: 0.5)
                                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Category Pie Chart with Selection
// ============================================

class _CategoryPieChartWithSelection extends StatefulWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final bool showExpenses;
  final List<Expense> expenses;
  final List<IncomeSource> income;
  final List<ExpenseCategory> customExpenseCategories;
  final List<IncomeCategoryModel> customIncomeCategories;
  final int touchedIndex;
  final Function(int) onTouch;
  final Set<String> selectedCategories;
  final Function(String) onCategoryToggle;
  final VoidCallback onClearSelection;

  const _CategoryPieChartWithSelection({
    required this.isDark,
    required this.l10n,
    required this.showExpenses,
    required this.expenses,
    required this.income,
    required this.customExpenseCategories,
    required this.customIncomeCategories,
    required this.touchedIndex,
    required this.onTouch,
    required this.selectedCategories,
    required this.onCategoryToggle,
    required this.onClearSelection,
  });

  @override
  State<_CategoryPieChartWithSelection> createState() => _CategoryPieChartWithSelectionState();
}

class _CategoryPieChartWithSelectionState extends State<_CategoryPieChartWithSelection> {
  bool _otherExpanded = false;
  static const int _topCategoriesCount = 5;

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Build category data based on showExpenses toggle
    Map<String, double> categoryTotals = {};
    double total = 0;

    if (widget.showExpenses) {
      for (final expense in widget.expenses) {
        categoryTotals[expense.categoryId] = (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
        total += expense.amount;
      }
    } else {
      for (final inc in widget.income) {
        categoryTotals[inc.categoryId] = (categoryTotals[inc.categoryId] ?? 0) + inc.amount;
        total += inc.amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return _EmptyCard(
        isDark: widget.isDark,
        icon: LucideIcons.pieChart,
        message: widget.showExpenses ? (widget.l10n?.noExpensesThisMonth ?? 'No expenses this month') : (widget.l10n?.noIncomeThisMonth ?? 'No income this month'),
      );
    }

    // Sort all categories by amount
    final allSortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Split into top categories and "other"
    final topCategories = allSortedCategories.take(_topCategoriesCount).toList();
    final otherCategories = allSortedCategories.skip(_topCategoriesCount).toList();
    final otherTotal = otherCategories.fold<double>(0, (sum, e) => sum + e.value);

    // Filter data based on selected categories
    Map<String, double> filteredTotals = categoryTotals;
    double filteredTotal = total;

    if (widget.selectedCategories.isNotEmpty) {
      filteredTotals = Map.fromEntries(
        categoryTotals.entries.where((e) => widget.selectedCategories.contains(e.key))
      );
      filteredTotal = filteredTotals.values.fold(0.0, (sum, v) => sum + v);
    }

    final sortedCategories = filteredTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Build pie chart sections
    List<MapEntry<String, double>> displayCategories;
    double displayOtherTotal = 0;

    if (widget.selectedCategories.isEmpty) {
      // Show top 5 + Other
      displayCategories = topCategories;
      displayOtherTotal = otherTotal;
    } else {
      // Show only selected categories
      displayCategories = sortedCategories;
    }

    if (displayCategories.isEmpty && displayOtherTotal == 0) {
      return _EmptyCard(
        isDark: widget.isDark,
        icon: LucideIcons.pieChart,
        message: widget.l10n?.noDataForSelectedCategories ?? 'No data for selected categories',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Category selection chips - Top categories
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.l10n?.selectCategoriesToDisplay ?? 'Select categories to display:',
                    style: AppTypography.labelSmall.copyWith(
                      color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (widget.selectedCategories.isNotEmpty)
                    GestureDetector(
                      onTap: widget.onClearSelection,
                      child: Text(
                        widget.l10n?.showAll ?? 'Show All',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Top categories row
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: topCategories.length + (otherCategories.isNotEmpty ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    // "More..." expandable chip at the end (for categories beyond top 5)
                    if (index == topCategories.length && otherCategories.isNotEmpty) {
                      final anyOtherSelected = otherCategories.any(
                        (e) => widget.selectedCategories.contains(e.key)
                      );
                      final isSelected = widget.selectedCategories.isEmpty || anyOtherSelected;
                      final selectedInOther = otherCategories.where(
                        (e) => widget.selectedCategories.contains(e.key)
                      ).length;

                      return GestureDetector(
                        onTap: () => setState(() => _otherExpanded = !_otherExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _otherExpanded ? AppColors.primary.withValues(alpha: 0.15) : (isSelected ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _otherExpanded ? AppColors.primary : (isSelected ? Colors.grey : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                              width: _otherExpanded || isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _otherExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 14,
                                color: _otherExpanded ? AppColors.primary : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.l10n?.moreCategories(otherCategories.length) ?? 'More (${otherCategories.length})',
                                style: AppTypography.labelSmall.copyWith(
                                  color: _otherExpanded
                                      ? AppColors.primary
                                      : (isSelected
                                          ? (widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                          : (widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
                                  fontWeight: isSelected || _otherExpanded ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              if (selectedInOther > 0 && widget.selectedCategories.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$selectedInOther',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    final categoryId = topCategories[index].key;
                    final isSelected = widget.selectedCategories.isEmpty || widget.selectedCategories.contains(categoryId);

                    // Get category details
                    String categoryName = categoryId;
                    Color categoryColor = Colors.grey;

                    if (widget.showExpenses) {
                      final category = ExpenseCategories.getByIdWithCustom(categoryId, widget.customExpenseCategories);
                      categoryName = category.name;
                      categoryColor = category.color;
                    } else {
                      final category = IncomeCategories.getByIdWithCustom(categoryId, widget.customIncomeCategories);
                      categoryName = category.name;
                      categoryColor = category.color;
                    }

                    return GestureDetector(
                      onTap: () => widget.onCategoryToggle(categoryId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? categoryColor.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? categoryColor : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected ? categoryColor : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              categoryName,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? categoryColor
                                    : (widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Expanded "Other" categories
              if (_otherExpanded && otherCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.darkSurface : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More categories (${otherCategories.length}):',
                        style: AppTypography.labelSmall.copyWith(
                          color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: otherCategories.map((entry) {
                          final categoryId = entry.key;
                          final isSelected = widget.selectedCategories.isEmpty || widget.selectedCategories.contains(categoryId);

                          String categoryName = categoryId;
                          Color categoryColor = Colors.grey;

                          if (widget.showExpenses) {
                            final category = ExpenseCategories.getByIdWithCustom(categoryId, widget.customExpenseCategories);
                            categoryName = category.name;
                            categoryColor = category.color;
                          } else {
                            final category = IncomeCategories.getByIdWithCustom(categoryId, widget.customIncomeCategories);
                            categoryName = category.name;
                            categoryColor = category.color;
                          }

                          return GestureDetector(
                            onTap: () => widget.onCategoryToggle(categoryId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? categoryColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? categoryColor : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected ? categoryColor : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    categoryName,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 11,
                                      color: isSelected
                                          ? categoryColor
                                          : (widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatAmount(entry.value),
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                      color: widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      widget.onTouch(-1);
                      return;
                    }
                    widget.onTouch(pieTouchResponse.touchedSection!.touchedSectionIndex);
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  ...displayCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final catEntry = entry.value;

                    Color categoryColor = Colors.grey;
                    if (widget.showExpenses) {
                      final category = ExpenseCategories.getByIdWithCustom(catEntry.key, widget.customExpenseCategories);
                      categoryColor = category.color;
                    } else {
                      final category = IncomeCategories.getByIdWithCustom(catEntry.key, widget.customIncomeCategories);
                      categoryColor = category.color;
                    }

                    final isTouched = index == widget.touchedIndex;
                    final displayTotal = widget.selectedCategories.isEmpty ? total : filteredTotal;
                    final percent = displayTotal > 0 ? (catEntry.value / displayTotal * 100).round() : 0;

                    return PieChartSectionData(
                      color: categoryColor,
                      value: catEntry.value,
                      title: isTouched ? '$percent%' : '',
                      radius: isTouched ? 55 : 45,
                      titleStyle: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  // "Other" section in pie chart
                  if (displayOtherTotal > 0 && widget.selectedCategories.isEmpty)
                    PieChartSectionData(
                      color: Colors.grey,
                      value: displayOtherTotal,
                      title: widget.touchedIndex == displayCategories.length
                          ? '${(displayOtherTotal / total * 100).round()}%'
                          : '',
                      radius: widget.touchedIndex == displayCategories.length ? 55 : 45,
                      titleStyle: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            ),
          ),
          const SizedBox(height: 16),
          // Legend with amounts
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ...displayCategories.map((entry) {
                String categoryName = entry.key;
                Color categoryColor = Colors.grey;

                if (widget.showExpenses) {
                  final category = ExpenseCategories.getByIdWithCustom(entry.key, widget.customExpenseCategories);
                  categoryName = category.name;
                  categoryColor = category.color;
                } else {
                  final category = IncomeCategories.getByIdWithCustom(entry.key, widget.customIncomeCategories);
                  categoryName = category.name;
                  categoryColor = category.color;
                }

                final displayTotal = widget.selectedCategories.isEmpty ? total : filteredTotal;
                final percent = displayTotal > 0 ? (entry.value / displayTotal * 100).round() : 0;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$categoryName ($percent%)',
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatAmount(entry.value),
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                );
              }),
              // "More categories" in legend
              if (displayOtherTotal > 0 && widget.selectedCategories.isEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'More (${(displayOtherTotal / total * 100).round()}%)',
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatAmount(displayOtherTotal),
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Total display
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (widget.showExpenses ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.l10n?.total ?? 'Total'}: ',
                  style: AppTypography.labelMedium.copyWith(
                    color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  _formatAmount(widget.selectedCategories.isEmpty ? total : filteredTotal),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.showExpenses ? AppColors.error : AppColors.success,
                  ),
                ),
                if (widget.selectedCategories.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.selectedCategories.length} ${widget.l10n?.selected ?? 'selected'})',
                    style: AppTypography.labelSmall.copyWith(
                      color: widget.isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
