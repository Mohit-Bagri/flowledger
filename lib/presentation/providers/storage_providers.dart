import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_account.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/income.dart';
import '../../data/models/expense.dart';
import '../../data/models/budget.dart';
import '../../data/models/goal.dart';
import '../../data/models/recurring_transaction.dart';
import '../../data/storage/storage_service.dart';
import '../../services/sync_service.dart';

/// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// ============================================
// Bank Accounts
// ============================================

/// Bank Accounts Provider
final bankAccountsProvider = StateNotifierProvider<BankAccountsNotifier, List<BankAccount>>((ref) {
  return BankAccountsNotifier(ref.watch(storageServiceProvider));
});

class BankAccountsNotifier extends StateNotifier<List<BankAccount>> {
  final StorageService _storage;

  BankAccountsNotifier(this._storage) : super([]) {
    _loadAccounts();
  }

  void _loadAccounts() {
    state = _storage.getBankAccounts();
  }

  Future<void> addAccount(BankAccount account) async {
    await _storage.saveBankAccount(account);
    state = [...state, account];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateAccount(BankAccount account) async {
    await _storage.saveBankAccount(account);
    state = [
      for (final a in state)
        if (a.id == account.id) account else a
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteAccount(String id) async {
    await _storage.deleteBankAccount(id);
    state = state.where((a) => a.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadAccounts();
}

// ============================================
// Payment Methods
// ============================================

/// Payment Methods Provider
final paymentMethodsProvider = StateNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>((ref) {
  return PaymentMethodsNotifier(ref.watch(storageServiceProvider));
});

class PaymentMethodsNotifier extends StateNotifier<List<PaymentMethod>> {
  final StorageService _storage;

  PaymentMethodsNotifier(this._storage) : super([]) {
    _loadMethods();
  }

  void _loadMethods() {
    state = _storage.getPaymentMethods();
  }

  Future<void> addMethod(PaymentMethod method) async {
    await _storage.savePaymentMethod(method);
    state = [...state, method];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateMethod(PaymentMethod method) async {
    await _storage.savePaymentMethod(method);
    state = [
      for (final m in state)
        if (m.id == method.id) method else m
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteMethod(String id) async {
    await _storage.deletePaymentMethod(id);
    state = state.where((m) => m.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadMethods();
}

// ============================================
// Income Sources (Income Entries)
// ============================================

/// Income Sources Provider
final incomeSourcesProvider = StateNotifierProvider<IncomeSourcesNotifier, List<IncomeSource>>((ref) {
  return IncomeSourcesNotifier(ref.watch(storageServiceProvider));
});

class IncomeSourcesNotifier extends StateNotifier<List<IncomeSource>> {
  final StorageService _storage;

  IncomeSourcesNotifier(this._storage) : super([]) {
    _loadSources();
  }

  void _loadSources() {
    state = _storage.getIncomeSources();
  }

  Future<void> addSource(IncomeSource source) async {
    await _storage.saveIncomeSource(source);
    state = [...state, source]..sort((a, b) => b.date.compareTo(a.date));
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateSource(IncomeSource source) async {
    await _storage.saveIncomeSource(source);
    state = [
      for (final s in state)
        if (s.id == source.id) source else s
    ]..sort((a, b) => b.date.compareTo(a.date));
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteSource(String id) async {
    await _storage.deleteIncomeSource(id);
    state = state.where((s) => s.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  List<IncomeSource> getForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return state
        .where((s) => s.date.isAfter(start) && s.date.isBefore(end))
        .toList();
  }

  void refresh() => _loadSources();
}

// ============================================
// Income Transactions - DEPRECATED (Removed)
// ============================================
// NOTE: income_transactions table is no longer used.
// All income entries are now stored in income_sources table.
// Use incomeSourcesProvider instead.
// The 3-table architecture is: income_sources, recurring_transactions, expenses

// ============================================
// Custom Expense Categories
// ============================================

/// Custom Expense Categories Provider
final customExpenseCategoriesProvider = StateNotifierProvider<CustomExpenseCategoriesNotifier, List<ExpenseCategory>>((ref) {
  return CustomExpenseCategoriesNotifier(ref.watch(storageServiceProvider));
});

class CustomExpenseCategoriesNotifier extends StateNotifier<List<ExpenseCategory>> {
  final StorageService _storage;

  CustomExpenseCategoriesNotifier(this._storage) : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    state = _storage.getCustomExpenseCategories();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _storage.saveCustomExpenseCategory(category);
    state = [...state, category];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    await _storage.saveCustomExpenseCategory(category);
    state = [
      for (final c in state)
        if (c.id == category.id) category else c
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteCategory(String id) async {
    await _storage.deleteCustomExpenseCategory(id);
    state = state.where((c) => c.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadCategories();
}

/// Combined expense categories (system + custom)
final allExpenseCategoriesProvider = Provider<List<ExpenseCategory>>((ref) {
  final customCategories = ref.watch(customExpenseCategoriesProvider);
  return [...ExpenseCategories.all, ...customCategories];
});

// ============================================
// Custom Income Categories
// ============================================

/// Custom Income Categories Provider
final customIncomeCategoriesProvider = StateNotifierProvider<CustomIncomeCategoriesNotifier, List<IncomeCategoryModel>>((ref) {
  return CustomIncomeCategoriesNotifier(ref.watch(storageServiceProvider));
});

class CustomIncomeCategoriesNotifier extends StateNotifier<List<IncomeCategoryModel>> {
  final StorageService _storage;

  CustomIncomeCategoriesNotifier(this._storage) : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    state = _storage.getCustomIncomeCategories();
  }

  Future<void> addCategory(IncomeCategoryModel category) async {
    await _storage.saveCustomIncomeCategory(category);
    state = [...state, category];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateCategory(IncomeCategoryModel category) async {
    await _storage.saveCustomIncomeCategory(category);
    state = [
      for (final c in state)
        if (c.id == category.id) category else c
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteCategory(String id) async {
    await _storage.deleteCustomIncomeCategory(id);
    state = state.where((c) => c.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadCategories();
}

/// Combined income categories (system + custom)
final allIncomeCategoriesProvider = Provider<List<IncomeCategoryModel>>((ref) {
  final customCategories = ref.watch(customIncomeCategoriesProvider);
  return [...IncomeCategories.all, ...customCategories];
});

// ============================================
// Merchants
// ============================================

/// Merchants Provider
final merchantsProvider = StateNotifierProvider<MerchantsNotifier, List<String>>((ref) {
  return MerchantsNotifier(ref.watch(storageServiceProvider));
});

class MerchantsNotifier extends StateNotifier<List<String>> {
  final StorageService _storage;

  MerchantsNotifier(this._storage) : super([]) {
    _loadMerchants();
  }

  void _loadMerchants() {
    state = _storage.getMerchants();
  }

  Future<void> addMerchant(String merchantName) async {
    if (merchantName.trim().isEmpty) return;

    // Check if already exists (case-insensitive)
    final normalizedName = merchantName.trim().toLowerCase();
    if (state.any((m) => m.toLowerCase() == normalizedName)) return;

    await _storage.saveMerchant(merchantName);
    state = [...state, merchantName.trim()]..sort();
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteMerchant(String merchantName) async {
    await _storage.deleteMerchant(merchantName);
    state = state.where((m) => m.toLowerCase() != merchantName.toLowerCase()).toList();
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadMerchants();
}

// ============================================
// Expenses
// ============================================

/// Expenses Provider
final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier(ref.watch(storageServiceProvider));
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final StorageService _storage;

  ExpensesNotifier(this._storage) : super([]) {
    _loadExpenses();
  }

  void _loadExpenses() {
    state = _storage.getExpenses();
  }

  Future<void> addExpense(Expense expense) async {
    await _storage.saveExpense(expense);
    state = [...state, expense]..sort((a, b) => b.date.compareTo(a.date));
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateExpense(Expense expense) async {
    await _storage.saveExpense(expense);
    state = [
      for (final e in state)
        if (e.id == expense.id) expense else e
    ]..sort((a, b) => b.date.compareTo(a.date));
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteExpense(String id) async {
    await _storage.deleteExpense(id);
    state = state.where((e) => e.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  List<Expense> getForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return state
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  void refresh() => _loadExpenses();
}

// ============================================
// Budgets
// ============================================

/// Budgets Provider
final budgetsProvider = StateNotifierProvider<BudgetsNotifier, List<CategoryBudget>>((ref) {
  return BudgetsNotifier(ref.watch(storageServiceProvider));
});

class BudgetsNotifier extends StateNotifier<List<CategoryBudget>> {
  final StorageService _storage;

  BudgetsNotifier(this._storage) : super([]) {
    _loadBudgets();
  }

  void _loadBudgets() {
    state = _storage.getBudgets();
  }

  Future<void> addBudget(CategoryBudget budget) async {
    await _storage.saveBudget(budget);
    state = [...state, budget];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateBudget(CategoryBudget budget) async {
    await _storage.saveBudget(budget);
    state = [
      for (final b in state)
        if (b.id == budget.id) budget else b
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteBudget(String id) async {
    await _storage.deleteBudget(id);
    state = state.where((b) => b.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  /// Set or update budget for a category in a specific month
  Future<void> setBudgetForCategory({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
    String currencyCode = 'INR',
  }) async {
    // Check if budget already exists for this category/month/year/currency
    final existing = state.where(
      (b) => b.categoryId == categoryId &&
             b.month == month &&
             b.year == year &&
             b.currencyCode == currencyCode,
    ).toList();

    if (existing.isNotEmpty) {
      // Update existing
      final updated = existing.first.copyWith(
        amount: amount,
        updatedAt: DateTime.now(),
      );
      await updateBudget(updated);
    } else {
      // Create new
      final newBudget = CategoryBudget(
        id: 'budget_${DateTime.now().millisecondsSinceEpoch}_$categoryId',
        categoryId: categoryId,
        amount: amount,
        currencyCode: currencyCode,
        month: month,
        year: year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await addBudget(newBudget);
    }
  }

  /// Get budgets for a specific month
  List<CategoryBudget> getBudgetsForMonth(int month, int year) {
    return state.where((b) => b.month == month && b.year == year).toList();
  }

  /// Copy budgets from one month to another
  Future<void> copyBudgetsToMonth(
    int fromMonth,
    int fromYear,
    int toMonth,
    int toYear,
  ) async {
    final newBudgets = await _storage.copyBudgetsToMonth(
      fromMonth,
      fromYear,
      toMonth,
      toYear,
    );
    state = [...state, ...newBudgets];
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadBudgets();
}

/// Budgets for current month provider
final currentMonthBudgetsProvider = Provider<List<CategoryBudget>>((ref) {
  final now = DateTime.now();
  final budgets = ref.watch(budgetsProvider);
  return budgets.where((b) => b.month == now.month && b.year == now.year).toList();
});

/// Budget progress for current month
final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final now = DateTime.now();
  final budgets = ref.watch(currentMonthBudgetsProvider);
  final expenses = ref.watch(expensesProvider);
  final allCategories = ref.watch(allExpenseCategoriesProvider);

  // Get expenses for current month
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final monthExpenses = expenses.where(
    (e) => e.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
           e.date.isBefore(monthEnd.add(const Duration(seconds: 1))),
  ).toList();

  // Calculate spending per category
  final spendingByCategory = <String, double>{};
  for (final expense in monthExpenses) {
    spendingByCategory[expense.categoryId] =
        (spendingByCategory[expense.categoryId] ?? 0) + expense.amount;
  }

  // Build progress list
  final progressList = <BudgetProgress>[];
  for (final budget in budgets) {
    final category = allCategories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () => ExpenseCategories.other,
    );
    progressList.add(BudgetProgress(
      categoryId: budget.categoryId,
      categoryName: category.name,
      budgetAmount: budget.amount,
      spentAmount: spendingByCategory[budget.categoryId] ?? 0,
      month: budget.month,
      year: budget.year,
    ));
  }

  // Sort by percentage used (highest first)
  progressList.sort((a, b) => b.percentUsed.compareTo(a.percentUsed));

  return progressList;
});

/// Total budgeted amount for current month
final totalBudgetedProvider = Provider<double>((ref) {
  final budgets = ref.watch(currentMonthBudgetsProvider);
  return budgets.fold(0.0, (sum, b) => sum + b.amount);
});

/// Categories with over-budget status
final overBudgetCategoriesProvider = Provider<List<BudgetProgress>>((ref) {
  final progress = ref.watch(budgetProgressProvider);
  return progress.where((p) => p.isOverBudget).toList();
});

/// Categories near budget limit (>80%)
final nearLimitCategoriesProvider = Provider<List<BudgetProgress>>((ref) {
  final progress = ref.watch(budgetProgressProvider);
  return progress.where((p) => p.isNearLimit).toList();
});

// ============================================
// Goals
// ============================================

/// Goals Provider
final goalsProvider = StateNotifierProvider<GoalsNotifier, List<SavingsGoal>>((ref) {
  return GoalsNotifier(ref.watch(storageServiceProvider));
});

class GoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  final StorageService _storage;

  GoalsNotifier(this._storage) : super([]) {
    _loadGoals();
  }

  void _loadGoals() {
    state = _storage.getGoals();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await _storage.saveGoal(goal);
    state = [goal, ...state];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await _storage.saveGoal(goal);
    state = [
      for (final g in state)
        if (g.id == goal.id) goal else g
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteGoal(String id) async {
    await _storage.deleteGoal(id);
    state = state.where((g) => g.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  /// Add money to a goal
  Future<SavingsGoal?> addToGoal(String id, double amount) async {
    final updatedGoal = await _storage.addToGoal(id, amount);
    if (updatedGoal != null) {
      state = [
        for (final g in state)
          if (g.id == id) updatedGoal else g
      ];
      SyncService.instance.triggerAutoSync();
    }
    return updatedGoal;
  }

  /// Withdraw money from a goal
  Future<SavingsGoal?> withdrawFromGoal(String id, double amount) async {
    final updatedGoal = await _storage.withdrawFromGoal(id, amount);
    if (updatedGoal != null) {
      state = [
        for (final g in state)
          if (g.id == id) updatedGoal else g
      ];
      SyncService.instance.triggerAutoSync();
    }
    return updatedGoal;
  }

  void refresh() => _loadGoals();
}

/// Active (non-completed) goals
final activeGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.where((g) => !g.isCompleted).toList();
});

/// Completed goals
final completedGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.where((g) => g.isCompleted).toList();
});

/// Total saved across all active goals
final totalSavedInGoalsProvider = Provider<double>((ref) {
  final activeGoals = ref.watch(activeGoalsProvider);
  return activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
});

/// Total target across all active goals
final totalGoalsTargetProvider = Provider<double>((ref) {
  final activeGoals = ref.watch(activeGoalsProvider);
  return activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
});

/// Goals that are overdue (past target date and not completed)
final overdueGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final activeGoals = ref.watch(activeGoalsProvider);
  return activeGoals.where((g) => g.isOverdue).toList();
});

// ============================================
// Recurring Transactions
// ============================================

/// Recurring Transactions Provider
final recurringTransactionsProvider = StateNotifierProvider<RecurringTransactionsNotifier, List<RecurringTransaction>>((ref) {
  return RecurringTransactionsNotifier(ref.watch(storageServiceProvider));
});

class RecurringTransactionsNotifier extends StateNotifier<List<RecurringTransaction>> {
  final StorageService _storage;

  RecurringTransactionsNotifier(this._storage) : super([]) {
    _loadRecurringTransactions();
  }

  void _loadRecurringTransactions() {
    state = _storage.getRecurringTransactions();
  }

  Future<void> addRecurring(RecurringTransaction recurring) async {
    await _storage.saveRecurringTransaction(recurring);
    state = [recurring, ...state];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    await _storage.saveRecurringTransaction(recurring);
    state = [
      for (final r in state)
        if (r.id == recurring.id) recurring else r
    ];
    SyncService.instance.triggerAutoSync();
  }

  Future<void> deleteRecurring(String id) async {
    await _storage.deleteRecurringTransaction(id);
    state = state.where((r) => r.id != id).toList();
    SyncService.instance.triggerAutoSync();
  }

  /// Mark recurring transaction as processed (advances next due date)
  Future<RecurringTransaction?> processRecurring(String id) async {
    final processed = await _storage.processRecurringTransaction(id);
    if (processed != null) {
      state = [
        for (final r in state)
          if (r.id == id) processed else r
      ];
      SyncService.instance.triggerAutoSync();
    }
    return processed;
  }

  /// Toggle active status
  Future<void> toggleActive(String id, bool isActive) async {
    await _storage.toggleRecurringTransactionActive(id, isActive);
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isActive: isActive, updatedAt: DateTime.now()) else r
    ];
    SyncService.instance.triggerAutoSync();
  }

  void refresh() => _loadRecurringTransactions();
}

/// Active recurring transactions
final activeRecurringTransactionsProvider = Provider<List<RecurringTransaction>>((ref) {
  final recurring = ref.watch(recurringTransactionsProvider);
  return recurring.where((r) => r.isActive).toList();
});

/// Due recurring transactions (due today or overdue)
final dueRecurringTransactionsProvider = Provider<List<RecurringTransaction>>((ref) {
  final recurring = ref.watch(recurringTransactionsProvider);
  return recurring.where((r) => r.isDue).toList();
});

/// Recurring income transactions
final recurringIncomeProvider = Provider<List<RecurringTransaction>>((ref) {
  final recurring = ref.watch(activeRecurringTransactionsProvider);
  return recurring.where((r) => r.type == RecurringType.income).toList();
});

/// Recurring expense transactions
final recurringExpenseProvider = Provider<List<RecurringTransaction>>((ref) {
  final recurring = ref.watch(activeRecurringTransactionsProvider);
  return recurring.where((r) => r.type == RecurringType.expense).toList();
});

/// Count of due recurring transactions (for badge/notification)
final dueRecurringCountProvider = Provider<int>((ref) {
  return ref.watch(dueRecurringTransactionsProvider).length;
});

// ============================================
// Computed Values
// ============================================

/// Total income for current month
final currentMonthIncomeProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final sources = ref.watch(incomeSourcesProvider);
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return sources
      .where((s) => s.date.isAfter(start) && s.date.isBefore(end))
      .fold(0.0, (sum, s) => sum + s.amount);
});

/// Total expenses for current month
final currentMonthExpensesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final expenses = ref.watch(expensesProvider);
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return expenses
      .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
      .fold(0.0, (sum, e) => sum + e.amount);
});

/// Net balance for current month
final currentMonthBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(currentMonthIncomeProvider);
  final expenses = ref.watch(currentMonthExpensesProvider);
  return income - expenses;
});

/// Saving rate for current month
final currentMonthSavingRateProvider = Provider<double>((ref) {
  final income = ref.watch(currentMonthIncomeProvider);
  final balance = ref.watch(currentMonthBalanceProvider);
  if (income == 0) return 0;
  return (balance / income) * 100;
});

// ============================================
// Date Range Selection
// ============================================

/// Date Range Preset Types
enum DateRangePreset {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('Last 3 Months'),
  custom('Custom Range');

  final String label;
  const DateRangePreset(this.label);
}

/// Date Range State
class DateRangeState {
  final DateRangePreset preset;
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeState({
    required this.preset,
    required this.startDate,
    required this.endDate,
  });

  factory DateRangeState.thisMonth() {
    final now = DateTime.now();
    return DateRangeState(
      preset: DateRangePreset.thisMonth,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  factory DateRangeState.lastMonth() {
    final now = DateTime.now();
    return DateRangeState(
      preset: DateRangePreset.lastMonth,
      startDate: DateTime(now.year, now.month - 1, 1),
      endDate: DateTime(now.year, now.month, 0, 23, 59, 59),
    );
  }

  factory DateRangeState.last3Months() {
    final now = DateTime.now();
    return DateRangeState(
      preset: DateRangePreset.last3Months,
      startDate: DateTime(now.year, now.month - 2, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  factory DateRangeState.custom(DateTime start, DateTime end) {
    return DateRangeState(
      preset: DateRangePreset.custom,
      startDate: start,
      endDate: end,
    );
  }

  /// Get the preset label (e.g., "This Month", "Last Month")
  String get presetLabel => preset.label;

  /// Get formatted date range string (dd/mm/yyyy format)
  String get dateRangeLabel {
    String formatDate(DateTime d) {
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }

  /// Get short date range with year (1 Jan'25 - 31 Jan'25)
  String get shortDateRangeLabel {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String formatDate(DateTime d) {
      final yearSuffix = "'${d.year.toString().substring(2)}";
      return '${d.day} ${months[d.month - 1]}$yearSuffix';
    }
    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }

  /// Display label for the selector button
  String get displayLabel {
    if (preset == DateRangePreset.custom) {
      return shortDateRangeLabel;
    }
    return preset.label;
  }

  /// Get period label for summary cards (e.g., "Total This Month", "Total Last Month")
  String get periodLabel {
    switch (preset) {
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.last3Months:
        return 'Last 3 Months';
      case DateRangePreset.custom:
        return shortDateRangeLabel;
    }
  }
}

/// Date Range Provider
final dateRangeProvider = StateNotifierProvider<DateRangeNotifier, DateRangeState>((ref) {
  return DateRangeNotifier();
});

class DateRangeNotifier extends StateNotifier<DateRangeState> {
  DateRangeNotifier() : super(DateRangeState.thisMonth());

  void setThisMonth() {
    state = DateRangeState.thisMonth();
  }

  void setLastMonth() {
    state = DateRangeState.lastMonth();
  }

  void setLast3Months() {
    state = DateRangeState.last3Months();
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = DateRangeState.custom(start, end);
  }

  void setPreset(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.thisMonth:
        setThisMonth();
        break;
      case DateRangePreset.lastMonth:
        setLastMonth();
        break;
      case DateRangePreset.last3Months:
        setLast3Months();
        break;
      case DateRangePreset.custom:
        // For custom, use setCustomRange instead
        break;
    }
  }
}

/// Filtered Expenses by Date Range
final filteredExpensesByDateProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final dateRange = ref.watch(dateRangeProvider);
  return expenses.where((e) =>
      e.date.isAfter(dateRange.startDate.subtract(const Duration(seconds: 1))) &&
      e.date.isBefore(dateRange.endDate.add(const Duration(seconds: 1)))).toList();
});

/// Filtered Income Transactions by Date Range
final filteredIncomeByDateProvider = Provider<List<IncomeSource>>((ref) {
  final incomeSources = ref.watch(incomeSourcesProvider);
  final dateRange = ref.watch(dateRangeProvider);
  return incomeSources.where((s) =>
      s.date.isAfter(dateRange.startDate.subtract(const Duration(seconds: 1))) &&
      s.date.isBefore(dateRange.endDate.add(const Duration(seconds: 1)))).toList();
});
