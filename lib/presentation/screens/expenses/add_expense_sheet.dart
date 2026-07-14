import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/ad_service.dart';
import '../../../data/models/bank_account.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/receipt.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../../services/receipt_scanner_service.dart';
import '../../providers/storage_providers.dart';
import '../../widgets/common/auto_scroll_text.dart';
import '../../widgets/common/bottom_sheet_handle.dart';
import '../settings/add_bank_account_sheet.dart';
import '../settings/add_payment_method_sheet.dart';
import '../settings/merchants_screen.dart';
import 'receipt_scanner_sheet.dart';

/// Available icons for custom categories with their colors
const List<({IconData icon, Color color})> customExpenseCategoryOptions = [
  (icon: LucideIcons.star, color: Color(0xFFF5A524)),
  (icon: LucideIcons.tag, color: Color(0xFF3CCF91)),
  (icon: LucideIcons.folder, color: Color(0xFF5B7CFA)),
  (icon: LucideIcons.box, color: Color(0xFFEC4899)),
  (icon: LucideIcons.briefcase, color: Color(0xFF8B5CF6)),
  (icon: LucideIcons.coins, color: Color(0xFF14B8A6)),
];

/// Add/Edit Expense Bottom Sheet
class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? existingExpense;
  final Receipt? scannedReceipt;

  const AddExpenseSheet({super.key, this.existingExpense, this.scannedReceipt});

  bool get isEditing => existingExpense != null;

  static Future<void> show(BuildContext context, {Expense? existingExpense, Receipt? scannedReceipt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(existingExpense: existingExpense, scannedReceipt: scannedReceipt),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _customCategoryController = TextEditingController();

  ExpenseCategory? _selectedCategory;
  bool _isOtherCategory = false;
  int _selectedCustomIconIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  RecurringFrequency _recurringFrequency = RecurringFrequency.monthly;
  String? _selectedPaymentMethodId;
  String? _selectedBankAccountId;

  // Receipt scanning
  Receipt? _scannedReceipt;
  File? _receiptImageFile;

  /// Check if the selected payment method requires a bank account
  bool _requiresBankAccount(List<PaymentMethod> methods) {
    if (_selectedPaymentMethodId == null) return false;
    try {
      final method = methods.firstWhere((m) => m.id == _selectedPaymentMethodId);
      // Cash, wallet and cheque don't require bank account
      return method.type != PaymentMethodType.cash &&
          method.type != PaymentMethodType.wallet &&
          method.type != PaymentMethodType.cheque;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate fields if editing
    if (widget.existingExpense != null) {
      final expense = widget.existingExpense!;
      _nameController.text = expense.name;
      _amountController.text = expense.amount.toStringAsFixed(0);
      _descriptionController.text = expense.description ?? '';
      _merchantController.text = expense.merchantName ?? '';
      _selectedDate = expense.date;
      _isRecurring = expense.isRecurring;
      _recurringFrequency = expense.recurringFrequency ?? RecurringFrequency.monthly;
      _selectedPaymentMethodId = expense.paymentMethodId;
      _selectedBankAccountId = expense.bankAccountId;

      // Load receipt data from existing expense
      if (expense.receiptImagePath != null && expense.receiptImagePath!.isNotEmpty) {
        _receiptImageFile = File(expense.receiptImagePath!);
        // Try to parse receipt items from JSON
        if (expense.receiptItemsJson != null && expense.receiptItemsJson!.isNotEmpty) {
          try {
            final items = Receipt.itemsFromJsonString(expense.receiptItemsJson!);
            _scannedReceipt = Receipt(
              id: expense.receiptId ?? expense.id,
              localImagePath: expense.receiptImagePath,
              items: items,
              extractedDate: expense.date,
              merchantName: expense.merchantName,
              createdAt: expense.createdAt,
            );
          } catch (e) {
            debugPrint('Error parsing receipt items: $e');
          }
        }
      }

      // Schedule category lookup after frame to ensure ref is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final customCategories = ref.read(customExpenseCategoriesProvider);
        final category = ExpenseCategories.getByIdWithCustom(expense.categoryId, customCategories);
        setState(() {
          if (category.id == 'other' || category.id.startsWith('custom_')) {
            final customCat = customCategories.where((c) => c.id == expense.categoryId).firstOrNull;
            if (customCat != null) {
              _selectedCategory = customCat;
              _isOtherCategory = false;
            } else {
              _isOtherCategory = true;
              _selectedCategory = null;
            }
          } else {
            _selectedCategory = category;
            _isOtherCategory = false;
          }
        });
      });
    } else {
      // Default category for new expense
      _selectedCategory = ExpenseCategories.foodDining;

      // Pre-fill from scanned receipt if provided
      if (widget.scannedReceipt != null) {
        final receipt = widget.scannedReceipt!;
        _scannedReceipt = receipt;
        if (receipt.localImagePath != null) {
          _receiptImageFile = File(receipt.localImagePath!);
        }

        // Pre-fill form with receipt data
        if (receipt.merchantName != null && receipt.merchantName!.isNotEmpty) {
          _merchantController.text = receipt.merchantName!;
          _nameController.text = receipt.merchantName!;
        } else if (receipt.items.isNotEmpty) {
          _nameController.text = receipt.items.first.name;
        }

        if (receipt.extractedDate != null) {
          _selectedDate = receipt.extractedDate!;
        }

        // Use receipt total as amount
        if (receipt.selectedTotal > 0) {
          _amountController.text = receipt.selectedTotal.toStringAsFixed(0);
        }

        // Set description with item count
        if (receipt.items.length > 1) {
          final itemCount = receipt.items.where((i) => i.isSelected).length;
          _descriptionController.text = '$itemCount items from receipt';
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      final paymentMethods = ref.read(paymentMethodsProvider);

      // Check if payment method is selected
      if (_selectedPaymentMethodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseSelectPaymentMethod ?? 'Please select a payment method'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Check if bank account is required but not selected
      if (_requiresBankAccount(paymentMethods) && _selectedBankAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseSelectBankAccount ?? 'Please select a bank account for this payment method'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Check if merchant is selected (only if mandatory)
      final isMerchantMandatory = ref.read(merchantMandatoryProvider);
      if (isMerchantMandatory && _merchantController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseEnterMerchantName ?? 'Please select a merchant'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Get category ID - create custom category if needed
      String categoryId;
      final now = DateTime.now();

      if (_isOtherCategory && _customCategoryController.text.trim().isNotEmpty) {
        // Create a custom category and save it
        final customCategoryName = _customCategoryController.text.trim();
        final customCategoryId = 'custom_${const Uuid().v4()}';
        final selectedOption = customExpenseCategoryOptions[_selectedCustomIconIndex];

        final customCategory = ExpenseCategory(
          id: customCategoryId,
          name: customCategoryName,
          icon: selectedOption.icon,
          color: selectedOption.color,
          isSystem: false,
          sortOrder: 100,
          createdAt: now,
        );

        // Save the custom category
        await ref.read(customExpenseCategoriesProvider.notifier).addCategory(customCategory);
        categoryId = customCategoryId;
      } else {
        categoryId = _selectedCategory!.id;
      }

      // Save receipt image if present (for new expenses)
      String? savedReceiptPath;
      String? receiptItemsJson;
      final expenseId = widget.existingExpense?.id ?? const Uuid().v4();

      if (_scannedReceipt != null && _receiptImageFile != null) {
        try {
          savedReceiptPath = await ReceiptScannerService.instance.saveReceiptImage(
            _receiptImageFile!,
            expenseId,
          );
          receiptItemsJson = _scannedReceipt!.itemsToJsonString();
        } catch (e) {
          debugPrint('Error saving receipt: $e');
        }
      }

      final expense = Expense(
        id: expenseId,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        currencyCode: CurrencyFormatter.currentCurrencyCode,
        categoryId: categoryId,
        date: _selectedDate,
        paymentMethodId: _selectedPaymentMethodId!,
        bankAccountId: _selectedBankAccountId,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        merchantName: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
        receiptImagePath: savedReceiptPath ?? widget.existingExpense?.receiptImagePath,
        receiptItemsJson: receiptItemsJson ?? widget.existingExpense?.receiptItemsJson,
        isRecurring: _isRecurring,
        recurringFrequency: _isRecurring ? _recurringFrequency : null,
        createdAt: widget.existingExpense?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existingExpense != null) {
        await ref.read(expensesProvider.notifier).updateExpense(expense);

        // Handle recurring transaction for edited expense
        final wasRecurring = widget.existingExpense!.isRecurring;
        if (_isRecurring && !wasRecurring) {
          // Expense is now recurring but wasn't before - create new recurring transaction
          final recurrenceFreq = switch (_recurringFrequency) {
            RecurringFrequency.daily => RecurrenceFrequency.daily,
            RecurringFrequency.weekly => RecurrenceFrequency.weekly,
            RecurringFrequency.monthly => RecurrenceFrequency.monthly,
            RecurringFrequency.quarterly => RecurrenceFrequency.quarterly,
            RecurringFrequency.yearly => RecurrenceFrequency.yearly,
          };

          final recurringTransaction = RecurringTransaction(
            id: 'recurring_${const Uuid().v4()}',
            type: RecurringType.expense,
            name: _nameController.text.trim(), // Use expense name, not merchant
            amount: double.parse(_amountController.text),
            categoryId: categoryId,
            paymentMethodId: _selectedPaymentMethodId,
            bankAccountId: _selectedBankAccountId,
            merchantName: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            frequency: recurrenceFreq,
            nextDueDate: recurrenceFreq.getNextDueDate(_selectedDate),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await ref.read(recurringTransactionsProvider.notifier).addRecurring(recurringTransaction);
        } else if (wasRecurring && !_isRecurring) {
          // Expense was recurring but now is not - find and delete matching recurring transaction
          final recurringTransactions = ref.read(recurringTransactionsProvider);
          final originalName = widget.existingExpense!.name;
          final originalMerchant = widget.existingExpense!.merchantName;
          final originalCategory = widget.existingExpense!.categoryId;

          // Find matching recurring transaction by type, name/merchant, and category
          final matchingRecurring = recurringTransactions.where((rt) =>
              rt.type == RecurringType.expense &&
              rt.categoryId == originalCategory &&
              (rt.name == originalName || rt.name == originalMerchant || rt.merchantName == originalMerchant)
          ).toList();

          // Delete the first matching one (most likely the correct one)
          if (matchingRecurring.isNotEmpty) {
            await ref.read(recurringTransactionsProvider.notifier).deleteRecurring(matchingRecurring.first.id);
          }
        }
      } else {
        await ref.read(expensesProvider.notifier).addExpense(expense);

        // Check budget and send notification if threshold crossed
        await _checkBudgetAndNotify(expense, ref);

        // Also create a RecurringTransaction if recurring is enabled
        if (_isRecurring) {
          // Map RecurringFrequency to RecurrenceFrequency
          final recurrenceFreq = switch (_recurringFrequency) {
            RecurringFrequency.daily => RecurrenceFrequency.daily,
            RecurringFrequency.weekly => RecurrenceFrequency.weekly,
            RecurringFrequency.monthly => RecurrenceFrequency.monthly,
            RecurringFrequency.quarterly => RecurrenceFrequency.quarterly,
            RecurringFrequency.yearly => RecurrenceFrequency.yearly,
          };

          final recurringTransaction = RecurringTransaction(
            id: 'recurring_${const Uuid().v4()}',
            type: RecurringType.expense,
            name: _nameController.text.trim(), // Use expense name, not merchant
            amount: double.parse(_amountController.text),
            categoryId: categoryId,
            paymentMethodId: _selectedPaymentMethodId,
            bankAccountId: _selectedBankAccountId,
            merchantName: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            frequency: recurrenceFreq,
            nextDueDate: recurrenceFreq.getNextDueDate(_selectedDate),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await ref.read(recurringTransactionsProvider.notifier).addRecurring(recurringTransaction);
        }
      }

      // Save merchant for future use (if custom)
      final merchantName = _merchantController.text.trim();
      if (merchantName.isNotEmpty) {
        await ref.read(merchantsProvider.notifier).addMerchant(merchantName);
      }

      if (mounted) {
        Navigator.pop(context);
        // Show interstitial ad (for free users, once every N actions)
        AdService.instance.showInterstitialIfDue();
        // Determine the success message
        String message;
        if (widget.existingExpense != null) {
          final wasRecurring = widget.existingExpense!.isRecurring;
          final newRecurringCreated = _isRecurring && !wasRecurring;
          final recurringRemoved = wasRecurring && !_isRecurring;
          if (newRecurringCreated) {
            message = 'Expense updated & recurring transaction created!';
          } else if (recurringRemoved) {
            message = 'Expense updated & recurring transaction removed!';
          } else {
            message = 'Expense updated!';
          }
        } else {
          message = _isRecurring
              ? 'Expense added & recurring transaction created!'
              : 'Expense added!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  /// Check budget and send notification if threshold crossed
  Future<void> _checkBudgetAndNotify(Expense expense, WidgetRef ref) async {
    try {
      // Get all budgets
      final budgets = ref.read(budgetsProvider);
      final now = DateTime.now();

      // Find budget for this category and month
      final budget = budgets.where(
        (b) => b.categoryId == expense.categoryId &&
               b.month == now.month &&
               b.year == now.year,
      ).firstOrNull;

      if (budget == null) return;

      // Calculate total spent in this category this month
      final expenses = ref.read(expensesProvider);
      final monthlyExpenses = expenses.where(
        (e) => e.categoryId == expense.categoryId &&
               e.date.month == now.month &&
               e.date.year == now.year,
      );
      final totalSpent = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);

      // Get category name
      final categories = ref.read(allExpenseCategoriesProvider);
      final category = categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => categories.first,
      );

      // Check and notify
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

  Future<void> _scanReceipt() async {
    final receipt = await ReceiptScannerSheet.show(context);
    if (receipt != null && mounted) {
      setState(() {
        _scannedReceipt = receipt;
        if (receipt.localImagePath != null) {
          _receiptImageFile = File(receipt.localImagePath!);
        }

        // Pre-fill form with receipt data
        if (receipt.merchantName != null && receipt.merchantName!.isNotEmpty) {
          _merchantController.text = receipt.merchantName!;
        }

        if (receipt.extractedDate != null) {
          _selectedDate = receipt.extractedDate!;
        }

        // Use receipt total as amount
        if (receipt.selectedTotal > 0) {
          _amountController.text = receipt.selectedTotal.toStringAsFixed(0);
        }

        // Set name from merchant or first item
        if (_nameController.text.isEmpty) {
          if (receipt.merchantName != null && receipt.merchantName!.isNotEmpty) {
            _nameController.text = receipt.merchantName!;
          } else if (receipt.items.isNotEmpty) {
            _nameController.text = receipt.items.first.name;
          }
        }

        // Set description with item count
        if (receipt.items.length > 1) {
          final itemCount = receipt.items.where((i) => i.isSelected).length;
          _descriptionController.text = '$itemCount items from receipt';
        }
      });

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.receiptScanned ?? 'Receipt scanned'}! ${receipt.items.where((i) => i.isSelected).length} ${l10n?.items ?? 'items'} added.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _removeReceipt() {
    setState(() {
      _scannedReceipt = null;
      _receiptImageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
          const BottomSheetHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingHorizontal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  widget.existingExpense != null ? (l10n?.editExpense ?? 'Edit Expense') : (l10n?.addExpense ?? 'Add Expense'),
                  style: AppTypography.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    l10n?.save ?? 'Save',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppDimensions.screenPaddingHorizontal,
                right: AppDimensions.screenPaddingHorizontal,
                bottom: bottomPadding + AppDimensions.spacing24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.spacing16),

                    // Receipt Section
                    // For new expenses: Show scan button
                    // For editing: Show existing receipt (read-only) or allow scanning if none exists
                    if (widget.existingExpense == null) ...[
                      _ReceiptScanButton(
                        isDark: isDark,
                        hasReceipt: _scannedReceipt != null,
                        receiptImageFile: _receiptImageFile,
                        itemCount: _scannedReceipt?.items.where((i) => i.isSelected).length ?? 0,
                        onScan: _scanReceipt,
                        onRemove: _removeReceipt,
                      ),
                      const SizedBox(height: AppDimensions.spacing24),
                    ] else if (_scannedReceipt != null || _receiptImageFile != null) ...[
                      // Show read-only receipt preview when editing
                      _ReceiptPreview(
                        isDark: isDark,
                        receiptImageFile: _receiptImageFile,
                        receipt: _scannedReceipt,
                      ),
                      const SizedBox(height: AppDimensions.spacing24),
                    ],

                    // Name (Required)
                    _buildLabel(l10n?.name ?? 'Name', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Grocery Shopping, Netflix, etc.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n?.pleaseEnterName ?? 'Please enter a name for this expense';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Amount (Large, prominent input)
                    _AmountInput(
                      isDark: isDark,
                      amountController: _amountController,
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Category
                    _buildLabel(l10n?.category ?? 'Category', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _CategorySelector(
                      selectedCategory: _selectedCategory,
                      isOtherSelected: _isOtherCategory,
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                          _isOtherCategory = false;
                        });
                      },
                      onOtherSelected: () {
                        setState(() {
                          _selectedCategory = null;
                          _isOtherCategory = true;
                        });
                      },
                      isDark: isDark,
                    ),
                    if (_isOtherCategory) ...[
                      const SizedBox(height: AppDimensions.spacing12),
                      TextFormField(
                        controller: _customCategoryController,
                        decoration: InputDecoration(
                          hintText: l10n?.enterCategoryName ?? 'Enter custom category name',
                        ),
                        validator: (value) {
                          if (_isOtherCategory && (value == null || value.isEmpty)) {
                            return l10n?.pleaseEnterCustomCategory ?? 'Please enter a category name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacing12),
                      // Icon picker
                      Text(
                        l10n?.chooseIcon ?? 'Choose Icon',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: customExpenseCategoryOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = _selectedCustomIconIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCustomIconIndex = index),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option.color.withValues(alpha: 0.2)
                                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                border: Border.all(
                                  color: isSelected
                                      ? option.color
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                option.icon,
                                color: option.color,
                                size: 20,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spacing24),

                    // Date
                    _buildLabel(l10n?.date ?? 'Date', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _QuickDateSelector(
                      selectedDate: _selectedDate,
                      onChanged: (date) {
                        setState(() => _selectedDate = date);
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Payment Method
                    _buildLabel(l10n?.paymentMethod ?? 'Payment Method', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _PaymentMethodSelector(
                      isDark: isDark,
                      paymentMethods: ref.watch(paymentMethodsProvider),
                      selectedId: _selectedPaymentMethodId,
                      onChanged: (id) {
                        setState(() {
                          _selectedPaymentMethodId = id;
                          // Reset bank account when payment method changes
                          _selectedBankAccountId = null;
                        });
                      },
                      onAddNew: () async {
                        final newMethod = await AddPaymentMethodSheet.show(context);
                        if (newMethod != null) {
                          // Save the new payment method
                          await ref.read(paymentMethodsProvider.notifier).addMethod(newMethod);
                          // Auto-select the newly added method
                          setState(() {
                            _selectedPaymentMethodId = newMethod.id;
                            _selectedBankAccountId = null;
                          });
                        }
                      },
                    ),

                    // Bank Account Selector (for non-cash payment methods)
                    if (_requiresBankAccount(ref.watch(paymentMethodsProvider))) ...[
                      const SizedBox(height: AppDimensions.spacing16),
                      _buildLabel(l10n?.fromBankAccount ?? 'From Bank Account', isRequired: true),
                      const SizedBox(height: AppDimensions.spacing8),
                      _BankAccountSelector(
                        isDark: isDark,
                        bankAccounts: ref.watch(bankAccountsProvider),
                        selectedId: _selectedBankAccountId,
                        onChanged: (id) {
                          setState(() => _selectedBankAccountId = id);
                        },
                        onAddNew: () async {
                          final newAccount = await AddBankAccountSheet.show(context);
                          if (newAccount != null) {
                            await ref.read(bankAccountsProvider.notifier).addAccount(newAccount);
                            setState(() => _selectedBankAccountId = newAccount.id);
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spacing24),

                    // Description
                    _buildLabel(l10n?.descriptionOptional ?? 'Description (Optional)'),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'e.g., "Lunch at Subway"',
                      ),
                      // No validator - description is optional
                    ),

                    const SizedBox(height: AppDimensions.spacing16),

                    // Merchant
                    _buildLabel(l10n?.merchant ?? 'Merchant', isRequired: ref.watch(merchantMandatoryProvider)),
                    const SizedBox(height: AppDimensions.spacing8),
                    _MerchantSelector(
                      selectedMerchant: _merchantController.text,
                      onChanged: (merchant) {
                        setState(() => _merchantController.text = merchant);
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Recurring Toggle
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacing16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.repeat,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: AppDimensions.spacing12),
                                  Text(
                                    l10n?.recurring ?? 'Recurring expense?',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isRecurring,
                                onChanged: (value) {
                                  setState(() => _isRecurring = value);
                                },
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                          if (_isRecurring) ...[
                            const SizedBox(height: AppDimensions.spacing12),
                            const Divider(),
                            const SizedBox(height: AppDimensions.spacing12),
                            Row(
                              children: [
                                Text(
                                  '${l10n?.frequency ?? 'Frequency'}:',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spacing12),
                                Expanded(
                                  child: Wrap(
                                    spacing: AppDimensions.spacing8,
                                    runSpacing: AppDimensions.spacing8,
                                    children: RecurringFrequency.values.map((freq) {
                                      final isSelected = freq == _recurringFrequency;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() => _recurringFrequency = freq);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withValues(alpha: 0.2)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.lightBorder),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            freq.label,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark
                                                      ? AppColors.darkTextSecondary
                                                      : AppColors.lightTextSecondary),
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacing32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.existingExpense != null
                            ? (l10n?.update ?? 'Update')
                            : (l10n?.save ?? 'Save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          text,
          style: AppTypography.labelLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
}

/// Category Selector (chip style - matches income)
class _CategorySelector extends ConsumerWidget {
  final ExpenseCategory? selectedCategory;
  final bool isOtherSelected;
  final ValueChanged<ExpenseCategory> onChanged;
  final VoidCallback onOtherSelected;
  final bool isDark;

  const _CategorySelector({
    required this.selectedCategory,
    required this.isOtherSelected,
    required this.onChanged,
    required this.onOtherSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Filter out the system "other" since we have our own custom "Other" option
    final systemCategories = ExpenseCategories.all.where((c) => c.id != 'other').toList();
    final customCategories = ref.watch(customExpenseCategoriesProvider);

    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        // System categories
        ...systemCategories.map((category) {
          final isSelected = selectedCategory != null &&
              category.id == selectedCategory!.id && !isOtherSelected;
          return GestureDetector(
            onTap: () => onChanged(category),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected
                        ? category.color
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? category.color
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Custom categories (user-created)
        ...customCategories.map((category) {
          final isSelected = selectedCategory != null &&
              category.id == selectedCategory!.id && !isOtherSelected;
          return GestureDetector(
            onTap: () => onChanged(category),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected
                        ? category.color
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? category.color
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Other option (for creating new custom categories)
        GestureDetector(
          onTap: onOtherSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
            decoration: BoxDecoration(
              color: isOtherSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color: isOtherSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: isOtherSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.other ?? 'Other',
                  style: AppTypography.labelMedium.copyWith(
                    color: isOtherSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick Date Selector
class _QuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final bool isDark;

  const _QuickDateSelector({
    required this.selectedDate,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    final isToday = _isSameDay(selectedDate, now);
    final isYesterday = _isSameDay(selectedDate, yesterdayDate);

    return Row(
      children: [
        _QuickDateChip(
          label: l10n?.today ?? 'Today',
          isSelected: isToday,
          // When "Today" is tapped, use current time
          onTap: () => onChanged(DateTime.now()),
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        _QuickDateChip(
          label: l10n?.yesterday ?? 'Yesterday',
          isSelected: isYesterday,
          // For yesterday, use noon as default time (more reasonable than midnight)
          onTap: () {
            final yesterday = DateTime.now().subtract(const Duration(days: 1));
            onChanged(DateTime(yesterday.year, yesterday.month, yesterday.day, 12, 0));
          },
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                // If user picked today, use current time
                // Otherwise, use noon as a reasonable default
                final currentNow = DateTime.now();
                if (_isSameDay(date, currentNow)) {
                  onChanged(currentNow);
                } else {
                  onChanged(DateTime(date.year, date.month, date.day, 12, 0));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing12,
              ),
              decoration: BoxDecoration(
                color: (!isToday && !isYesterday)
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: (!isToday && !isYesterday)
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: (!isToday && !isYesterday)
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (!isToday && !isYesterday)
                        ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}'
                        : (l10n?.pickDate ?? 'Pick Date'),
                    style: AppTypography.labelMedium.copyWith(
                      color: (!isToday && !isYesterday)
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickDateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

/// Payment Method Selector (chip style - matches income)
class _PaymentMethodSelector extends StatelessWidget {
  final bool isDark;
  final List<PaymentMethod> paymentMethods;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final Future<void> Function() onAddNew;

  const _PaymentMethodSelector({
    required this.isDark,
    required this.paymentMethods,
    required this.selectedId,
    required this.onChanged,
    required this.onAddNew,
  });

  PaymentMethod? get selectedMethod {
    if (selectedId == null) return null;
    try {
      return paymentMethods.firstWhere((m) => m.id == selectedId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (paymentMethods.isEmpty) {
      // No payment methods configured
      return GestureDetector(
        onTap: onAddNew,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.plus,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  l10n?.addPaymentMethod ?? 'Add a payment method',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show payment methods as chips
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        ...paymentMethods.map((method) {
          final isSelected = method.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(method.id),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    method.icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    method.displayName,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Add new button
        GestureDetector(
          onTap: onAddNew,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
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
                Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.addNew ?? 'Add New',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bank Account Selector (chip style)
class _BankAccountSelector extends StatelessWidget {
  final bool isDark;
  final List<BankAccount> bankAccounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddNew;

  const _BankAccountSelector({
    required this.isDark,
    required this.bankAccounts,
    required this.selectedId,
    required this.onChanged,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (bankAccounts.isEmpty) {
      // No bank accounts configured
      return GestureDetector(
        onTap: onAddNew,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.noBankAccountsConfigured ?? 'No bank accounts configured',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.tapToAddBankAccount ?? 'Tap to add a bank account',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    // Show bank accounts as chips
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        ...bankAccounts.map((account) {
          final isSelected = account.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(account.id),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? account.color.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: isSelected
                      ? account.color
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: account.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AutoScrollText(
                      text: '${account.bankName} - ${account.accountTypeLabel} - ${account.displayAccountNumber}',
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? account.color
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Add new button
        GestureDetector(
          onTap: onAddNew,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
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
                Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.addBankAccount ?? 'Add Bank',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Merchant Selector (chip style)
class _MerchantSelector extends ConsumerStatefulWidget {
  final String selectedMerchant;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _MerchantSelector({
    required this.selectedMerchant,
    required this.onChanged,
    required this.isDark,
  });

  @override
  ConsumerState<_MerchantSelector> createState() => _MerchantSelectorState();
}

class _MerchantSelectorState extends ConsumerState<_MerchantSelector> {
  static const _popularMerchants = [
    'Swiggy',
    'Zomato',
    'Amazon',
    'Flipkart',
    'BigBasket',
    'Myntra',
    'Uber',
    'Ola',
    'Netflix',
    'Spotify',
  ];

  bool _showCustomInput = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if the selected merchant is not in popular list
    final savedMerchants = ref.read(merchantsProvider);
    final allKnownMerchants = [..._popularMerchants, ...savedMerchants];
    if (!allKnownMerchants.any((m) => m.toLowerCase() == widget.selectedMerchant.toLowerCase()) && widget.selectedMerchant.isNotEmpty) {
      _customController.text = widget.selectedMerchant;
      _showCustomInput = true;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedMerchants = ref.watch(merchantsProvider);
    // Filter out saved merchants that are already in popular list
    final customMerchants = savedMerchants
        .where((m) => !_popularMerchants.any((p) => p.toLowerCase() == m.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            // Popular merchants
            ..._popularMerchants.map((merchant) {
              final isSelected = merchant.toLowerCase() == widget.selectedMerchant.toLowerCase() && !_showCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() => _showCustomInput = false);
                  widget.onChanged(merchant);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing12,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    merchant,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }),
            // User-saved custom merchants
            ...customMerchants.map((merchant) {
              final isSelected = merchant.toLowerCase() == widget.selectedMerchant.toLowerCase() && !_showCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() => _showCustomInput = false);
                  widget.onChanged(merchant);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing12,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    merchant,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }),
            // Other option for adding new merchants
            GestureDetector(
              onTap: () => setState(() => _showCustomInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing12,
                  vertical: AppDimensions.spacing8,
                ),
                decoration: BoxDecoration(
                  color: _showCustomInput
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(
                    color: _showCustomInput
                        ? AppColors.warning
                        : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: _showCustomInput
                          ? AppColors.warning
                          : (widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          l10n?.other ?? 'Other',
                          style: AppTypography.labelMedium.copyWith(
                            color: _showCustomInput
                                ? AppColors.warning
                                : (widget.isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showCustomInput) ...[
          const SizedBox(height: AppDimensions.spacing12),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return TextFormField(
                controller: _customController,
                decoration: InputDecoration(
                  hintText: l10n?.enterMerchantName ?? 'Enter merchant name...',
                ),
                onChanged: (value) {
                  if (value.trim().isNotEmpty) widget.onChanged(value.trim());
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Receipt Scan Button widget
class _ReceiptScanButton extends StatelessWidget {
  final bool isDark;
  final bool hasReceipt;
  final File? receiptImageFile;
  final int itemCount;
  final VoidCallback onScan;
  final VoidCallback onRemove;

  const _ReceiptScanButton({
    required this.isDark,
    required this.hasReceipt,
    required this.receiptImageFile,
    required this.itemCount,
    required this.onScan,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (hasReceipt && receiptImageFile != null) {
      // Show receipt preview with warning
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  child: Image.file(
                    receiptImageFile!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.checkCircle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.receiptScanned ?? 'Receipt attached',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$itemCount ${l10n?.itemsDetected ?? 'items detected'}',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  tooltip: l10n?.delete ?? 'Remove receipt',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          // Warning message
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: Text(
                    'Receipt image and scanned items cannot be edited after saving',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Show scan button
    return GestureDetector(
      onTap: onScan,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                LucideIcons.scanLine,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.scanReceipt ?? 'Scan Receipt',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-extract items and prices',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Receipt Preview Widget (read-only, for edit mode)
class _ReceiptPreview extends StatelessWidget {
  final bool isDark;
  final File? receiptImageFile;
  final Receipt? receipt;

  const _ReceiptPreview({
    required this.isDark,
    this.receiptImageFile,
    this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
              Text(
                l10n?.receiptScanned ?? 'Receipt Attached',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Receipt Image Preview
          if (receiptImageFile != null) ...[
            const SizedBox(height: AppDimensions.spacing16),
            GestureDetector(
              onTap: () => _showFullImage(context, receiptImageFile!.path),
              child: Container(
                height: 120,
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
                    receiptImageFile!,
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
                          Text(
                            l10n?.noData ?? 'Image not found',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n?.tapToViewFullImage ?? 'Tap to view full image',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),
          ],

          // Receipt Items
          if (receipt != null && receipt!.items.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing16),
            const Divider(),
            const SizedBox(height: AppDimensions.spacing12),
            Text(
              '${l10n?.receiptItems ?? 'Scanned Items'} (${receipt!.items.length})',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            ...receipt!.items.take(5).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: Row(
                  children: [
                    Icon(
                      item.isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      size: 16,
                      color: item.isSelected
                          ? AppColors.success
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Text(
                        item.quantity > 1 ? '${item.name} (x${item.quantity})' : item.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          decoration: item.isSelected ? null : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.price),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (receipt!.items.length > 5)
              Text(
                '+${receipt!.items.length - 5} more ${l10n?.items ?? 'items'}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
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

/// Simple Amount Input with currency symbol from settings
class _AmountInput extends StatelessWidget {
  final bool isDark;
  final TextEditingController amountController;

  const _AmountInput({
    required this.isDark,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing20,
        vertical: AppDimensions.spacing24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Currency symbol (read-only, from settings)
              Text(
                CurrencyFormatter.currentSymbol,
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
                  child: TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: AppTypography.h1.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary.withValues(alpha: 0.5)
                            : AppColors.lightTextTertiary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.required ?? 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return l10n?.pleaseEnterValidAmount ?? 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.pleaseEnterAmount ?? 'Enter expense amount',
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
