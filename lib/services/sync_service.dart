import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import '../data/storage/storage_service.dart';
import '../data/models/income.dart';
import '../data/models/expense.dart';
import '../data/models/bank_account.dart';
import '../data/models/payment_method.dart';
import '../data/models/budget.dart';
import '../data/models/goal.dart';
import '../data/models/recurring_transaction.dart';

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync result class
class SyncResult {
  final bool success;
  final String? message;
  final int uploaded;
  final int downloaded;

  SyncResult({
    required this.success,
    this.message,
    this.uploaded = 0,
    this.downloaded = 0,
  });
}

/// Service for syncing data between local storage and Supabase
/// Event emitted when sync state changes
class SyncStateEvent {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final SyncResult? result;

  SyncStateEvent({
    required this.status,
    this.lastSyncTime,
    this.result,
  });
}

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  final SupabaseClient _client = Supabase.instance.client;
  final StorageService _storage = StorageService.instance;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  static const String _lastSyncKeyPrefix = 'last_sync_time_';
  static const String _autoSyncKey = 'auto_sync_enabled';

  bool _autoSyncEnabled = false;
  bool get autoSyncEnabled => _autoSyncEnabled;

  /// Stream controller for sync state changes
  final _syncStateController = StreamController<SyncStateEvent>.broadcast();

  /// Stream of sync state changes - listen to this for UI updates
  Stream<SyncStateEvent> get syncStateStream => _syncStateController.stream;

  /// Notify listeners of sync state change
  void _notifySyncState({SyncResult? result}) {
    _syncStateController.add(SyncStateEvent(
      status: _status,
      lastSyncTime: _lastSyncTime,
      result: result,
    ));
  }

  /// Get user-specific sync key
  String get _userSyncKey => '${_lastSyncKeyPrefix}${userId ?? 'unknown'}';

  /// Initialize sync service and load last sync time for current user
  Future<void> initialize() async {
    await _loadLastSyncTime();
    await _loadAutoSyncPreference();
  }

  /// Load auto-sync preference
  Future<void> _loadAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSyncEnabled = prefs.getBool(_autoSyncKey) ?? false;
  }

  /// Set auto-sync enabled/disabled
  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
    debugPrint('Auto-sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Trigger auto-sync if enabled and authenticated
  /// Call this after any data modification (add/edit/delete transactions)
  Future<void> triggerAutoSync() async {
    if (!_autoSyncEnabled) {
      debugPrint('Auto-sync: Skipped (disabled)');
      return;
    }

    if (!isAuthenticated) {
      debugPrint('Auto-sync: Skipped (not authenticated)');
      return;
    }

    if (_status == SyncStatus.syncing) {
      debugPrint('Auto-sync: Skipped (already syncing)');
      return;
    }

    debugPrint('Auto-sync: Triggering...');
    await syncAll();
  }

  /// Load last sync time for current user
  Future<void> _loadLastSyncTime() async {
    if (userId == null) {
      _lastSyncTime = null;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_userSyncKey);
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncString);
    } else {
      _lastSyncTime = null;
    }
  }

  /// Clear sync state (call on sign out)
  Future<void> clearSyncState() async {
    _lastSyncTime = null;
    _status = SyncStatus.idle;
  }

  /// Clear all local data (call on sign out to prevent data leakage)
  Future<void> clearAllLocalData() async {
    await _clearAllLocalDataForRestore();
    debugPrint('Cleared all local data on sign out');
  }

  /// Called when user changes - handle local data and load user's cloud data
  Future<void> onUserChanged() async {
    if (!isAuthenticated || userId == null) {
      debugPrint('onUserChanged: Not authenticated or no userId');
      return;
    }

    final currentUserId = userId;
    debugPrint('onUserChanged: User changed to: $currentUserId');

    try {
      // Load sync time for this user first to check if they're new or returning
      await _loadLastSyncTime();

      if (_lastSyncTime != null) {
        // Returning user - they have cloud data
        debugPrint('onUserChanged: Returning user, restoring from cloud...');

        // Clear local data from previous session (could be different user or offline data)
        await _clearAllLocalDataForRestore();
        debugPrint('onUserChanged: Cleared local data for returning user');

        // Download their cloud data
        if (isAuthenticated && userId == currentUserId) {
          await _downloadAllUserData();
        } else {
          debugPrint('onUserChanged: User changed or signed out during operation, skipping download');
        }
      } else {
        // New user - they have no cloud data
        // Check if there's local data that should be linked to this account
        final hasLocalData = await _hasLocalData();
        debugPrint('onUserChanged: New user - has local data: $hasLocalData');

        if (hasLocalData) {
          // New user with local data - automatically backup their local data to cloud
          debugPrint('onUserChanged: New user has local data, backing up to cloud...');
          if (isAuthenticated && userId == currentUserId) {
            await _uploadLocalDataToNewAccount();
          }
        } else {
          debugPrint('onUserChanged: New user with no local data - starting fresh');
        }
      }
    } catch (e) {
      debugPrint('onUserChanged: Error during user change handling: $e');
      // Don't rethrow - we don't want to break the sign-in flow
    }
  }

  /// Check if there's any local data
  /// NOTE: income_transactions is DEPRECATED - all income is in income_sources
  Future<bool> _hasLocalData() async {
    final hasIncomeSources = _storage.getIncomeSources().isNotEmpty;
    final hasExpenses = _storage.getExpenses().isNotEmpty;
    final hasBankAccounts = _storage.getBankAccounts().isNotEmpty;
    final hasBudgets = _storage.getBudgets().isNotEmpty;
    final hasGoals = _storage.getGoals().isNotEmpty;
    final hasRecurringTransactions = _storage.getRecurringTransactions().isNotEmpty;

    return hasIncomeSources || hasExpenses ||
           hasBankAccounts || hasBudgets || hasGoals || hasRecurringTransactions;
  }

  /// Upload existing local data to a new account
  /// This links local data created before sign-up to the user's account
  Future<void> _uploadLocalDataToNewAccount() async {
    debugPrint('_uploadLocalDataToNewAccount: Starting...');
    int uploaded = 0;

    try {
      // Upload all local data types
      // NOTE: income_transactions is DEPRECATED - all income is in income_sources
      try { uploaded += await _uploadIncomeSources(); } catch (e) { debugPrint('Error uploading income sources: $e'); }
      try { uploaded += await _uploadExpenses(); } catch (e) { debugPrint('Error uploading expenses: $e'); }
      try { uploaded += await _uploadBankAccounts(); } catch (e) { debugPrint('Error uploading bank accounts: $e'); }
      try { uploaded += await _uploadPaymentMethods(); } catch (e) { debugPrint('Error uploading payment methods: $e'); }
      try { uploaded += await _uploadBudgets(); } catch (e) { debugPrint('Error uploading budgets: $e'); }
      try { uploaded += await _uploadGoals(); } catch (e) { debugPrint('Error uploading goals: $e'); }
      try { uploaded += await _uploadRecurringTransactions(); } catch (e) { debugPrint('Error uploading recurring transactions: $e'); }
      try { uploaded += await _uploadCustomCategories(); } catch (e) { debugPrint('Error uploading custom categories: $e'); }
      try { uploaded += await _uploadMerchants(); } catch (e) { debugPrint('Error uploading merchants: $e'); }

      // Update last sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSyncKey, _lastSyncTime!.toIso8601String());

      debugPrint('_uploadLocalDataToNewAccount: Completed - uploaded $uploaded items');
    } catch (e) {
      debugPrint('_uploadLocalDataToNewAccount: Critical error: $e');
    }
  }

  /// Download all user data from cloud (used on sign in)
  Future<void> _downloadAllUserData() async {
    if (!isAuthenticated || userId == null) {
      debugPrint('_downloadAllUserData: Skipping - not authenticated');
      return;
    }

    debugPrint('_downloadAllUserData: Starting download for user $userId');
    int downloaded = 0;

    try {
      // Download each type with individual error handling so one failure doesn't stop all
      // NOTE: income_transactions is DEPRECATED - all income is in income_sources
      try { downloaded += await _downloadIncomeSources(forRestore: true); } catch (e) { debugPrint('Error downloading income sources: $e'); }
      try { downloaded += await _downloadExpenses(forRestore: true); } catch (e) { debugPrint('Error downloading expenses: $e'); }
      try { downloaded += await _downloadBankAccounts(forRestore: true); } catch (e) { debugPrint('Error downloading bank accounts: $e'); }
      try { downloaded += await _downloadPaymentMethods(forRestore: true); } catch (e) { debugPrint('Error downloading payment methods: $e'); }
      try { downloaded += await _downloadBudgets(forRestore: true); } catch (e) { debugPrint('Error downloading budgets: $e'); }
      try { downloaded += await _downloadGoals(forRestore: true); } catch (e) { debugPrint('Error downloading goals: $e'); }
      try { downloaded += await _downloadRecurringTransactions(forRestore: true); } catch (e) { debugPrint('Error downloading recurring transactions: $e'); }
      try { downloaded += await _downloadCustomCategories(forRestore: true); } catch (e) { debugPrint('Error downloading custom categories: $e'); }
      try { downloaded += await _downloadMerchants(forRestore: true); } catch (e) { debugPrint('Error downloading merchants: $e'); }

      debugPrint('_downloadAllUserData: Completed - downloaded $downloaded items');
    } catch (e) {
      debugPrint('_downloadAllUserData: Critical error: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseService.instance.isAuthenticated;

  /// Get current user ID
  String? get userId => SupabaseService.instance.currentUser?.id;

  /// Perform full sync (upload local changes, download remote changes)
  Future<SyncResult> syncAll() async {
    if (!isAuthenticated || userId == null) {
      return SyncResult(
        success: false,
        message: 'Please sign in to sync your data',
      );
    }

    _status = SyncStatus.syncing;
    int uploaded = 0;
    int downloaded = 0;

    try {
      // Sync Income Sources
      uploaded += await _uploadIncomeSources();
      downloaded += await _downloadIncomeSources();

      // NOTE: income_transactions table is DEPRECATED
      // All income entries are now stored in income_sources table
      // The 3-table architecture is: income_sources, recurring_transactions, expenses

      // Sync Expenses
      uploaded += await _uploadExpenses();
      downloaded += await _downloadExpenses();

      // Sync Bank Accounts
      uploaded += await _uploadBankAccounts();
      downloaded += await _downloadBankAccounts();

      // Sync Payment Methods
      uploaded += await _uploadPaymentMethods();
      downloaded += await _downloadPaymentMethods();

      // Sync Budgets
      uploaded += await _uploadBudgets();
      downloaded += await _downloadBudgets();

      // Sync Goals
      uploaded += await _uploadGoals();
      downloaded += await _downloadGoals();

      // Sync Recurring Transactions
      uploaded += await _uploadRecurringTransactions();
      downloaded += await _downloadRecurringTransactions();

      // Sync Custom Categories
      uploaded += await _uploadCustomCategories();
      downloaded += await _downloadCustomCategories();

      // Sync Merchants
      uploaded += await _uploadMerchants();
      downloaded += await _downloadMerchants();

      // Update last sync time for this user
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSyncKey, _lastSyncTime!.toIso8601String());

      _status = SyncStatus.success;
      final result = SyncResult(
        success: true,
        message: 'Sync complete!',
        uploaded: uploaded,
        downloaded: downloaded,
      );

      // Notify listeners of sync completion
      _notifySyncState(result: result);

      return result;
    } catch (e) {
      debugPrint('Sync error: $e');
      _status = SyncStatus.error;
      final result = SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );

      // Notify listeners of sync error
      _notifySyncState(result: result);

      return result;
    }
  }

  /// Backup all data to cloud (upload only)
  Future<SyncResult> backupToCloud() async {
    if (!isAuthenticated || userId == null) {
      return SyncResult(
        success: false,
        message: 'Please sign in to backup your data',
      );
    }

    _status = SyncStatus.syncing;
    int uploaded = 0;

    try {
      uploaded += await _uploadIncomeSources();
      // income_transactions is DEPRECATED - all income is in income_sources
      uploaded += await _uploadExpenses();
      uploaded += await _uploadBankAccounts();
      uploaded += await _uploadPaymentMethods();
      uploaded += await _uploadBudgets();
      uploaded += await _uploadGoals();
      uploaded += await _uploadRecurringTransactions();
      uploaded += await _uploadCustomCategories();
      uploaded += await _uploadMerchants();

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSyncKey, _lastSyncTime!.toIso8601String());

      _status = SyncStatus.success;
      final result = SyncResult(
        success: true,
        message: 'Backup complete!',
        uploaded: uploaded,
      );

      // Notify listeners of backup completion
      _notifySyncState(result: result);

      return result;
    } catch (e) {
      debugPrint('Backup error: $e');
      _status = SyncStatus.error;
      final result = SyncResult(
        success: false,
        message: 'Backup failed: ${e.toString()}',
      );

      // Notify listeners of backup error
      _notifySyncState(result: result);

      return result;
    }
  }

  /// Restore all data from cloud (clears local data first, then downloads)
  Future<SyncResult> restoreFromCloud() async {
    if (!isAuthenticated || userId == null) {
      return SyncResult(
        success: false,
        message: 'Please sign in to restore your data',
      );
    }

    _status = SyncStatus.syncing;
    int downloaded = 0;

    try {
      // IMPORTANT: Clear all local data first before restoring from cloud
      // This ensures restore REPLACES local data with cloud data
      await _clearAllLocalDataForRestore();

      // Now download all data from cloud (will replace cleared local data)
      downloaded += await _downloadIncomeSources(forRestore: true);
      // income_transactions is DEPRECATED - all income is in income_sources
      downloaded += await _downloadExpenses(forRestore: true);
      downloaded += await _downloadBankAccounts(forRestore: true);
      downloaded += await _downloadPaymentMethods(forRestore: true);
      downloaded += await _downloadBudgets(forRestore: true);
      downloaded += await _downloadGoals(forRestore: true);
      downloaded += await _downloadRecurringTransactions(forRestore: true);
      downloaded += await _downloadCustomCategories(forRestore: true);
      downloaded += await _downloadMerchants(forRestore: true);

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSyncKey, _lastSyncTime!.toIso8601String());

      _status = SyncStatus.success;
      final result = SyncResult(
        success: true,
        message: 'Restore complete! Restored $downloaded items.',
        downloaded: downloaded,
      );

      // Notify listeners of restore completion
      _notifySyncState(result: result);

      return result;
    } catch (e) {
      debugPrint('Restore error: $e');
      _status = SyncStatus.error;
      final result = SyncResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );

      // Notify listeners of restore error
      _notifySyncState(result: result);

      return result;
    }
  }

  /// Clear all local transaction data for restore (keeps settings)
  Future<void> _clearAllLocalDataForRestore() async {
    // Use the optimized method that clears all Hive boxes at once
    // This is faster and ensures complete data removal
    await _storage.clearAllTransactionData();
    debugPrint('Cleared all local data for restore');
  }

  // ===== Income Sources Sync =====

  Future<int> _uploadIncomeSources() async {
    final localSources = _storage.getIncomeSources();
    debugPrint('_uploadIncomeSources: Found ${localSources.length} local sources to upload');
    int count = 0;

    for (final source in localSources) {
      try {
        final data = {
          'id': source.id,
          'user_id': userId,
          'source_name': source.sourceName,
          'amount': source.amount,
          'currency_code': source.currencyCode,
          'category_id': source.categoryId,
          'date': source.date.toIso8601String(),
          'payment_method_id': source.paymentMethodId,
          'bank_account_id': source.bankAccountId,
          'description': source.description,
          'payer_name': source.payerName,
          'notes': source.notes,
          'is_recurring': source.isRecurring,
          'recurring_transaction_id': source.recurringTransactionId,
          'recurring_frequency': source.recurringFrequency?.index,
          'recurring_day_of_month': source.recurringDayOfMonth,
          'created_at': source.createdAt.toIso8601String(),
          'updated_at': source.updatedAt.toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(source.toJson()),
        };

        debugPrint('_uploadIncomeSources: Uploading source ${source.id} - ${source.sourceName} - amount: ${source.amount}');
        await _client.from('income_sources').upsert(data, onConflict: 'id');
        debugPrint('_uploadIncomeSources: Successfully uploaded source ${source.id}');
        count++;
      } catch (e) {
        debugPrint('Error uploading income source ${source.id}: $e');
      }
    }

    debugPrint('_uploadIncomeSources: Completed - uploaded $count sources');
    return count;
  }

  Future<int> _downloadIncomeSources({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('income_sources')
          .select()
          .eq('user_id', userId!)
          .order('updated_at', ascending: false);

      int count = 0;
      for (final row in response) {
        try {
          // Try new format first (individual columns), fallback to data column
          IncomeSource source;
          if (row['source_name'] != null) {
            // Parse date with fallback to created_at for old data
            final now = DateTime.now();
            DateTime date;
            if (row['date'] != null) {
              date = DateTime.parse(row['date'] as String);
            } else {
              date = DateTime.parse(row['created_at'] as String? ?? now.toIso8601String());
            }

            // Determine if recurring based on new field or old frequency field
            bool isRecurring = row['is_recurring'] as bool? ?? false;
            RecurringFrequency? recurringFrequency;

            // Handle recurring frequency from new field or legacy frequency field
            if (row['recurring_frequency'] != null) {
              recurringFrequency = RecurringFrequency.values[row['recurring_frequency'] as int];
            } else if (row['frequency'] != null) {
              // Legacy: convert old frequency to recurring frequency
              final frequencyIndex = row['frequency'] as int?;
              if (frequencyIndex != null && frequencyIndex != 0) {
                isRecurring = true;
                // Map old IncomeFrequency to RecurringFrequency
                switch (frequencyIndex) {
                  case 1: recurringFrequency = RecurringFrequency.daily; break;
                  case 2: recurringFrequency = RecurringFrequency.weekly; break;
                  case 3: recurringFrequency = RecurringFrequency.weekly; break;
                  case 4: recurringFrequency = RecurringFrequency.monthly; break;
                  case 5: recurringFrequency = RecurringFrequency.quarterly; break;
                  case 6: recurringFrequency = RecurringFrequency.yearly; break;
                  default: recurringFrequency = RecurringFrequency.monthly; break;
                }
              }
            }

            source = IncomeSource(
              id: row['id'] as String,
              sourceName: row['source_name'] as String,
              amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
              currencyCode: row['currency_code'] as String? ?? 'INR',
              categoryId: row['category_id'] as String? ?? 'other',
              date: date,
              paymentMethodId: row['payment_method_id'] as String?,
              bankAccountId: row['bank_account_id'] as String?,
              description: row['description'] as String?,
              payerName: row['payer_name'] as String?,
              notes: row['notes'] as String?,
              isRecurring: isRecurring,
              recurringTransactionId: row['recurring_transaction_id'] as String?,
              recurringFrequency: recurringFrequency,
              recurringDayOfMonth: row['recurring_day_of_month'] as int?,
              createdAt: DateTime.parse(row['created_at'] as String? ?? now.toIso8601String()),
              updatedAt: DateTime.parse(row['updated_at'] as String? ?? now.toIso8601String()),
            );
          } else {
            // Fallback to data column
            final jsonData = jsonDecode(row['data'] as String);
            source = IncomeSource.fromJson(jsonData);
          }

          // For restore, always save (local is cleared)
          // For sync, only add if not exists locally
          final localSources = _storage.getIncomeSources();
          final exists = localSources.any((s) => s.id == source.id);
          if (forRestore || !exists) {
            await _storage.saveIncomeSource(source);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing income source: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading income sources: $e');
      return 0;
    }
  }

  // ===== Income Transactions Sync =====

  Future<int> _uploadIncomeTransactions() async {
    final localTransactions = _storage.getIncomeTransactions();
    debugPrint('_uploadIncomeTransactions: Found ${localTransactions.length} local transactions to upload');
    int count = 0;

    for (final transaction in localTransactions) {
      try {
        // Use data column for all fields to handle schema mismatches
        // The data column stores JSON which can have any fields
        final data = {
          'id': transaction.id,
          'user_id': userId,
          'recurring_transaction_id': transaction.recurringTransactionId,
          'description': transaction.description,
          'category_id': transaction.categoryId,
          'amount': transaction.amount,
          'date': transaction.date.toIso8601String(),
          'bank_account_id': transaction.bankAccountId,
          'notes': transaction.notes,
          'created_at': transaction.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // Store full data as JSON for backward compatibility and schema flexibility
          'data': jsonEncode({
            ...transaction.toJson(),
            'is_recurring': transaction.isRecurring,
          }),
        };

        debugPrint('_uploadIncomeTransactions: Uploading transaction ${transaction.id} - ${transaction.description} - amount: ${transaction.amount}');
        await _client.from('income_transactions').upsert(data, onConflict: 'id');
        debugPrint('_uploadIncomeTransactions: Successfully uploaded transaction ${transaction.id}');
        count++;
      } catch (e) {
        debugPrint('Error uploading income transaction ${transaction.id}: $e');
      }
    }

    debugPrint('_uploadIncomeTransactions: Completed - uploaded $count transactions');
    return count;
  }

  Future<int> _downloadIncomeTransactions({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('income_transactions')
          .select()
          .eq('user_id', userId!)
          .order('updated_at', ascending: false);

      int count = 0;
      for (final row in response) {
        try {
          // Try new format first (individual columns), fallback to data column
          IncomeTransaction transaction;
          if (row['description'] != null) {
            transaction = IncomeTransaction(
              id: row['id'] as String,
              recurringTransactionId: row['recurring_transaction_id'] as String? ?? row['income_source_id'] as String?,
              description: row['description'] as String,
              categoryId: row['category_id'] as String? ?? 'other',
              amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
              date: DateTime.parse(row['date'] as String),
              bankAccountId: row['bank_account_id'] as String?,
              notes: row['notes'] as String?,
              isRecurring: row['is_recurring'] as bool? ?? false,
              createdAt: DateTime.parse(row['created_at'] as String),
            );
          } else {
            // Fallback to data column
            final jsonData = jsonDecode(row['data'] as String);
            transaction = IncomeTransaction.fromJson(jsonData);
          }

          // For restore, always save (local is cleared)
          // For sync, only add if not exists locally
          final localTransactions = _storage.getIncomeTransactions();
          final exists = localTransactions.any((t) => t.id == transaction.id);
          if (forRestore || !exists) {
            await _storage.saveIncomeTransaction(transaction);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing income transaction: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading income transactions: $e');
      return 0;
    }
  }

  // ===== Expense Sync =====

  Future<int> _uploadExpenses() async {
    final localExpenses = _storage.getExpenses();
    int count = 0;

    for (final expense in localExpenses) {
      try {
        final data = {
          'id': expense.id,
          'user_id': userId,
          'name': expense.name,
          'amount': expense.amount,
          'currency_code': expense.currencyCode,
          'category_id': expense.categoryId,
          'date': expense.date.toIso8601String(),
          'payment_method_id': expense.paymentMethodId,
          'bank_account_id': expense.bankAccountId,
          'description': expense.description,
          'merchant_name': expense.merchantName,
          'receipt_id': expense.receiptId,
          'receipt_image_path': expense.receiptImagePath,
          'receipt_items_json': expense.receiptItemsJson,
          'has_receipt': expense.hasReceipt,
          'is_recurring': expense.isRecurring,
          'recurring_frequency': expense.recurringFrequency?.index,
          'recurring_day_of_month': expense.recurringDayOfMonth,
          'created_at': expense.createdAt.toIso8601String(),
          'updated_at': expense.updatedAt.toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(expense.toJson()),
        };

        await _client.from('expenses').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading expense ${expense.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadExpenses({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('expenses')
          .select()
          .eq('user_id', userId!)
          .order('updated_at', ascending: false);

      int count = 0;
      for (final row in response) {
        try {
          // Try new format first (individual columns), fallback to data column
          Expense expense;
          if (row['name'] != null) {
            expense = Expense(
              id: row['id'] as String,
              name: row['name'] as String,
              amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
              currencyCode: row['currency_code'] as String? ?? 'INR',
              categoryId: row['category_id'] as String? ?? 'other',
              date: DateTime.parse(row['date'] as String),
              paymentMethodId: row['payment_method_id'] as String? ?? 'cash',
              bankAccountId: row['bank_account_id'] as String?,
              description: row['description'] as String?,
              merchantName: row['merchant_name'] as String?,
              receiptId: row['receipt_id'] as String?,
              receiptImagePath: row['receipt_image_path'] as String?,
              receiptItemsJson: row['receipt_items_json'] as String?,
              isRecurring: row['is_recurring'] as bool? ?? false,
              recurringFrequency: row['recurring_frequency'] != null
                  ? RecurringFrequency.values[row['recurring_frequency'] as int]
                  : null,
              recurringDayOfMonth: row['recurring_day_of_month'] as int?,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            );
          } else {
            // Fallback to data column
            final jsonData = jsonDecode(row['data'] as String);
            expense = Expense.fromJson(jsonData);
          }

          final localExpenses = _storage.getExpenses();
          final exists = localExpenses.any((e) => e.id == expense.id);
          if (forRestore || !exists) {
            await _storage.saveExpense(expense);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing expense: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading expenses: $e');
      return 0;
    }
  }

  // ===== Bank Account Sync =====

  Future<int> _uploadBankAccounts() async {
    final localAccounts = _storage.getBankAccounts();
    int count = 0;

    for (final account in localAccounts) {
      try {
        final data = {
          'id': account.id,
          'user_id': userId,
          'bank_name': account.bankName,
          'account_name': account.accountName,
          'account_number': account.accountNumber,
          'ifsc_code': account.ifscCode,
          'account_type': account.accountType.index,
          'custom_account_type_label': account.customAccountTypeLabel,
          'color': account.color.toARGB32(),
          'is_active': account.isActive,
          'created_at': account.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(account.toJson()),
        };

        await _client.from('bank_accounts').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading bank account ${account.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadBankAccounts({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('bank_accounts')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          // Try new format first, fallback to data column
          BankAccount account;
          if (row['bank_name'] != null) {
            account = BankAccount(
              id: row['id'] as String,
              bankName: row['bank_name'] as String,
              accountName: row['account_name'] as String,
              accountNumber: row['account_number'] as String?,
              ifscCode: row['ifsc_code'] as String?,
              accountType: BankAccountType.values[row['account_type'] as int? ?? 0],
              customAccountTypeLabel: row['custom_account_type_label'] as String?,
              color: Color(row['color'] as int? ?? 0xFF6366F1),
              isActive: row['is_active'] as bool? ?? true,
              createdAt: DateTime.parse(row['created_at'] as String),
            );
          } else {
            final jsonData = jsonDecode(row['data'] as String);
            account = BankAccount.fromJson(jsonData);
          }

          final localAccount = _storage.getBankAccount(account.id);
          if (forRestore || localAccount == null) {
            await _storage.saveBankAccount(account);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing bank account: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading bank accounts: $e');
      return 0;
    }
  }

  // ===== Payment Method Sync =====

  Future<int> _uploadPaymentMethods() async {
    final localMethods = _storage.getPaymentMethods();
    int count = 0;

    for (final method in localMethods) {
      try {
        final data = {
          'id': method.id,
          'user_id': userId,
          'type': method.type.index,
          'name': method.name,
          'bank_account_id': method.bankAccountId,
          'last_four_digits': method.lastFourDigits,
          'upi_id': method.upiId,
          'color': method.color.toARGB32(),
          'is_active': method.isActive,
          'created_at': method.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(method.toJson()),
        };

        await _client.from('payment_methods').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading payment method ${method.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadPaymentMethods({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('payment_methods')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          // Try new format first, fallback to data column
          PaymentMethod method;
          if (row['name'] != null && row['type'] != null) {
            method = PaymentMethod(
              id: row['id'] as String,
              type: PaymentMethodType.values[row['type'] as int],
              name: row['name'] as String,
              bankAccountId: row['bank_account_id'] as String?,
              lastFourDigits: row['last_four_digits'] as String?,
              upiId: row['upi_id'] as String?,
              color: Color(row['color'] as int? ?? 0xFF6366F1),
              isActive: row['is_active'] as bool? ?? true,
              createdAt: DateTime.parse(row['created_at'] as String),
            );
          } else {
            final jsonData = jsonDecode(row['data'] as String);
            method = PaymentMethod.fromJson(jsonData);
          }

          final localMethod = _storage.getPaymentMethod(method.id);
          if (forRestore || localMethod == null) {
            await _storage.savePaymentMethod(method);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing payment method: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading payment methods: $e');
      return 0;
    }
  }

  // ===== Budget Sync =====

  Future<int> _uploadBudgets() async {
    final localBudgets = _storage.getBudgets();
    int count = 0;

    for (final budget in localBudgets) {
      try {
        final data = {
          'id': budget.id,
          'user_id': userId,
          'category_id': budget.categoryId,
          'amount': budget.amount,
          'month': budget.month,
          'year': budget.year,
          'created_at': budget.createdAt.toIso8601String(),
          'updated_at': budget.updatedAt.toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(budget.toJson()),
        };

        await _client.from('budgets').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading budget ${budget.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadBudgets({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          // Try new format first, fallback to data column
          CategoryBudget budget;
          if (row['category_id'] != null && row['amount'] != null) {
            budget = CategoryBudget(
              id: row['id'] as String,
              categoryId: row['category_id'] as String,
              amount: (row['amount'] as num).toDouble(),
              month: row['month'] as int,
              year: row['year'] as int,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            );
          } else {
            final jsonData = jsonDecode(row['data'] as String);
            budget = CategoryBudget.fromJson(jsonData);
          }

          final localBudgets = _storage.getBudgets();
          final exists = localBudgets.any((b) => b.id == budget.id);
          if (forRestore || !exists) {
            await _storage.saveBudget(budget);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing budget: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading budgets: $e');
      return 0;
    }
  }

  // ===== Goal Sync =====

  Future<int> _uploadGoals() async {
    final localGoals = _storage.getGoals();
    int count = 0;

    for (final goal in localGoals) {
      try {
        final data = {
          'id': goal.id,
          'user_id': userId,
          'name': goal.name,
          'target_amount': goal.targetAmount,
          'current_amount': goal.currentAmount,
          'target_date': goal.targetDate?.toIso8601String(),
          'color': goal.color.toARGB32(),
          'icon_code': goal.icon.codePoint,
          'milestones_reached': jsonEncode(goal.milestonesReached),
          'is_completed': goal.isCompleted,
          'completed_at': goal.completedAt?.toIso8601String(),
          'created_at': goal.createdAt.toIso8601String(),
          'updated_at': goal.updatedAt.toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(goal.toJson()),
        };

        await _client.from('goals').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading goal ${goal.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadGoals({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('goals')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          // Use data column for complex models (includes milestones list)
          final jsonData = jsonDecode(row['data'] as String);
          final goal = SavingsGoal.fromJson(jsonData);

          final localGoal = _storage.getGoal(goal.id);
          if (forRestore || localGoal == null) {
            await _storage.saveGoal(goal);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing goal: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading goals: $e');
      return 0;
    }
  }

  // ===== Recurring Transaction Sync =====

  Future<int> _uploadRecurringTransactions() async {
    final localRecurring = _storage.getRecurringTransactions();
    int count = 0;

    for (final recurring in localRecurring) {
      try {
        final data = {
          'id': recurring.id,
          'user_id': userId,
          'name': recurring.name,
          'amount': recurring.amount,
          'type': recurring.type.index,
          'category_id': recurring.categoryId,
          'frequency': recurring.frequency.index,
          'payment_method_id': recurring.paymentMethodId,
          'bank_account_id': recurring.bankAccountId,
          'merchant_name': recurring.merchantName,
          'description': recurring.description,
          'next_due_date': recurring.nextDueDate.toIso8601String(),
          'last_processed_date': recurring.lastProcessedDate?.toIso8601String(),
          'is_active': recurring.isActive,
          'created_at': recurring.createdAt.toIso8601String(),
          'updated_at': recurring.updatedAt.toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(recurring.toJson()),
        };

        await _client.from('recurring_transactions').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading recurring ${recurring.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadRecurringTransactions({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('recurring_transactions')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          // For now, use data column for recurring (complex structure)
          final jsonData = jsonDecode(row['data'] as String);
          final recurring = RecurringTransaction.fromJson(jsonData);

          final localRecurring = _storage.getRecurringTransaction(recurring.id);
          if (forRestore || localRecurring == null) {
            await _storage.saveRecurringTransaction(recurring);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing recurring: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading recurring: $e');
      return 0;
    }
  }

  // ===== Custom Category Sync =====

  Future<int> _uploadCustomCategories() async {
    final expenseCategories = _storage.getCustomExpenseCategories();
    final incomeCategories = _storage.getCustomIncomeCategories();
    int count = 0;

    // Upload expense categories
    for (final category in expenseCategories) {
      try {
        final data = {
          'id': category.id,
          'user_id': userId,
          'type': 'expense',
          'name': category.name,
          'icon_code': category.icon.codePoint,
          'color': category.color.toARGB32(),
          'budget_limit': category.budgetLimit,
          'is_active': category.isActive,
          'sort_order': category.sortOrder,
          'created_at': category.createdAt?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(category.toJson()),
        };

        await _client.from('custom_categories').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading expense category ${category.id}: $e');
      }
    }

    // Upload income categories
    for (final category in incomeCategories) {
      try {
        final data = {
          'id': category.id,
          'user_id': userId,
          'type': 'income',
          'name': category.name,
          'icon_code': category.icon.codePoint,
          'color': category.color.toARGB32(),
          'is_active': category.isActive,
          'sort_order': category.sortOrder,
          'created_at': category.createdAt?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          // Keep data column for backward compatibility
          'data': jsonEncode(category.toJson()),
        };

        await _client.from('custom_categories').upsert(data, onConflict: 'id');
        count++;
      } catch (e) {
        debugPrint('Error uploading income category ${category.id}: $e');
      }
    }

    return count;
  }

  Future<int> _downloadCustomCategories({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('custom_categories')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          final type = row['type'] as String;

          // Try new format first, fallback to data column
          if (row['name'] != null) {
            if (type == 'expense') {
              final category = ExpenseCategory(
                id: row['id'] as String,
                name: row['name'] as String,
                icon: IconData(
                  row['icon_code'] as int,
                  fontFamily: 'lucide',
                  fontPackage: 'lucide_icons',
                ),
                color: Color(row['color'] as int),
                budgetLimit: (row['budget_limit'] as num?)?.toDouble(),
                isSystem: false,
                isActive: row['is_active'] as bool? ?? true,
                sortOrder: row['sort_order'] as int? ?? 100,
                createdAt: row['created_at'] != null
                    ? DateTime.parse(row['created_at'] as String)
                    : null,
              );
              final localCategory = _storage.getCustomExpenseCategory(category.id);
              if (forRestore || localCategory == null) {
                await _storage.saveCustomExpenseCategory(category);
                count++;
              }
            } else if (type == 'income') {
              final category = IncomeCategoryModel(
                id: row['id'] as String,
                name: row['name'] as String,
                icon: IconData(
                  row['icon_code'] as int,
                  fontFamily: 'lucide',
                  fontPackage: 'lucide_icons',
                ),
                color: Color(row['color'] as int),
                isSystem: false,
                isActive: row['is_active'] as bool? ?? true,
                sortOrder: row['sort_order'] as int? ?? 100,
                createdAt: row['created_at'] != null
                    ? DateTime.parse(row['created_at'] as String)
                    : null,
              );
              final localCategory = _storage.getCustomIncomeCategory(category.id);
              if (forRestore || localCategory == null) {
                await _storage.saveCustomIncomeCategory(category);
                count++;
              }
            }
          } else {
            // Fallback to data column
            final jsonData = jsonDecode(row['data'] as String);
            if (type == 'expense') {
              final category = ExpenseCategory.fromJson(jsonData);
              final localCategory = _storage.getCustomExpenseCategory(category.id);
              if (forRestore || localCategory == null) {
                await _storage.saveCustomExpenseCategory(category);
                count++;
              }
            } else if (type == 'income') {
              final category = IncomeCategoryModel.fromJson(jsonData);
              final localCategory = _storage.getCustomIncomeCategory(category.id);
              if (forRestore || localCategory == null) {
                await _storage.saveCustomIncomeCategory(category);
                count++;
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing category: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading categories: $e');
      return 0;
    }
  }

  // ===== Merchant Sync =====

  Future<int> _uploadMerchants() async {
    final localMerchants = _storage.getMerchants();
    int count = 0;

    for (final merchant in localMerchants) {
      try {
        final data = {
          'id': merchant.toLowerCase(),
          'user_id': userId,
          'name': merchant,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _client.from('merchants').upsert(data, onConflict: 'id,user_id');
        count++;
      } catch (e) {
        debugPrint('Error uploading merchant $merchant: $e');
      }
    }

    return count;
  }

  Future<int> _downloadMerchants({bool forRestore = false}) async {
    try {
      final response = await _client
          .from('merchants')
          .select()
          .eq('user_id', userId!);

      int count = 0;
      for (final row in response) {
        try {
          final merchant = row['name'] as String;
          final localMerchants = _storage.getMerchants();
          final exists = localMerchants.any(
            (m) => m.toLowerCase() == merchant.toLowerCase(),
          );
          if (forRestore || !exists) {
            await _storage.saveMerchant(merchant);
            count++;
          }
        } catch (e) {
          debugPrint('Error parsing merchant: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error downloading merchants: $e');
      return 0;
    }
  }

  /// Delete all cloud data for current user
  Future<bool> deleteCloudData() async {
    if (!isAuthenticated || userId == null) return false;

    try {
      // Delete all user data from cloud tables
      // NOTE: income_transactions table was deprecated - all income data is now in income_sources
      await _client.from('income_sources').delete().eq('user_id', userId!);
      await _client.from('expenses').delete().eq('user_id', userId!);
      await _client.from('bank_accounts').delete().eq('user_id', userId!);
      await _client.from('payment_methods').delete().eq('user_id', userId!);
      await _client.from('budgets').delete().eq('user_id', userId!);
      await _client.from('goals').delete().eq('user_id', userId!);
      await _client.from('recurring_transactions').delete().eq('user_id', userId!);
      await _client.from('custom_categories').delete().eq('user_id', userId!);
      await _client.from('merchants').delete().eq('user_id', userId!);
      return true;
    } catch (e) {
      debugPrint('Error deleting cloud data: $e');
      return false;
    }
  }
}
