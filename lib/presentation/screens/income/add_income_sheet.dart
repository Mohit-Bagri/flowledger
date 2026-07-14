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
import '../../../data/models/expense.dart'; // For RecurringFrequency
import '../../../data/models/income.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../widgets/common/auto_scroll_text.dart';
import '../../widgets/common/bottom_sheet_handle.dart';
import '../settings/add_bank_account_sheet.dart';
import '../settings/add_payment_method_sheet.dart';

/// Available icons for custom categories with their colors
const List<({IconData icon, Color color})> customCategoryOptions = [
  (icon: LucideIcons.star, color: Color(0xFFF5A524)),
  (icon: LucideIcons.tag, color: Color(0xFF3CCF91)),
  (icon: LucideIcons.folder, color: Color(0xFF5B7CFA)),
  (icon: LucideIcons.box, color: Color(0xFFEC4899)),
  (icon: LucideIcons.briefcase, color: Color(0xFF8B5CF6)),
  (icon: LucideIcons.coins, color: Color(0xFF14B8A6)),
];

/// Add/Edit Income Bottom Sheet - Creates IncomeSource records
class AddIncomeSheet extends ConsumerStatefulWidget {
  final IncomeSource? existingSource;

  const AddIncomeSheet({super.key, this.existingSource});

  bool get isEditing => existingSource != null;

