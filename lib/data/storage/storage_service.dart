import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bank_account.dart';
import '../models/payment_method.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/recurring_transaction.dart';

/// Box names
class HiveBoxes {
  static const String bankAccounts = 'bank_accounts';
  static const String paymentMethods = 'payment_methods';
  static const String incomeSources = 'income_sources';
  static const String incomeTransactions = 'income_transactions';
  static const String expenses = 'expenses';
  static const String expenseCategories = 'expense_categories';
  static const String incomeCategories = 'income_categories';
  static const String merchants = 'merchants';
  static const String budgets = 'budgets';
  static const String goals = 'goals';
  static const String recurringTransactions = 'recurring_transactions';
  static const String settings = 'settings';
}

/// Storage Service for managing local data with Hive
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  late Box<String> _bankAccountsBox;
  late Box<String> _paymentMethodsBox;
  late Box<String> _incomeSourcesBox;
  late Box<String> _incomeTransactionsBox;
  late Box<String> _expensesBox;
  late Box<String> _expenseCategoriesBox;
  late Box<String> _incomeCategoriesBox;
  late Box<String> _merchantsBox;
  late Box<String> _budgetsBox;
  late Box<String> _goalsBox;
  late Box<String> _recurringTransactionsBox;
  late Box<dynamic> _settingsBox;

  bool _initialized = false;

  /// Initialize all Hive boxes
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    _bankAccountsBox = await Hive.openBox<String>(HiveBoxes.bankAccounts);
    _paymentMethodsBox = await Hive.openBox<String>(HiveBoxes.paymentMethods);
    _incomeSourcesBox = await Hive.openBox<String>(HiveBoxes.incomeSources);
    _incomeTransactionsBox = await Hive.openBox<String>(HiveBoxes.incomeTransactions);
    _expensesBox = await Hive.openBox<String>(HiveBoxes.expenses);
    _expenseCategoriesBox = await Hive.openBox<String>(HiveBoxes.expenseCategories);
    _incomeCategoriesBox = await Hive.openBox<String>(HiveBoxes.incomeCategories);
    _merchantsBox = await Hive.openBox<String>(HiveBoxes.merchants);
    _budgetsBox = await Hive.openBox<String>(HiveBoxes.budgets);
    _goalsBox = await Hive.openBox<String>(HiveBoxes.goals);
    _recurringTransactionsBox = await Hive.openBox<String>(HiveBoxes.recurringTransactions);
    _settingsBox = await Hive.openBox(HiveBoxes.settings);

    _initialized = true;
  }

  // ============================================
  // Bank Accounts
  // ============================================

  /// Get all bank accounts
  List<BankAccount> getBankAccounts() {
    return _bankAccountsBox.values
        .map((json) => BankAccount.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a single bank account by ID
  BankAccount? getBankAccount(String id) {
    final json = _bankAccountsBox.get(id);
    if (json == null) return null;
    return BankAccount.fromJson(jsonDecode(json));
  }

  /// Save a bank account
  Future<void> saveBankAccount(BankAccount account) async {
    await _bankAccountsBox.put(account.id, jsonEncode(account.toJson()));
  }

  /// Delete a bank account
  Future<void> deleteBankAccount(String id) async {
    await _bankAccountsBox.delete(id);
  }

  // ============================================
  // Payment Methods
  // ============================================

  /// Get all payment methods
  List<PaymentMethod> getPaymentMethods() {
    return _paymentMethodsBox.values
        .map((json) => PaymentMethod.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a single payment method by ID
  PaymentMethod? getPaymentMethod(String id) {
    final json = _paymentMethodsBox.get(id);
    if (json == null) return null;
    return PaymentMethod.fromJson(jsonDecode(json));
  }

  /// Save a payment method
  Future<void> savePaymentMethod(PaymentMethod method) async {
    await _paymentMethodsBox.put(method.id, jsonEncode(method.toJson()));
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String id) async {
    await _paymentMethodsBox.delete(id);
  }

  // ============================================
  // Income Sources (Income Entries)
  // ============================================

  /// Get all income sources
  List<IncomeSource> getIncomeSources() {
    return _incomeSourcesBox.values
        .map((json) => IncomeSource.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get a single income source by ID
  IncomeSource? getIncomeSource(String id) {
    final json = _incomeSourcesBox.get(id);
    if (json == null) return null;
    return IncomeSource.fromJson(jsonDecode(json));
  }

  /// Get income sources for a date range
  List<IncomeSource> getIncomeSourcesInRange(DateTime start, DateTime end) {
    return getIncomeSources()
        .where((s) => s.date.isAfter(start) && s.date.isBefore(end))
        .toList();
  }

  /// Get income sources for a specific recurring transaction
  List<IncomeSource> getIncomeSourcesForRecurring(String recurringId) {
    return getIncomeSources()
        .where((s) => s.recurringTransactionId == recurringId)
        .toList();
  }

  /// Save an income source
  Future<void> saveIncomeSource(IncomeSource source) async {
    await _incomeSourcesBox.put(source.id, jsonEncode(source.toJson()));
  }

  /// Delete an income source
  Future<void> deleteIncomeSource(String id) async {
    await _incomeSourcesBox.delete(id);
  }

  // ============================================
  // Income Transactions
  // ============================================

  /// Get all income transactions
  List<IncomeTransaction> getIncomeTransactions() {
    return _incomeTransactionsBox.values
        .map((json) => IncomeTransaction.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get income transactions for a specific recurring transaction
  List<IncomeTransaction> getIncomeTransactionsForRecurring(String recurringId) {
    return getIncomeTransactions()
        .where((t) => t.recurringTransactionId == recurringId)
        .toList();
  }

  /// Get income transactions for a date range
  List<IncomeTransaction> getIncomeTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return getIncomeTransactions()
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  /// Save an income transaction
  Future<void> saveIncomeTransaction(IncomeTransaction transaction) async {
    await _incomeTransactionsBox.put(
      transaction.id,
      jsonEncode(transaction.toJson()),
    );
  }

  /// Delete an income transaction
  Future<void> deleteIncomeTransaction(String id) async {
    await _incomeTransactionsBox.delete(id);
  }

  // ============================================
  // Custom Expense Categories
  // ============================================

  /// Get all custom expense categories
  List<ExpenseCategory> getCustomExpenseCategories() {
    return _expenseCategoriesBox.values
        .map((json) => ExpenseCategory.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => (a.sortOrder).compareTo(b.sortOrder));
  }

  /// Get a single custom expense category by ID
  ExpenseCategory? getCustomExpenseCategory(String id) {
    final json = _expenseCategoriesBox.get(id);
    if (json == null) return null;
    return ExpenseCategory.fromJson(jsonDecode(json));
  }

  /// Save a custom expense category
  Future<void> saveCustomExpenseCategory(ExpenseCategory category) async {
    await _expenseCategoriesBox.put(category.id, jsonEncode(category.toJson()));
  }

  /// Delete a custom expense category
  Future<void> deleteCustomExpenseCategory(String id) async {
    await _expenseCategoriesBox.delete(id);
  }

  // ============================================
  // Custom Income Categories
  // ============================================

  /// Get all custom income categories
  List<IncomeCategoryModel> getCustomIncomeCategories() {
    return _incomeCategoriesBox.values
        .map((json) => IncomeCategoryModel.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => (a.sortOrder).compareTo(b.sortOrder));
  }

  /// Get a single custom income category by ID
  IncomeCategoryModel? getCustomIncomeCategory(String id) {
    final json = _incomeCategoriesBox.get(id);
    if (json == null) return null;
    return IncomeCategoryModel.fromJson(jsonDecode(json));
  }

  /// Save a custom income category
  Future<void> saveCustomIncomeCategory(IncomeCategoryModel category) async {
    await _incomeCategoriesBox.put(category.id, jsonEncode(category.toJson()));
  }

  /// Delete a custom income category
  Future<void> deleteCustomIncomeCategory(String id) async {
    await _incomeCategoriesBox.delete(id);
  }

  // ============================================
  // Merchants
  // ============================================

  /// Get all saved merchants
  List<String> getMerchants() {
    return _merchantsBox.values.toList()..sort();
  }

  /// Save a merchant (if not already exists)
  Future<void> saveMerchant(String merchantName) async {
    final normalizedName = merchantName.trim().toLowerCase();
    if (normalizedName.isEmpty) return;

    // Check if merchant already exists (case-insensitive)
    final existing = _merchantsBox.values
        .where((m) => m.toLowerCase() == normalizedName)
        .toList();

    if (existing.isEmpty) {
      await _merchantsBox.put(normalizedName, merchantName.trim());
    }
  }

  /// Delete a merchant
  Future<void> deleteMerchant(String merchantName) async {
    final normalizedName = merchantName.trim().toLowerCase();
    await _merchantsBox.delete(normalizedName);
  }

  // ============================================
  // Expenses
  // ============================================

  /// Get all expenses
  List<Expense> getExpenses() {
    return _expensesBox.values
        .map((json) => Expense.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get expenses for a date range
  List<Expense> getExpensesInRange(DateTime start, DateTime end) {
    return getExpenses()
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  /// Get expenses for a specific category
  List<Expense> getExpensesByCategory(String categoryId) {
    return getExpenses()
        .where((e) => e.categoryId == categoryId)
        .toList();
  }

  /// Save an expense
  Future<void> saveExpense(Expense expense) async {
    await _expensesBox.put(expense.id, jsonEncode(expense.toJson()));
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    await _expensesBox.delete(id);
  }

  // ============================================
  // Budgets
  // ============================================

  /// Get all budgets
  List<CategoryBudget> getBudgets() {
    return _budgetsBox.values
        .map((json) => CategoryBudget.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Get budgets for a specific month/year
  List<CategoryBudget> getBudgetsForMonth(int month, int year) {
    return getBudgets()
        .where((b) => b.month == month && b.year == year)
        .toList();
  }

  /// Get budget for a specific category in a month/year
  CategoryBudget? getBudgetForCategory(String categoryId, int month, int year) {
    final budgets = getBudgetsForMonth(month, year);
    try {
      return budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  /// Save a budget
  Future<void> saveBudget(CategoryBudget budget) async {
    await _budgetsBox.put(budget.id, jsonEncode(budget.toJson()));
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    await _budgetsBox.delete(id);
  }

  /// Copy budgets from one month to another
  Future<List<CategoryBudget>> copyBudgetsToMonth(
    int fromMonth,
    int fromYear,
    int toMonth,
    int toYear,
  ) async {
    final sourceBudgets = getBudgetsForMonth(fromMonth, fromYear);
    final newBudgets = <CategoryBudget>[];

    for (final budget in sourceBudgets) {
      final newBudget = CategoryBudget(
        id: 'budget_${DateTime.now().millisecondsSinceEpoch}_${budget.categoryId}',
        categoryId: budget.categoryId,
        amount: budget.amount,
        month: toMonth,
        year: toYear,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveBudget(newBudget);
      newBudgets.add(newBudget);
    }

    return newBudgets;
  }

  // ============================================
  // Goals
  // ============================================

  /// Get all goals
  List<SavingsGoal> getGoals() {
    return _goalsBox.values
        .map((json) => SavingsGoal.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get active (non-completed) goals
  List<SavingsGoal> getActiveGoals() {
    return getGoals().where((g) => !g.isCompleted).toList();
  }

  /// Get completed goals
  List<SavingsGoal> getCompletedGoals() {
    return getGoals().where((g) => g.isCompleted).toList();
  }

  /// Get a single goal by ID
  SavingsGoal? getGoal(String id) {
    final json = _goalsBox.get(id);
    if (json == null) return null;
    return SavingsGoal.fromJson(jsonDecode(json));
  }

  /// Save a goal
  Future<void> saveGoal(SavingsGoal goal) async {
    await _goalsBox.put(goal.id, jsonEncode(goal.toJson()));
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
  }

  /// Add amount to a goal
  Future<SavingsGoal?> addToGoal(String id, double amount) async {
    final goal = getGoal(id);
    if (goal == null) return null;

    final previousAmount = goal.currentAmount;
    final newAmount = goal.currentAmount + amount;
    final newMilestone = goal.getNewMilestone(previousAmount);

    var updatedGoal = goal.copyWith(
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
    );

    // Add milestone if reached
    if (newMilestone != null) {
      updatedGoal = updatedGoal.copyWith(
        milestonesReached: [...updatedGoal.milestonesReached, newMilestone],
      );
    }

    // Mark as completed if target reached
    if (newAmount >= goal.targetAmount && !goal.isCompleted) {
      updatedGoal = updatedGoal.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
    }

    await saveGoal(updatedGoal);
    return updatedGoal;
  }

  /// Withdraw amount from a goal
  Future<SavingsGoal?> withdrawFromGoal(String id, double amount) async {
    final goal = getGoal(id);
    if (goal == null) return null;

    final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);

    var updatedGoal = goal.copyWith(
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
    );

    // Unmark completion if withdrawn below target
    if (newAmount < goal.targetAmount && goal.isCompleted) {
      updatedGoal = updatedGoal.copyWith(
        isCompleted: false,
        completedAt: null,
      );
    }

    await saveGoal(updatedGoal);
    return updatedGoal;
  }

  // ============================================
  // Recurring Transactions
  // ============================================

  /// Get all recurring transactions
  List<RecurringTransaction> getRecurringTransactions() {
    return _recurringTransactionsBox.values
        .map((json) => RecurringTransaction.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  /// Get active recurring transactions
  List<RecurringTransaction> getActiveRecurringTransactions() {
    return getRecurringTransactions().where((r) => r.isActive).toList();
  }

  /// Get due recurring transactions (today or overdue)
  List<RecurringTransaction> getDueRecurringTransactions() {
    return getActiveRecurringTransactions().where((r) => r.isDue).toList();
  }

  /// Get a single recurring transaction by ID
  RecurringTransaction? getRecurringTransaction(String id) {
    final json = _recurringTransactionsBox.get(id);
    if (json == null) return null;
    return RecurringTransaction.fromJson(jsonDecode(json));
  }

  /// Save a recurring transaction
  Future<void> saveRecurringTransaction(RecurringTransaction transaction) async {
    await _recurringTransactionsBox.put(transaction.id, jsonEncode(transaction.toJson()));
  }

  /// Delete a recurring transaction
  Future<void> deleteRecurringTransaction(String id) async {
    await _recurringTransactionsBox.delete(id);
  }

  /// Mark a recurring transaction as processed and advance next due date
  Future<RecurringTransaction?> processRecurringTransaction(String id) async {
    final transaction = getRecurringTransaction(id);
    if (transaction == null) return null;

    final processed = transaction.markAsProcessed();
    await saveRecurringTransaction(processed);
    return processed;
  }

  /// Toggle recurring transaction active status
  Future<void> toggleRecurringTransactionActive(String id, bool isActive) async {
    final transaction = getRecurringTransaction(id);
    if (transaction == null) return;

    final updated = transaction.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    await saveRecurringTransaction(updated);
  }

  // ============================================
  // Settings
  // ============================================

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Save a setting value
  Future<void> saveSetting<T>(String key, T value) async {
    await _settingsBox.put(key, value);
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// Clear all data (for logout/reset)
  Future<void> clearAllData() async {
    await _bankAccountsBox.clear();
    await _paymentMethodsBox.clear();
    await _incomeSourcesBox.clear();
    await _incomeTransactionsBox.clear();
    await _expensesBox.clear();
    await _expenseCategoriesBox.clear();
    await _incomeCategoriesBox.clear();
    await _merchantsBox.clear();
    await _budgetsBox.clear();
    await _goalsBox.clear();
    await _recurringTransactionsBox.clear();
    await _settingsBox.clear();
  }

  /// Clear all transaction data (keeps settings) - used for restore from cloud
  Future<void> clearAllTransactionData() async {
    await _bankAccountsBox.clear();
    await _paymentMethodsBox.clear();
    await _incomeSourcesBox.clear();
    await _incomeTransactionsBox.clear();
    await _expensesBox.clear();
    await _expenseCategoriesBox.clear();
    await _incomeCategoriesBox.clear();
    await _merchantsBox.clear();
    await _budgetsBox.clear();
    await _goalsBox.clear();
    await _recurringTransactionsBox.clear();
    // Note: Settings are NOT cleared - user preferences are preserved
  }

  /// Get total income for a month
  double getTotalIncomeForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getIncomeSourcesInRange(start, end)
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  /// Get total expenses for a month
  double getTotalExpensesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getExpensesInRange(start, end)
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}
