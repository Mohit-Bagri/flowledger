import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/budget.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/app_router.dart';
import '../../providers/storage_providers.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/common/date_range_selector.dart';
import 'add_expense_sheet.dart';
import 'receipt_scanner_sheet.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/common/banner_ad_widget.dart';
import '../../../services/ad_service.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  ExpenseCategory? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use date-filtered expenses
    final allExpenses = ref.watch(filteredExpensesByDateProvider);
    final dateRange = ref.watch(dateRangeProvider);

    // Get default currency for display
    final defaultCurrency = ref.watch(currencyProvider);

    // Apply category filter for breakdown only, and sort by date (newest first)
    final filteredList = _selectedFilter == null
        ? [...allExpenses]
        : allExpenses.where((e) => e.categoryId == _selectedFilter!.id).toList();
    final filteredExpenses = filteredList..sort((a, b) => b.date.compareTo(a.date));

    // Calculate total expenses - sum all amounts regardless of currency
    // Currency is just for UI display, original currency codes are preserved in database
    final totalExpenses = allExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final displayCurrencySymbol = defaultCurrency.symbol;

    // Get unique categories from filtered expenses for breakdown
    final categoryBreakdown = _getCategoryBreakdown(filteredExpenses);

    // Calculate filtered total for breakdown - sum all amounts regardless of currency
    final filteredTotal = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.expenses ?? 'Expenses',
                          style: AppTypography.h2.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        DateRangeSelector(isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // Total Expenses Card
                    _TotalExpensesCard(
                      isDark: isDark,
                      totalExpenses: totalExpenses,
                      currencySymbol: displayCurrencySymbol,
                      periodLabel: dateRange.periodLabel,
                      dateRange: dateRange.shortDateRangeLabel,
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  children: [
                    _FilterChip(
                      label: l10n?.all ?? 'All',
                      isSelected: _selectedFilter == null,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedFilter = null),
                    ),
                    // Show ALL system categories
                    ...ExpenseCategories.all.where((c) => c.id != 'other').map((category) => _FilterChip(
                          label: category.name.split(' ').first,
                          isSelected: _selectedFilter?.id == category.id,
                          isDark: isDark,
                          color: category.color,
                          onTap: () => setState(() => _selectedFilter = category),
                        )),
                    // Add ALL custom categories
                    ...ref.watch(customExpenseCategoriesProvider).map((category) => _FilterChip(
                          label: category.name,
                          isSelected: _selectedFilter?.id == category.id,
                          isDark: isDark,
                          color: category.color,
                          onTap: () => setState(() => _selectedFilter = category),
                        )),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacing24),
            ),

            // Category Breakdown Section
            if (categoryBreakdown.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: Text(
                    l10n?.expensesByCategory ?? 'Category Breakdown',
                    style: AppTypography.h4.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing12),
              ),

              // Category Breakdown Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: _CategoryBreakdownCard(
                    isDark: isDark,
                    categoryBreakdown: categoryBreakdown,
                    totalExpenses: filteredTotal,
                                      ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing24),
              ),
            ],

            // Budget Status Section (only show for current month)
            if (dateRange.preset == DateRangePreset.thisMonth) ...[
              SliverToBoxAdapter(
                child: _BudgetStatusSection(
                  isDark: isDark,
                                  ),
              ),
            ],

            // Empty state when filtered category has no data
            if (_selectedFilter != null && filteredExpenses.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: Text(
                    '${l10n?.expensesByCategory ?? 'Category Breakdown'} (0)',
                    style: AppTypography.h4.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing12),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing24),
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
                          LucideIcons.folderSearch,
                          size: 48,
                          color: _selectedFilter!.color.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        Text(
                          l10n?.noCategoriesForFilter ?? 'No items for this category',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacing8),
                        Text(
                          l10n?.tapAddExpenseToStart ?? 'Tap the + button to add your first expense',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing24),
              ),
            ],

            // Recent Transactions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.recentExpenses ?? 'Recent Transactions',
                      style: AppTypography.h4.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (allExpenses.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showAllExpenseHistory(context, allExpenses, l10n),
                        child: Text(
                          l10n?.seeAll ?? 'See All',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacing12),
            ),

            // Expense List - Always shows ALL expenses (not filtered)
            SliverToBoxAdapter(
              child: allExpenses.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : _RecentExpensesList(
                      isDark: isDark,
                      expenses: (List<Expense>.from(allExpenses)
                            ..sort((a, b) => b.date.compareTo(a.date)))
                          .take(5)
                          .toList(),
                                            onEdit: _editExpense,
                      onDelete: _deleteExpense,
                      onViewDetails: (expense) => _showExpenseDetails(context, expense),
                    ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: () async {
              final receipt = await ReceiptScannerSheet.show(context);
              if (receipt != null && context.mounted) {
                // Open add expense sheet with scanned receipt data
                AddExpenseSheet.show(context, scannedReceipt: receipt);
              }
            },
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Icon(
              LucideIcons.camera,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => AddExpenseSheet.show(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(LucideIcons.plus, color: Colors.white),
            label: Text(
              l10n?.addExpense ?? 'Add Expense',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getCategoryBreakdown(List<Expense> expenses) {
    final breakdown = <String, double>{};
    for (final expense in expenses) {
      breakdown[expense.categoryId] = (breakdown[expense.categoryId] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  Future<void> _editExpense(Expense expense) async {
    final authenticated = await BiometricService.instance.authenticateForEdit();
    if (!authenticated || !mounted) return;

    AddExpenseSheet.show(context, existingExpense: expense);
  }

  void _showAllExpenseHistory(BuildContext parentContext, List<Expense> expenses, AppLocalizations? l10n) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final customCategories = ref.read(customExpenseCategoriesProvider);
    final paymentMethods = ref.read(paymentMethodsProvider);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.bottomSheetRadius),
            ),
          ),
          child: Column(
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
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.expenseTransactions ?? 'Expense History',
                      style: AppTypography.h4.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${sortedExpenses.length} ${(l10n?.expenses ?? 'expenses').toLowerCase()}',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: sortedExpenses.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: AppDimensions.screenPaddingHorizontal,
                    endIndent: AppDimensions.screenPaddingHorizontal,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (context, index) {
                    final expense = sortedExpenses[index];
                    final category = ExpenseCategories.getByIdWithCustom(expense.categoryId, customCategories);
                    final paymentMethod = paymentMethods.where((p) => p.id == expense.paymentMethodId).firstOrNull;

                    // Build subtitle with all details
                    final details = <String>[
                      category.name,
                      DateFormat('dd/MM/yyyy').format(expense.date),
                    ];
                    if (paymentMethod != null) {
                      details.add(paymentMethod.displayName);
                    }
                    if (expense.isRecurring && expense.recurringFrequency != null) {
                      details.add(l10n?.recurring ?? 'Recurring');
                    }

                    return ListTile(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showExpenseOptions(parentContext, expense);
                      },
                      leading: Container(
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
                      title: Text(
                        expense.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        details.join(' • '),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '-${CurrencyFormatter.format(expense.amount)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseOptions(BuildContext parentContext, Expense expense) {
    final l10n = AppLocalizations.of(parentContext);
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    showModalBottomSheet(
      context: parentContext,
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
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                expense.name,
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ListTile(
                leading: Icon(
                  LucideIcons.eye,
                  color: AppColors.info,
                ),
                title: Text(
                  l10n?.viewDetails ?? 'View Details',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showExpenseDetails(parentContext, expense);
                },
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.pencil,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                title: Text(
                  l10n?.edit ?? 'Edit',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.authenticateToContinue ?? 'Requires authentication',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.fingerprint,
                  size: 18,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final authenticated = await BiometricService.instance.authenticateForEdit();
                  if (authenticated && mounted) {
                    AddExpenseSheet.show(parentContext, existingExpense: expense);
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n?.delete ?? 'Delete',
                  style: const TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  l10n?.authenticateToContinue ?? 'Requires authentication',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.fingerprint,
                  size: 18,
                  color: AppColors.primary,
                ),
                onTap: () async {
                // Step 1: Show confirmation dialog first
                final confirm = await showDialog<bool>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n?.deleteExpense ?? 'Delete Expense'),
                    content: Text(l10n?.deleteExpenseConfirm ?? 'Are you sure you want to delete this expense of ${CurrencyFormatter.format(expense.amount)}? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                // Step 2: Authenticate after confirmation
                final authenticated = await BiometricService.instance.authenticateForDelete();
                if (!authenticated) return;

                // Step 3: Delete and close sheet
                if (mounted) {
                  Navigator.pop(sheetContext);
                  await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                  AdService.instance.showInterstitialIfDue();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(l10n?.expenseDeleted ?? 'Expense deleted')),
                  );
                }
              },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final l10n = AppLocalizations.of(context);
    // Auth and confirm are handled in the options sheets
    await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.expenseDeleted ?? 'Expense deleted')),
      );
    }
  }

  void _showExpenseDetails(BuildContext parentContext, Expense expense) {
    final l10n = AppLocalizations.of(parentContext);
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final paymentMethods = ref.read(paymentMethodsProvider);
    final customCategories = ref.read(customExpenseCategoriesProvider);
    final category = ExpenseCategories.getByIdWithCustom(expense.categoryId, customCategories);
    final paymentMethod = paymentMethods.where((p) => p.id == expense.paymentMethodId).firstOrNull;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(parentContext).size.height * 0.85,
        ),
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
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.transactionDetails ?? 'Expense Details',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          expense.name,
                          style: AppTypography.h4.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Details
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Column(
                  children: [
                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacing20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.error.withValues(alpha: 0.15),
                            AppColors.error.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n?.amount ?? 'Amount',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '-${CurrencyFormatter.format(expense.amount)}',
                            style: AppTypography.h1.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing20),

                    // Details Grid
                    _ExpenseDetailRow(
                      icon: LucideIcons.tag,
                      label: l10n?.category ?? 'Category',
                      value: category.name,
                      color: category.color,
                      isDark: isDark,
                    ),
                    if (expense.merchantName != null && expense.merchantName!.isNotEmpty)
                      _ExpenseDetailRow(
                        icon: LucideIcons.store,
                        label: l10n?.merchant ?? 'Merchant',
                        value: expense.merchantName!,
                        isDark: isDark,
                      ),
                    if (expense.description != null && expense.description!.isNotEmpty)
                      _ExpenseDetailRow(
                        icon: LucideIcons.fileText,
                        label: l10n?.description ?? 'Description',
                        value: expense.description!,
                        isDark: isDark,
                      ),
                    if (paymentMethod != null)
                      _ExpenseDetailRow(
                        icon: paymentMethod.icon,
                        label: l10n?.paymentMethod ?? 'Payment Method',
                        value: paymentMethod.displayName,
                        isDark: isDark,
                      ),
                    _ExpenseDetailRow(
                      icon: LucideIcons.calendar,
                      label: l10n?.date ?? 'Date',
                      value: DateFormat('dd MMMM yyyy').format(expense.date),
                      isDark: isDark,
                    ),
                    if (expense.isRecurring && expense.recurringFrequency != null)
                      _ExpenseDetailRow(
                        icon: LucideIcons.repeat,
                        label: l10n?.recurring ?? 'Recurring',
                        value: expense.recurringFrequency!.label,
                        isDark: isDark,
                      ),

                    // Receipt Section
                    if (expense.hasReceipt) ...[
                      const SizedBox(height: AppDimensions.spacing24),
                      _ReceiptSection(
                        expense: expense,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacing24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              final authenticated = await BiometricService.instance.authenticateForEdit();
                              if (authenticated && mounted) {
                                AddExpenseSheet.show(parentContext, existingExpense: expense);
                              }
                            },
                            icon: const Icon(LucideIcons.pencil, size: 18),
                            label: Text(l10n?.edit ?? 'Edit'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: sheetContext,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n?.deleteExpense ?? 'Delete Expense?'),
                                  content: Text(l10n?.deleteExpenseConfirm ?? 'Are you sure you want to delete this expense of ${CurrencyFormatter.format(expense.amount)}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n?.cancel ?? 'Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              final authenticated = await BiometricService.instance.authenticateForDelete();
                              if (!authenticated) return;
                              if (mounted) {
                                Navigator.pop(sheetContext);
                                await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(content: Text(l10n?.expenseDeleted ?? 'Expense deleted')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            label: Text(l10n?.delete ?? 'Delete'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacing32),
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
          const SizedBox(height: AppDimensions.spacing16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.noExpensesYet ?? 'No expenses yet',
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.tapAddExpenseToStart ?? 'Tap the + button to add your first expense',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TotalExpensesCard extends StatelessWidget {
  final bool isDark;
  final double totalExpenses;
  final String currencySymbol;
  final String periodLabel;
  final String dateRange;

  const _TotalExpensesCard({
    required this.isDark,
    required this.totalExpenses,
    required this.currencySymbol,
    required this.periodLabel,
    required this.dateRange,
  });

  String _formatAmount(double amount, String symbol) {
    // Format number with proper separators
    final formatted = amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
    // Add thousand separators
    final parts = formatted.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$symbol${parts.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withValues(alpha: 0.15),
            AppColors.error.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.totalExpenses ?? 'Total Expenses',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 12,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateRange,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            _formatAmount(totalExpenses, currencySymbol),
            style: AppTypography.h1.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 36,
            ),
          ),
          if (totalExpenses > 0) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Row(
              children: [
                Icon(
                  LucideIcons.trendingDown,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.spent ?? 'Total spent',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(right: AppDimensions.spacing8),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          labelStyle: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          side: BorderSide(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
        ),
      ),
    );
  }
}

class _CategoryBreakdownCard extends ConsumerWidget {
  final bool isDark;
  final Map<String, double> categoryBreakdown;
  final double totalExpenses;

  const _CategoryBreakdownCard({
    required this.isDark,
    required this.categoryBreakdown,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customCategories = ref.watch(customExpenseCategoriesProvider);

    // Sort categories by amount (highest first)
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
        children: sortedCategories.take(5).map((entry) {
          final category = ExpenseCategories.getByIdWithCustom(entry.key, customCategories);
          final amount = entry.value;
          final percent = totalExpenses > 0 ? amount / totalExpenses : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Text(
                        category.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    minHeight: 6,
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

class _RecentExpensesList extends ConsumerWidget {
  final bool isDark;
  final List<Expense> expenses;
  final Function(Expense) onEdit;
  final Function(Expense) onDelete;
  final Function(Expense)? onViewDetails;

  const _RecentExpensesList({
    required this.isDark,
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
    this.onViewDetails,
  });

  String _formatDate(DateTime date, AppLocalizations? l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return '${l10n?.today ?? 'Today'}, ${DateFormat('h:mm a').format(date)}';
    } else if (expenseDate == yesterday) {
      return '${l10n?.yesterday ?? 'Yesterday'}, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('dd/MM, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customCategories = ref.watch(customExpenseCategoriesProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: expenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          final isLast = index == expenses.length - 1;
          final category = ExpenseCategories.getByIdWithCustom(expense.categoryId, customCategories);

          return Column(
            children: [
              InkWell(
                onTap: () => _showOptionsSheet(context, expense, ref, l10n),
                child: Padding(
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
                              expense.name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  category.name,
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  ' • ${_formatDate(expense.date, l10n)}',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-${CurrencyFormatter.format(expense.amount)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
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

  void _showOptionsSheet(BuildContext parentContext, Expense expense, WidgetRef ref, AppLocalizations? l10n) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final expenseName = expense.name;

    showModalBottomSheet(
      context: parentContext,
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
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                expenseName,
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ListTile(
                leading: Icon(
                  LucideIcons.eye,
                  color: AppColors.info,
                ),
                title: Text(
                  l10n?.viewDetails ?? 'View Details',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onViewDetails?.call(expense);
                },
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.pencil,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                title: Text(
                  l10n?.edit ?? 'Edit',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.authenticateToContinue ?? 'Requires authentication',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.fingerprint,
                  size: 18,
                  color: AppColors.primary,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEdit(expense);
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n?.delete ?? 'Delete',
                  style: const TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  l10n?.authenticateToContinue ?? 'Requires authentication',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.fingerprint,
                  size: 18,
                  color: AppColors.primary,
                ),
                onTap: () async {
                // Step 1: Show confirmation dialog first
                final confirm = await showDialog<bool>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n?.deleteExpense ?? 'Delete Expense'),
                    content: Text(l10n?.deleteExpenseConfirm ?? 'Are you sure you want to delete this expense of ${CurrencyFormatter.format(expense.amount)}? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                // Step 2: Authenticate after confirmation
                final authenticated = await BiometricService.instance.authenticateForDelete();
                if (!authenticated) return;

                // Step 3: Delete and close sheet
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                  onDelete(expense);
                }
              },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Budget Status Section Widget
class _BudgetStatusSection extends ConsumerWidget {
  final bool isDark;

  const _BudgetStatusSection({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final budgetProgress = ref.watch(budgetProgressProvider);
    final overBudget = ref.watch(overBudgetCategoriesProvider);
    final nearLimit = ref.watch(nearLimitCategoriesProvider);

    // Don't show if no budgets are set
    if (budgetProgress.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.budgets ?? 'Budget Status',
                  style: AppTypography.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.budgets),
                  child: Text(
                    l10n?.setBudget ?? 'Set Budget',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacing20),
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
                    LucideIcons.target,
                    size: 40,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                  Text(
                    l10n?.noBudgetSet ?? 'No budgets set for this month',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing4),
                  Text(
                    l10n?.setBudgetZeroRemove ?? 'Set spending limits to track your finances',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.budgets),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: Text(l10n?.setBudget ?? 'Set Budget'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing20,
                        vertical: AppDimensions.spacing12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.budgets ?? 'Budget Status',
                style: AppTypography.h4.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.budgets),
                child: Text(
                  l10n?.dataManagement ?? 'Manage',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Warning Cards for Over Budget / Near Limit
          if (overBudget.isNotEmpty)
            _BudgetWarningCard(
              icon: LucideIcons.alertTriangle,
              color: AppColors.error,
              title: l10n?.budgetsExceeded(overBudget.length) ?? '${overBudget.length} ${overBudget.length == 1 ? 'category' : 'categories'} over budget',
              subtitle: overBudget.map((b) => b.categoryName).take(3).join(', '),
              isDark: isDark,
            ),
          if (nearLimit.isNotEmpty)
            _BudgetWarningCard(
              icon: LucideIcons.alertCircle,
              color: AppColors.warning,
              title: '${nearLimit.length} ${nearLimit.length == 1 ? (l10n?.category ?? 'category') : (l10n?.categories ?? 'categories')} near limit',
              subtitle: nearLimit.map((b) => b.categoryName).take(3).join(', '),
              isDark: isDark,
            ),

          // Budget Progress List
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: budgetProgress.take(4).map((progress) {
                final isLast = progress == budgetProgress.take(4).last;
                return _BudgetProgressTile(
                  progress: progress,
                                    isDark: isDark,
                  showDivider: !isLast,
                );
              }).toList(),
            ),
          ),

          if (budgetProgress.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacing12),
              child: Center(
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.budgets),
                  child: Text(
                    '+${budgetProgress.length - 4} more ${(l10n?.budgets ?? 'budgets').toLowerCase()}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.spacing24),
        ],
      ),
    );
  }
}

class _BudgetWarningCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;

  const _BudgetWarningCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressTile extends StatelessWidget {
  final BudgetProgress progress;
  final bool isDark;
  final bool showDivider;

  const _BudgetProgressTile({
    required this.progress,
    required this.isDark,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final percentUsed = progress.percentUsed.clamp(0.0, 100.0);
    final progressColor = progress.isOverBudget
        ? AppColors.error
        : progress.isNearLimit
            ? AppColors.warning
            : AppColors.success;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progress.categoryName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.format(progress.spentAmount)} / ${CurrencyFormatter.format(progress.budgetAmount)}',
                    style: AppTypography.caption.copyWith(
                      color: progress.isOverBudget
                          ? AppColors.error
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percentUsed / 100).clamp(0.0, 1.0),
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${percentUsed.toStringAsFixed(0)}%',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing12,
            endIndent: AppDimensions.spacing12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

/// Detail row widget for view expense transaction sheet
class _ExpenseDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool isDark;

  const _ExpenseDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    fontWeight: FontWeight.w500,
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

/// Receipt Section Widget for viewing attached receipt
class _ReceiptSection extends StatelessWidget {
  final Expense expense;
  final bool isDark;

  const _ReceiptSection({
    required this.expense,
    required this.isDark,
  });

  List<Map<String, dynamic>> _parseReceiptItems() {
    if (expense.receiptItemsJson == null || expense.receiptItemsJson!.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(expense.receiptItemsJson!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptItems = _parseReceiptItems();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.receipt,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.receiptScanned ?? 'Receipt Attached',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Receipt Image
          if (expense.receiptImagePath != null && expense.receiptImagePath!.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showFullImage(context, expense.receiptImagePath!),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  child: Image.file(
                    File(expense.receiptImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.imageOff,
                            size: 32,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                l10n?.noData ?? 'Image not found',
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.tapToViewFullImage ?? 'Tap to view full image',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  );
                },
              ),
            ),
          ],

          // Receipt Items
          if (receiptItems.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing16),
            const Divider(),
            const SizedBox(height: AppDimensions.spacing12),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(
                  '${l10n?.receiptItems ?? 'Scanned Items'} (${receiptItems.length})',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacing12),
            ...receiptItems.map((item) {
              final name = item['name'] ?? (AppLocalizations.of(context)?.noData ?? 'Unknown Item');
              final price = item['price'] ?? 0.0;
              final quantity = item['quantity'] ?? 1;
              final isSelected = item['isSelected'] ?? true;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      size: 16,
                      color: isSelected
                          ? AppColors.success
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Text(
                        quantity > 1 ? '$name (x$quantity)' : name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          decoration: isSelected ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(price is int ? price.toDouble() : price),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.black87,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n?.noData ?? 'Image not found',
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 24,
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