  static Future<void> show(BuildContext context, {IncomeSource? existingSource}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddIncomeSheet(existingSource: existingSource),
    );
  }

  @override
  ConsumerState<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends ConsumerState<AddIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController(); // Source name
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _payerNameController = TextEditingController(); // Who paid you
  final _additionalDescriptionController = TextEditingController(); // Extra description

  IncomeCategoryModel? _selectedCategory;
  bool _isOtherCategory = false;
  int _selectedCustomIconIndex = 0;
  bool _isRecurring = false;
  RecurrenceFrequency _recurringFrequency = RecurrenceFrequency.monthly;
  DateTime _incomeDate = DateTime.now();
  String? _selectedBankAccountId;
  String? _selectedPaymentMethodId;
  int? _recurringDayOfMonth;

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
    if (widget.existingSource != null) {
      final transaction = widget.existingSource!;
      _descriptionController.text = transaction.sourceName;
      _amountController.text = transaction.amount.toStringAsFixed(0);
      _notesController.text = transaction.notes ?? '';
      _payerNameController.text = transaction.payerName ?? '';
      _additionalDescriptionController.text = transaction.description ?? '';
      _isRecurring = transaction.isRecurring;
      _incomeDate = transaction.date;
      _selectedBankAccountId = transaction.bankAccountId;
      _selectedPaymentMethodId = transaction.paymentMethodId;
      _recurringDayOfMonth = transaction.recurringDayOfMonth;
      // Restore recurring frequency if available
      if (transaction.recurringFrequency != null) {
        // Map RecurringFrequency to RecurrenceFrequency
        switch (transaction.recurringFrequency!) {
          case RecurringFrequency.daily: _recurringFrequency = RecurrenceFrequency.daily; break;
          case RecurringFrequency.weekly: _recurringFrequency = RecurrenceFrequency.weekly; break;
          case RecurringFrequency.monthly: _recurringFrequency = RecurrenceFrequency.monthly; break;
          case RecurringFrequency.quarterly: _recurringFrequency = RecurrenceFrequency.quarterly; break;
          case RecurringFrequency.yearly: _recurringFrequency = RecurrenceFrequency.yearly; break;
        }
      }
    } else {
      // Default category for new income
      _selectedCategory = IncomeCategories.salary;
    }

    // Schedule category lookup after frame for editing (ref might not be ready in initState)
    if (widget.existingSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final transaction = widget.existingSource!;
        final customCategories = ref.read(customIncomeCategoriesProvider);
        final category = IncomeCategories.getByIdWithCustom(transaction.categoryId, customCategories);
        setState(() {
          if (category.id == 'other' || category.id.startsWith('custom_')) {
            final customCat = customCategories.where((c) => c.id == transaction.categoryId).firstOrNull;
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
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _customCategoryController.dispose();
    _payerNameController.dispose();
    _additionalDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      final paymentMethods = ref.read(paymentMethodsProvider);

      // Validate payment method is selected
      if (_selectedPaymentMethodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.pleaseSelectPaymentMethod ?? 'Please select a payment method')),
        );
        return;
      }

      // Validate bank account if required
      if (_requiresBankAccount(paymentMethods) && _selectedBankAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.pleaseSelectBankAccount ?? 'Please select a bank account')),
        );
        return;
      }

      final now = DateTime.now();
      String categoryId;

      // Handle custom category
      if (_isOtherCategory && _customCategoryController.text.trim().isNotEmpty) {
        final customCategoryName = _customCategoryController.text.trim();
        final customCategoryId = 'custom_income_${const Uuid().v4()}';
        final selectedOption = customCategoryOptions[_selectedCustomIconIndex];

        // Create and save custom category with selected icon and color
        final customCategory = IncomeCategoryModel(
          id: customCategoryId,
          name: customCategoryName,
          icon: selectedOption.icon,
          color: selectedOption.color,
          isSystem: false,
          sortOrder: 100,
          createdAt: now,
        );
        await ref.read(customIncomeCategoriesProvider.notifier).addCategory(customCategory);
        categoryId = customCategoryId;
      } else {
        categoryId = _selectedCategory?.id ?? 'other';
      }

      // Map RecurrenceFrequency to RecurringFrequency for storage
      RecurringFrequency? recurringFreq;
      if (_isRecurring) {
        switch (_recurringFrequency) {
          case RecurrenceFrequency.daily: recurringFreq = RecurringFrequency.daily; break;
          case RecurrenceFrequency.weekly: recurringFreq = RecurringFrequency.weekly; break;
          case RecurrenceFrequency.biweekly: recurringFreq = RecurringFrequency.weekly; break; // bi-weekly -> weekly
          case RecurrenceFrequency.monthly: recurringFreq = RecurringFrequency.monthly; break;
          case RecurrenceFrequency.quarterly: recurringFreq = RecurringFrequency.quarterly; break;
          case RecurrenceFrequency.yearly: recurringFreq = RecurringFrequency.yearly; break;
        }
      }

      // Create the income entry with full details (like Expense)
      final incomeSource = IncomeSource(
        id: widget.existingSource?.id ?? 'income_${const Uuid().v4()}',
        sourceName: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currencyCode: CurrencyFormatter.currentCurrencyCode,
        categoryId: categoryId,
        date: _incomeDate,
        paymentMethodId: _selectedPaymentMethodId,
        bankAccountId: _selectedBankAccountId,
        description: _additionalDescriptionController.text.isEmpty ? null : _additionalDescriptionController.text.trim(),
        payerName: _payerNameController.text.isEmpty ? null : _payerNameController.text.trim(),
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
        isRecurring: _isRecurring,
        recurringTransactionId: widget.existingSource?.recurringTransactionId,
        recurringFrequency: recurringFreq,
        recurringDayOfMonth: _isRecurring ? (_recurringDayOfMonth ?? _incomeDate.day) : null,
        createdAt: widget.existingSource?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existingSource != null) {
        await ref.read(incomeSourcesProvider.notifier).updateSource(incomeSource);

        // Handle recurring transaction for edited income
        final wasRecurring = widget.existingSource!.isRecurring;
        if (_isRecurring && !wasRecurring) {
          // Income is now recurring but wasn't before - create new recurring transaction
          final recurringTransaction = RecurringTransaction(
            id: 'recurring_${const Uuid().v4()}',
            type: RecurringType.income,
            name: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text),
            categoryId: categoryId,
            bankAccountId: _selectedBankAccountId,
            description: _notesController.text.isEmpty ? null : _notesController.text.trim(),
            frequency: _recurringFrequency,
            nextDueDate: _recurringFrequency.getNextDueDate(_incomeDate),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await ref.read(recurringTransactionsProvider.notifier).addRecurring(recurringTransaction);
        } else if (wasRecurring && !_isRecurring) {
          // Income was recurring but now is not - find and delete matching recurring transaction
          final recurringTransactions = ref.read(recurringTransactionsProvider);
          final originalSourceName = widget.existingSource!.sourceName;
          final originalCategory = widget.existingSource!.categoryId;

          // Find matching recurring transaction by type, name, and category
          final matchingRecurring = recurringTransactions.where((rt) =>
              rt.type == RecurringType.income &&
              rt.categoryId == originalCategory &&
              rt.name == originalSourceName
          ).toList();

          // Delete the first matching one (most likely the correct one)
          if (matchingRecurring.isNotEmpty) {
            await ref.read(recurringTransactionsProvider.notifier).deleteRecurring(matchingRecurring.first.id);
          }
        }
      } else {
        await ref.read(incomeSourcesProvider.notifier).addSource(incomeSource);

        // Create a RecurringTransaction if recurring is enabled for new income
        if (_isRecurring) {
          final recurringTransaction = RecurringTransaction(
            id: 'recurring_${const Uuid().v4()}',
            type: RecurringType.income,
            name: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text),
            categoryId: categoryId,
            bankAccountId: _selectedBankAccountId,
            description: _notesController.text.isEmpty ? null : _notesController.text.trim(),
            frequency: _recurringFrequency,
            nextDueDate: _recurringFrequency.getNextDueDate(_incomeDate),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await ref.read(recurringTransactionsProvider.notifier).addRecurring(recurringTransaction);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        // Show interstitial ad (for free users, once every N actions)
        AdService.instance.showInterstitialIfDue();
        // Determine the success message
        String message;
        if (widget.existingSource != null) {
          final wasRecurring = widget.existingSource!.isRecurring;
          final newRecurringCreated = _isRecurring && !wasRecurring;
          final recurringRemoved = wasRecurring && !_isRecurring;
          if (newRecurringCreated) {
            message = l10n?.recurringTransactionAdded ?? 'Income updated & recurring transaction created!';
          } else if (recurringRemoved) {
            message = l10n?.recurringTransactionDeleted ?? 'Income updated & recurring transaction removed!';
          } else {
            message = l10n?.transactionAdded ?? 'Income updated!';
          }
        } else {
          message = _isRecurring
              ? (l10n?.recurringTransactionAdded ?? 'Income added & recurring transaction created!')
              : (l10n?.transactionAdded ?? 'Income added!');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
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
                  widget.existingSource != null ? (l10n?.editIncome ?? 'Edit Income') : (l10n?.addIncome ?? 'Add Income'),
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

                    // Description
                    _buildLabel(l10n?.description ?? 'Description', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: l10n?.recurringNameHintIncome ?? 'e.g., "Salary - January"',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n?.pleaseEnterName ?? 'Please enter a description';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Category
                    _buildLabel(l10n?.category ?? 'Category', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _CategorySelector(
                      selectedCategory: _selectedCategory,
                      isOtherSelected: _isOtherCategory,
                      onChanged: (IncomeCategoryModel category) {
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
                          hintText: l10n?.enterCustomCategoryName ?? 'Enter custom category name',
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
                        l10n?.chooseIconLabel ?? 'Choose Icon',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: customCategoryOptions.asMap().entries.map((entry) {
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

                    // Income Date
                    _buildLabel(l10n?.dateReceived ?? 'Income Date', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _IncomeDateSelector(
                      selectedDate: _incomeDate,
                      onChanged: (date) {
                        setState(() => _incomeDate = date);
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Amount
                    _buildLabel(l10n?.amount ?? 'Amount', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _AmountInput(
                      isDark: isDark,
                      amountController: _amountController,
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
                                    l10n?.recurringIncome ?? 'Recurring income?',
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
                                activeColor: AppColors.success,
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
                                    children: RecurrenceFrequency.values.map((freq) {
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
                                                ? AppColors.success.withValues(alpha: 0.2)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.success
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
                                                  ? AppColors.success
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

                    const SizedBox(height: AppDimensions.spacing24),

                    // Payment Method (Required)
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
                      _buildLabel(l10n?.toBankAccount ?? 'To Bank Account', isRequired: true),
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

                    // Notes
                    _buildLabel('${l10n?.notes ?? 'Notes'} (${l10n?.descriptionOptional ?? 'Optional'})'),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n?.anyAdditionalDetails ?? 'Any additional details...',
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacing32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.existingSource != null
                            ? (l10n?.updateRecurring ?? 'Update Income')
                            : (l10n?.saveRecurring ?? 'Save Income')),
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

/// Category Selector
class _CategorySelector extends ConsumerWidget {
  final IncomeCategoryModel? selectedCategory;
  final bool isOtherSelected;
  final ValueChanged<IncomeCategoryModel> onChanged;
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
    // Filter out the "other" since we have our own custom "Other" option
    final systemCategories = IncomeCategories.all.where((c) => c.id != 'other').toList();
    final customCategories = ref.watch(customIncomeCategoriesProvider);

    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        // System categories
        ...systemCategories.map((category) {
          final isSelected = category.id == selectedCategory?.id && !isOtherSelected;
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
          final isSelected = category.id == selectedCategory?.id && !isOtherSelected;
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
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return GestureDetector(
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
            );
          },
        ),
      ],
    );
  }
}


/// Income Date Selector (allows past dates for forgotten income)
class _IncomeDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final bool isDark;

  const _IncomeDateSelector({
    required this.selectedDate,
    required this.onChanged,
    required this.isDark,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                  l10n?.tapToAddBankAccount ?? 'Add a bank account',
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

    // Show bank accounts as chips
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        // None option
        GestureDetector(
          onTap: () => onChanged(null),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
            decoration: BoxDecoration(
              color: selectedId == null
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color: selectedId == null
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Text(
              l10n?.notAvailable ?? 'None',
              style: AppTypography.labelMedium.copyWith(
                color: selectedId == null
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
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
                  l10n?.addBank ?? 'Add Bank',
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

/// Payment Method Selector (chip style - matches expense sheet)
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
                  l10n?.addPaymentMethodFirst ?? 'Add a payment method',
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

    return Row(
      children: [
        // Currency symbol (read-only, from settings)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Text(
            CurrencyFormatter.currentSymbol,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        // Amount input
        Expanded(
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              hintText: '0',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n?.pleaseEnterAmount ?? 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return l10n?.pleaseEnterValidAmount ?? 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
