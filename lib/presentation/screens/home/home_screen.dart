import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/budget.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/income.dart';
import '../../../data/models/goal.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../navigation/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../providers/currency_provider.dart';
import '../../../providers/auth_provider.dart';
import '../income/add_income_sheet.dart';
import '../expenses/add_expense_sheet.dart';
import '../expenses/receipt_scanner_sheet.dart';
import '../settings/recurring_transactions_screen.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/health_score_calculator.dart';
import '../../../services/supabase_service.dart';
import '../../providers/profile_provider.dart';
import '../../../services/rating_service.dart';
import '../../widgets/common/rate_us_dialog.dart';
import '../../widgets/common/banner_ad_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context);
    if (hour < 12) return l10n?.goodMorning ?? 'Good Morning';
    if (hour < 17) return l10n?.goodAfternoon ?? 'Good Afternoon';
    return l10n?.goodEvening ?? 'Good Evening';
  }

  String _formatUserName(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return '';
    }

    // Split the name by spaces
    final parts = displayName.trim().split(' ');

    if (parts.length == 1) {
      // Single name - just truncate if needed
      final name = parts[0];
      if (name.length > 10) {
        return name.substring(0, 10);
      }
      return name;
    }

    // Multiple parts - take first name + first initial of subsequent names
    final firstName = parts[0];
    final lastInitial = parts.length > 1 ? ' ${parts[1][0]}.' : '';

    final result = '$firstName$lastInitial';

    // If still too long, truncate first name
    if (result.length > 12) {
      final maxFirstLen = 12 - lastInitial.length;
      return '${firstName.substring(0, maxFirstLen.clamp(1, firstName.length))}$lastInitial';
    }

    return result;
  }

  String _getGreetingWithName(BuildContext context, WidgetRef ref) {
    final greeting = _getGreeting(context);

    // First try to get from profile provider (most up-to-date)
    final profile = ref.watch(profileProvider);
    String? displayName = profile.displayName;

    // Fallback to supabase service if profile not loaded
    if (displayName == null || displayName.isEmpty) {
      displayName = SupabaseService.instance.userDisplayName;
    }

    // Only show name if user is authenticated
    if (!SupabaseService.instance.isAuthenticated) {
      return greeting;
    }

    final userName = _formatUserName(displayName);

    if (userName.isEmpty) {
      return greeting;
    }

    return '$greeting, $userName!';
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return DateFormat('MMMM yyyy').format(now);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incomeSources = ref.watch(incomeSourcesProvider);
    final expenses = ref.watch(expensesProvider);
    final budgets = ref.watch(budgetsProvider);
    final customIncomeCategories = ref.watch(customIncomeCategoriesProvider);
    final activeGoals = ref.watch(activeGoalsProvider);
    final dueRecurring = ref.watch(dueRecurringTransactionsProvider);
    // Watch currency to rebuild when it changes
    ref.watch(currencyProvider);
    // Watch auth state to rebuild when user signs in/out
    ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Rating prompt checker (invisible, runs once on mount)
            const SliverToBoxAdapter(child: _RatingChecker()),

            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreetingWithName(context, ref),
                            style: AppTypography.h3.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: _getGreetingWithName(context, ref).length > 20 ? 18 : 20,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentMonthYear(),
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _IconButton(
                          icon: LucideIcons.refreshCw,
                          onTap: () => context.push(AppRoutes.cloudSync),
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                        _IconButton(
                          icon: LucideIcons.bell,
                          onTap: () => context.push(AppRoutes.notifications),
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                        _IconButton(
                          icon: LucideIcons.settings,
                          onTap: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Financial Overview Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: _FinancialOverviewCard(
                  isDark: isDark,
                  incomeSources: incomeSources,
                  expenses: expenses,
                  budgets: budgets,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
            ),

            // Due Recurring Transactions Banner
            if (dueRecurring.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.screenPaddingHorizontal,
                    right: AppDimensions.screenPaddingHorizontal,
                    top: AppDimensions.spacing16,
                  ),
                  child: _DueRecurringBanner(
                    isDark: isDark,
                    dueTransactions: dueRecurring,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingTransactionsScreen()),
                    ),
                  ),
                ),
              ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.quickActions ?? 'Quick Actions',
                          style: AppTypography.labelLarge.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionButton(
                                icon: LucideIcons.plus,
                                label: l10n?.addIncome ?? 'Add Income',
                                color: AppColors.success,
                                onTap: () => AddIncomeSheet.show(context),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacing12),
                            Expanded(
                              child: _QuickActionButton(
                                icon: LucideIcons.minus,
                                label: l10n?.addExpense ?? 'Add Expense',
                                color: AppColors.error,
                                onTap: () => AddExpenseSheet.show(context),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacing12),
                            Expanded(
                              child: _QuickActionButton(
                                icon: LucideIcons.camera,
                                label: l10n?.scan ?? 'Scan',
                                color: AppColors.primary,
                                onTap: () async {
                                  final receipt = await ReceiptScannerSheet.show(context);
                                  if (receipt != null && context.mounted) {
                                    AddExpenseSheet.show(context, scannedReceipt: receipt);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 100.ms),
            ),

            // Income Streams Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _SectionHeader(
                    title: l10n?.incomeStreams ?? 'Income Streams',
                    onSeeAll: () => context.go(AppRoutes.income),
                  );
                },
              ),
              ),
            ),

            // Income List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: _IncomeStreamsList(
                  isDark: isDark,
                  incomeSources: incomeSources,
                  customCategories: customIncomeCategories,
                ),
              ),
            ),

            // Weekly Insight
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: _InsightCard(
                  isDark: isDark,
                  expenses: expenses,
                ),
              ),
            ),

            // Savings Goals Section (only show if there are active goals)
            if (activeGoals.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _SectionHeader(
                    title: l10n?.savingsGoals ?? 'Savings Goals',
                    onSeeAll: () => context.push(AppRoutes.goals),
                  );
                },
              ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: _GoalsSummary(
                    isDark: isDark,
                    goals: activeGoals,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing16),
              ),
            ],

            // Recent Expenses Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _SectionHeader(
                    title: l10n?.recentExpenses ?? 'Recent Expenses',
                    onSeeAll: () => context.go(AppRoutes.expenses),
                  );
                },
              ),
              ),
            ),

            // Expenses List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: _RecentTransactionsList(
                  isDark: isDark,
                  expenses: expenses,
                  incomeSources: incomeSources,
                ),
              ),
            ),

            // Bottom Padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacing32),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _FinancialOverviewCard extends ConsumerWidget {
  final bool isDark;
  final List<IncomeSource> incomeSources;
  final List<Expense> expenses;
  final List<CategoryBudget> budgets;

  const _FinancialOverviewCard({
    required this.isDark,
    required this.incomeSources,
    required this.expenses,
    required this.budgets,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate totals for current month
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Filter income sources for current month
    final currentMonthIncome = incomeSources.where((i) {
      return i.date.isAfter(currentMonthStart.subtract(const Duration(seconds: 1))) &&
             i.date.isBefore(currentMonthEnd.add(const Duration(seconds: 1)));
    }).toList();

    // Calculate total income - sum all amounts regardless of currency
    // Currency is just for UI display, original currency codes are preserved in database
    final totalIncome = currentMonthIncome.fold<double>(0, (sum, income) => sum + income.amount);

    // Filter expenses for current month
    final currentMonthExpenses = expenses.where((e) {
      final isCurrentMonth = e.date.isAfter(currentMonthStart) ||
             (e.date.year == currentMonthStart.year &&
              e.date.month == currentMonthStart.month);
      return isCurrentMonth;
    }).toList();

    // Calculate total expenses - sum all amounts regardless of currency
    final totalExpenses = currentMonthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    final netBalance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0
        ? ((netBalance / totalIncome) * 100).round()
        : 0;

    // Filter budgets for current month
    final currentMonthBudgets = budgets.where((b) {
      return b.month == now.month && b.year == now.year;
    }).toList();

    final healthResult = HealthScoreCalculator.calculate(
      incomeSources: currentMonthIncome,
      expenses: currentMonthExpenses,
      allExpenses: expenses,
      budgets: currentMonthBudgets.isNotEmpty ? currentMonthBudgets : null,
      includeFactors: false, // Home screen doesn't show factors
    );

    final healthScore = healthResult.score;
    final healthLabel = healthResult.label;
    final healthColor = HealthScoreCalculator.getHealthColor(
      healthScore,
      success: AppColors.success,
      warning: AppColors.warning,
      error: AppColors.error,
    );

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Column(
        children: [
          // Quick Summary Heading
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.quickSummary ?? 'Quick Summary',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _OverviewItem(
                      label: l10n?.totalIncome ?? 'Total Income',
                      amount: _formatAmount(totalIncome),
                      onTap: () => context.go('/income'),
                    );
                  },
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _OverviewItem(
                      label: l10n?.totalExpenses ?? 'Total Expenses',
                      amount: _formatAmount(totalExpenses),
                      onTap: () => context.go('/expenses'),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Row(
                children: [
                  Expanded(
                    child: _OverviewItem(
                      label: l10n?.netBalance ?? 'Net Balance',
                      amount: _formatAmount(netBalance),
                      subtitle: savingsRate >= 0
                          ? '${l10n?.savings ?? 'Saving'} $savingsRate%'
                          : '${l10n?.overspent ?? 'Overspent'} ${(-savingsRate).abs()}%',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _HealthScoreItem(
                      score: healthScore,
                      label: healthLabel,
                      color: healthColor,
                      onTap: () => context.go('/insights'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String amount;
  final String? subtitle;
  final VoidCallback? onTap;

  const _OverviewItem({
    required this.label,
    required this.amount,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppTypography.amountSmall.copyWith(
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthScoreItem extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _HealthScoreItem({
    required this.score,
    required this.label,
    required this.color,
    this.onTap,
  });

  /// Get localized health label
  String _getLocalizedHealthLabel(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context);
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.healthScore ?? 'Health Score',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: AppTypography.amountSmall.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                '/100',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getLocalizedHealthLabel(context, label),
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacing12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                widget.label,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.h4.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.seeAll ?? 'See All',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
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

class _IncomeStreamsList extends StatelessWidget {
  final bool isDark;
  final List<IncomeSource> incomeSources;
  final List<IncomeCategoryModel> customCategories;

  const _IncomeStreamsList({
    required this.isDark,
    required this.incomeSources,
    required this.customCategories,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (incomeSources.isEmpty) {
      return Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.wallet,
                  size: 48,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                const SizedBox(height: AppDimensions.spacing12),
                Text(
                  l10n?.noIncomeSourcesYet ?? 'No income sources yet',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  l10n?.tapAddIncomeToStart ?? 'Tap "Add Income" to get started',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Sort by date (newest first) and show max 3 income sources
    final sortedSources = [...incomeSources]
      ..sort((a, b) => b.date.compareTo(a.date));
    final displaySources = sortedSources.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: displaySources.asMap().entries.map((entry) {
          final index = entry.key;
          final income = entry.value;
          final isLast = index == displaySources.length - 1;
          final category = IncomeCategories.getByIdWithCustom(income.categoryId, customCategories);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            income.sourceName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                '${DateFormat('MMM d').format(income.date)}${income.isRecurring ? ' • ${l10n?.recurring ?? 'Recurring'}' : ''}',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatAmount(income.amount),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: AppDimensions.spacing16,
                  endIndent: AppDimensions.spacing16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InsightCard extends ConsumerWidget {
  final bool isDark;
  final List<Expense> expenses;

  const _InsightCard({
    required this.isDark,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customCategories = ref.watch(customExpenseCategoriesProvider);
    final l10n = AppLocalizations.of(context);

    // Generate insight based on expenses
    String insightText = l10n?.startTrackingInsight ?? 'Start tracking your expenses to get personalized insights about your spending patterns.';

    if (expenses.isNotEmpty) {
      // Find top spending category this week
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final weeklyExpenses = expenses.where((e) => e.date.isAfter(weekAgo)).toList();

      if (weeklyExpenses.isNotEmpty) {
        final categoryTotals = <String, double>{};
        for (final expense in weeklyExpenses) {
          categoryTotals[expense.categoryId] =
              (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
        }

        if (categoryTotals.isNotEmpty) {
          final topCategory = categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b);
          final category = ExpenseCategories.getByIdWithCustom(topCategory.key, customCategories);
          insightText = l10n?.topSpendingCategory(category.name, CurrencyFormatter.format(topCategory.value)) ??
              'Your top spending category this week is ${category.name}. '
              'You\'ve spent ${CurrencyFormatter.format(topCategory.value)} on it.';
        }
      } else {
        insightText = l10n?.noExpensesThisWeek ?? 'No expenses recorded this week. Keep tracking to get insights!';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.weeklyInsight ?? 'Weekly Insight',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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

class _RecentTransactionsList extends ConsumerWidget {
  final bool isDark;
  final List<Expense> expenses;
  final List<IncomeSource> incomeSources;

  const _RecentTransactionsList({
    required this.isDark,
    required this.expenses,
    required this.incomeSources,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  String _formatTime(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('h:mm a').format(date);

    if (transactionDate == today) {
      return '${l10n?.today ?? 'Today'}, $timeStr';
    } else if (transactionDate == yesterday) {
      return '${l10n?.yesterday ?? 'Yesterday'}, $timeStr';
    } else {
      return '${DateFormat('dd/MM').format(date)}, $timeStr';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customCategories = ref.watch(customExpenseCategoriesProvider);

    if (expenses.isEmpty && incomeSources.isEmpty) {
      return Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.receipt,
                  size: 48,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                const SizedBox(height: AppDimensions.spacing12),
                Text(
                  l10n?.noTransactions ?? 'No transactions yet',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  l10n?.startTrackingInsight ?? 'Start tracking your income and expenses',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Sort expenses by date and take most recent 4
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentExpenses = sortedExpenses.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: recentExpenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          final isLast = index == recentExpenses.length - 1;

          final category = ExpenseCategories.getByIdWithCustom(expense.categoryId, customCategories);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Row(
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
                            expense.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            _formatTime(expense.date, context),
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-${_formatAmount(expense.amount)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: AppDimensions.spacing16,
                  endIndent: AppDimensions.spacing16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _GoalsSummary extends StatelessWidget {
  final bool isDark;
  final List<SavingsGoal> goals;

  const _GoalsSummary({
    required this.isDark,
    required this.goals,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Show up to 2 goals
    final displayGoals = goals.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: displayGoals.asMap().entries.map((entry) {
          final index = entry.key;
          final goal = entry.value;
          final isLast = index == displayGoals.length - 1;
          final progress = goal.progressPercent / 100;
          final progressColor = goal.isOverdue
              ? AppColors.error
              : progress >= 0.8
                  ? AppColors.success
                  : progress >= 0.5
                      ? AppColors.warning
                      : AppColors.primary;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: goal.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Icon(
                        goal.icon,
                        color: goal.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${goal.progressPercent.toStringAsFixed(0)}%',
                                style: AppTypography.labelMedium.copyWith(
                                  color: progressColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatAmount(goal.currentAmount)} of ${_formatAmount(goal.targetAmount)}',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: AppDimensions.spacing16,
                  endIndent: AppDimensions.spacing16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DueRecurringBanner extends StatelessWidget {
  final bool isDark;
  final List<RecurringTransaction> dueTransactions;
  final VoidCallback onTap;

  const _DueRecurringBanner({
    required this.isDark,
    required this.dueTransactions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = dueTransactions.length;
    final totalAmount = dueTransactions.fold<double>(0, (sum, t) => sum + t.amount);

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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.bell, color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Recurring Transaction${count > 1 ? 's' : ''} Due',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total: ${CurrencyFormatter.format(totalAmount)} - Tap to review',
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Invisible widget that checks rating conditions once on mount.
/// Placed as the first sliver in HomeScreen's CustomScrollView.
class _RatingChecker extends StatefulWidget {
  const _RatingChecker();

  @override
  State<_RatingChecker> createState() => _RatingCheckerState();
}

class _RatingCheckerState extends State<_RatingChecker> {
  @override
  void initState() {
    super.initState();
    _scheduleRatingCheck();
  }

  Future<void> _scheduleRatingCheck() async {
    await RatingService.instance.recordFirstOpen();
    final should = await RatingService.instance.shouldShowRating();
    if (should && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) RateUsDialog.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
