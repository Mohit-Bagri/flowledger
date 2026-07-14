import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/bank_account.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/income.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../data/models/payment_method.dart';
import '../../providers/storage_providers.dart';
import '../../widgets/common/auto_scroll_text.dart';
import '../../widgets/common/bottom_sheet_handle.dart';
import 'add_bank_account_sheet.dart';
import 'add_payment_method_sheet.dart';

/// Available icons for custom expense categories with their colors
const List<({IconData icon, Color color})> customExpenseCategoryOptions = [
  (icon: LucideIcons.star, color: Color(0xFFF5A524)),
  (icon: LucideIcons.tag, color: Color(0xFF3CCF91)),
  (icon: LucideIcons.folder, color: Color(0xFF5B7CFA)),
  (icon: LucideIcons.box, color: Color(0xFFEC4899)),
  (icon: LucideIcons.briefcase, color: Color(0xFF8B5CF6)),
  (icon: LucideIcons.coins, color: Color(0xFF14B8A6)),
];

/// Available icons for custom income categories with their colors
const List<({IconData icon, Color color})> customIncomeCategoryOptions = [
  (icon: LucideIcons.star, color: Color(0xFF3CCF91)),
  (icon: LucideIcons.gift, color: Color(0xFFF5A524)),
  (icon: LucideIcons.wallet, color: Color(0xFF5B7CFA)),
  (icon: LucideIcons.piggyBank, color: Color(0xFFEC4899)),
  (icon: LucideIcons.banknote, color: Color(0xFF8B5CF6)),
  (icon: LucideIcons.coins, color: Color(0xFF14B8A6)),
];

/// Add/Edit Recurring Transaction Bottom Sheet
class AddRecurringSheet extends ConsumerStatefulWidget {
  final RecurringTransaction? existingRecurring;

  const AddRecurringSheet({super.key, this.existingRecurring});

  bool get isEditing => existingRecurring != null;

  static Future<void> show(BuildContext context, {RecurringTransaction? existingRecurring}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRecurringSheet(existingRecurring: existingRecurring),
    );
  }

  @override
  ConsumerState<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _customCategoryController = TextEditingController();

  RecurringType _selectedType = RecurringType.expense;
  String? _selectedCategoryId;
  bool _isOtherCategory = false;
  int _selectedCustomIconIndex = 0;
  RecurrenceFrequency _selectedFrequency = RecurrenceFrequency.monthly;
  DateTime _nextDueDate = DateTime.now();
  String? _selectedPaymentMethodId;
  String? _selectedBankAccountId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecurring != null) {
      final recurring = widget.existingRecurring!;
      _nameController.text = recurring.name;
      _amountController.text = recurring.amount.toStringAsFixed(0);
      _descriptionController.text = recurring.description ?? '';
      _merchantController.text = recurring.merchantName ?? '';
      _selectedType = recurring.type;
      _selectedCategoryId = recurring.categoryId;
      _selectedFrequency = recurring.frequency;
      _nextDueDate = recurring.nextDueDate;
      _selectedPaymentMethodId = recurring.paymentMethodId;
      _selectedBankAccountId = recurring.bankAccountId;
      _isActive = recurring.isActive;
    } else {
      // Default category based on type
      _selectedCategoryId = ExpenseCategories.billsUtilities.id;
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

  void _onTypeChanged(RecurringType type) {
    setState(() {
      _selectedType = type;
      _isOtherCategory = false;
      _selectedCustomIconIndex = 0;
      _customCategoryController.clear();
      // Reset category when type changes (keep payment method and bank account)
      if (type == RecurringType.income) {
        _selectedCategoryId = IncomeCategories.salary.id;
        _merchantController.clear();
      } else {
        _selectedCategoryId = ExpenseCategories.billsUtilities.id;
      }
    });
  }

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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      final paymentMethods = ref.read(paymentMethodsProvider);

      // Validate payment method (required for both income and expense)
      if (_selectedPaymentMethodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseSelectPaymentMethod ?? 'Please select a payment method'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate bank account if required (for both income and expense)
      if (_requiresBankAccount(paymentMethods) && _selectedBankAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseSelectBankAccount ?? 'Please select a bank account for this payment method'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate merchant for expenses (required)
      if (_selectedType == RecurringType.expense && _merchantController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseEnterMerchantName ?? 'Please enter a merchant name'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate category
      if (_selectedCategoryId == null && !_isOtherCategory) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseSelectCategory ?? 'Please select a category'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate custom category name
      if (_isOtherCategory && _customCategoryController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseEnterCustomCategory ?? 'Please enter a custom category name'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      String categoryId = _selectedCategoryId ?? '';

      // Create custom category if needed
      if (_isOtherCategory) {
        final customName = _customCategoryController.text.trim();
        categoryId = 'custom_${customName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

        if (_selectedType == RecurringType.expense) {
          final selectedOption = customExpenseCategoryOptions[_selectedCustomIconIndex];
          final customCategory = ExpenseCategory(
            id: categoryId,
            name: customName,
            icon: selectedOption.icon,
            color: selectedOption.color,
            isSystem: false,
            createdAt: DateTime.now(),
          );
          await ref.read(customExpenseCategoriesProvider.notifier).addCategory(customCategory);
        } else {
          final selectedOption = customIncomeCategoryOptions[_selectedCustomIconIndex];
          final customCategory = IncomeCategoryModel(
            id: categoryId,
            name: customName,
            icon: selectedOption.icon,
            color: selectedOption.color,
            isSystem: false,
            createdAt: DateTime.now(),
          );
          await ref.read(customIncomeCategoriesProvider.notifier).addCategory(customCategory);
        }
      }

      final now = DateTime.now();
      final recurring = RecurringTransaction(
        id: widget.existingRecurring?.id ?? 'recurring_${const Uuid().v4()}',
        type: _selectedType,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        categoryId: categoryId,
        paymentMethodId: _selectedPaymentMethodId, // Save for both expense and income
        bankAccountId: _selectedBankAccountId, // Save for both expense and income
        merchantName: _selectedType == RecurringType.expense ? _merchantController.text.trim() : null,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
        frequency: _selectedFrequency,
        nextDueDate: _nextDueDate,
        lastProcessedDate: widget.existingRecurring?.lastProcessedDate,
        isActive: _isActive,
        createdAt: widget.existingRecurring?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existingRecurring != null) {
        await ref.read(recurringTransactionsProvider.notifier).updateRecurring(recurring);
      } else {
        await ref.read(recurringTransactionsProvider.notifier).addRecurring(recurring);
      }

      // Save merchant for future use
      if (_selectedType == RecurringType.expense && _merchantController.text.trim().isNotEmpty) {
        await ref.read(merchantsProvider.notifier).addMerchant(_merchantController.text.trim());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecurring != null
                ? (l10n?.recurringTransactionUpdated ?? 'Recurring transaction updated!')
                : (l10n?.recurringTransactionAdded ?? 'Recurring transaction added!')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context);

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
                  widget.existingRecurring != null
                      ? (l10n?.editRecurring ?? 'Edit Recurring')
                      : (l10n?.addRecurring ?? 'Add Recurring'),
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

                    // Type Toggle (Income/Expense)
                    _buildLabel(l10n?.type ?? 'Type', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _TypeToggle(
                      selectedType: _selectedType,
                      onChanged: _onTypeChanged,
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Name
                    _buildLabel(l10n?.name ?? 'Name', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: _selectedType == RecurringType.income
                            ? (l10n?.recurringNameHintIncome ?? 'e.g., "Monthly Salary"')
                            : (l10n?.recurringNameHintExpense ?? 'e.g., "Netflix Subscription"'),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n?.pleaseEnterName ?? 'Please enter a name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Amount
                    _buildLabel(l10n?.amount ?? 'Amount', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing16,
                        vertical: AppDimensions.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            CurrencyFormatter.selectedCurrency.symbol,
                            style: AppTypography.h3.copyWith(
                              color: _selectedType == RecurringType.income
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacing12),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              style: AppTypography.h3.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: AppTypography.h3.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
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
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Category
                    _buildLabel(l10n?.category ?? 'Category', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    if (_selectedType == RecurringType.income)
                      _IncomeCategorySelector(
                        selectedCategoryId: _selectedCategoryId,
                        isOtherSelected: _isOtherCategory,
                        onChanged: (id) => setState(() {
                          _selectedCategoryId = id;
                          _isOtherCategory = false;
                        }),
                        onOtherSelected: () => setState(() {
                          _selectedCategoryId = null;
                          _isOtherCategory = true;
                        }),
                        isDark: isDark,
                        l10n: l10n,
                      )
                    else
                      _ExpenseCategorySelector(
                        selectedCategoryId: _selectedCategoryId,
                        isOtherSelected: _isOtherCategory,
                        onChanged: (id) => setState(() {
                          _selectedCategoryId = id;
                          _isOtherCategory = false;
                        }),
                        onOtherSelected: () => setState(() {
                          _selectedCategoryId = null;
                          _isOtherCategory = true;
                        }),
                        isDark: isDark,
                        l10n: l10n,
                      ),
                    if (_isOtherCategory) ...[
                      const SizedBox(height: AppDimensions.spacing12),
                      TextFormField(
                        controller: _customCategoryController,
                        decoration: InputDecoration(
                          hintText: l10n?.enterCustomCategoryName ?? 'Enter custom category name...',
                          prefixIcon: Icon(
                            _selectedType == RecurringType.expense
                                ? customExpenseCategoryOptions[_selectedCustomIconIndex].icon
                                : customIncomeCategoryOptions[_selectedCustomIconIndex].icon,
                            color: _selectedType == RecurringType.expense
                                ? customExpenseCategoryOptions[_selectedCustomIconIndex].color
                                : customIncomeCategoryOptions[_selectedCustomIconIndex].color,
                          ),
                        ),
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
                        children: (_selectedType == RecurringType.expense
                                ? customExpenseCategoryOptions
                                : customIncomeCategoryOptions)
                            .asMap()
                            .entries
                            .map((entry) {
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

                    // Frequency
                    _buildLabel(l10n?.frequency ?? 'Frequency', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _FrequencySelector(
                      selectedFrequency: _selectedFrequency,
                      onChanged: (f) => setState(() => _selectedFrequency = f),
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Next Due Date
                    _buildLabel(l10n?.nextDueDate ?? 'Next Due Date', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _DateSelector(
                      selectedDate: _nextDueDate,
                      onChanged: (d) => setState(() => _nextDueDate = d),
                      isDark: isDark,
                      l10n: l10n,
                    ),

                    // Payment Method (for both income and expense)
                    const SizedBox(height: AppDimensions.spacing24),
                    _buildLabel(l10n?.paymentMethod ?? 'Payment Method', isRequired: true),
                    const SizedBox(height: AppDimensions.spacing8),
                    _PaymentMethodSelector(
                      isDark: isDark,
                      paymentMethods: ref.watch(paymentMethodsProvider),
                      selectedId: _selectedPaymentMethodId,
                      onChanged: (id) => setState(() {
                        _selectedPaymentMethodId = id;
                        // Reset bank account when payment method changes
                        _selectedBankAccountId = null;
                      }),
                      onAddNew: () async {
                        final newMethod = await AddPaymentMethodSheet.show(context);
                        if (newMethod != null) {
                          await ref.read(paymentMethodsProvider.notifier).addMethod(newMethod);
                          setState(() {
                            _selectedPaymentMethodId = newMethod.id;
                            _selectedBankAccountId = null;
                          });
                        }
                      },
                      l10n: l10n,
                    ),

                    // Bank Account Selector (for non-cash payment methods)
                    if (_requiresBankAccount(ref.watch(paymentMethodsProvider))) ...[
                      const SizedBox(height: AppDimensions.spacing16),
                      _buildLabel(
                        _selectedType == RecurringType.expense
                            ? (l10n?.fromBankAccount ?? 'From Bank Account')
                            : (l10n?.toBankAccount ?? 'To Bank Account'),
                        isRequired: true,
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      _BankAccountSelector(
                        isDark: isDark,
                        bankAccounts: ref.watch(bankAccountsProvider),
                        selectedId: _selectedBankAccountId,
                        onChanged: (id) => setState(() => _selectedBankAccountId = id),
                        onAddNew: () async {
                          final newAccount = await AddBankAccountSheet.show(context);
                          if (newAccount != null) {
                            await ref.read(bankAccountsProvider.notifier).addAccount(newAccount);
                            setState(() => _selectedBankAccountId = newAccount.id);
                          }
                        },
                        l10n: l10n,
                      ),
                    ],

                    // Merchant (only for expenses)
                    if (_selectedType == RecurringType.expense) ...[
                      const SizedBox(height: AppDimensions.spacing24),
                      _buildLabel(l10n?.merchant ?? 'Merchant', isRequired: true),
                      const SizedBox(height: AppDimensions.spacing8),
                      _MerchantSelector(
                        selectedMerchant: _merchantController.text,
                        onChanged: (m) => setState(() => _merchantController.text = m),
                        isDark: isDark,
                        l10n: l10n,
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spacing24),

                    // Description
                    _buildLabel(l10n?.descriptionOptional ?? 'Description (Optional)'),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l10n?.anyAdditionalDetails ?? 'Any additional details...',
                      ),
                    ),

                    // Active Toggle (only when editing)
                    if (widget.existingRecurring != null) ...[
                      const SizedBox(height: AppDimensions.spacing24),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacing16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isActive ? LucideIcons.play : LucideIcons.pause,
                                  size: 20,
                                  color: _isActive ? AppColors.success : AppColors.warning,
                                ),
                                const SizedBox(width: AppDimensions.spacing12),
                                Text(
                                  l10n?.active ?? 'Active',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) => setState(() => _isActive = value),
                              activeColor: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spacing32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(widget.existingRecurring != null
                            ? (l10n?.updateRecurring ?? 'Update Recurring')
                            : (l10n?.saveRecurring ?? 'Save Recurring')),
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

/// Type Toggle (Income/Expense)
class _TypeToggle extends StatelessWidget {
  final RecurringType selectedType;
  final ValueChanged<RecurringType> onChanged;
  final bool isDark;

  const _TypeToggle({
    required this.selectedType,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RecurringType.values.map((type) {
        final isSelected = type == selectedType;
        final color = type == RecurringType.income ? AppColors.success : AppColors.error;
        final icon = type == RecurringType.income ? LucideIcons.trendingUp : LucideIcons.trendingDown;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              margin: EdgeInsets.only(
                right: type == RecurringType.income ? AppDimensions.spacing8 : 0,
                left: type == RecurringType.expense ? AppDimensions.spacing8 : 0,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(width: AppDimensions.spacing8),
                  Text(
                    type.label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Frequency Selector
class _FrequencySelector extends StatelessWidget {
  final RecurrenceFrequency selectedFrequency;
  final ValueChanged<RecurrenceFrequency> onChanged;
  final bool isDark;

  const _FrequencySelector({
    required this.selectedFrequency,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: RecurrenceFrequency.values.map((freq) {
        final isSelected = freq == selectedFrequency;
        return GestureDetector(
          onTap: () => onChanged(freq),
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
            child: Text(
              freq.label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Date Selector
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _DateSelector({
    required this.selectedDate,
    required this.onChanged,
    required this.isDark,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _isSameDay(selectedDate, today);

    return Row(
      children: [
        _QuickDateChip(
          label: l10n?.today ?? 'Today',
          isSelected: isToday,
          onTap: () => onChanged(today),
          isDark: isDark,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                onChanged(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing12,
              ),
              decoration: BoxDecoration(
                color: !isToday
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: !isToday
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
                    color: !isToday
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    !isToday
                        ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                        : (l10n?.pickDate ?? 'Pick Date'),
                    style: AppTypography.labelMedium.copyWith(
                      color: !isToday
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

/// Income Category Selector
class _IncomeCategorySelector extends ConsumerWidget {
  final String? selectedCategoryId;
  final bool isOtherSelected;
  final ValueChanged<String> onChanged;
  final VoidCallback onOtherSelected;
  final bool isDark;
  final AppLocalizations? l10n;

  const _IncomeCategorySelector({
    required this.selectedCategoryId,
    required this.isOtherSelected,
    required this.onChanged,
    required this.onOtherSelected,
    required this.isDark,
    this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter out system "other" since we have custom "Other" option
    final systemCategories = IncomeCategories.all.where((c) => c.id != 'other').toList();
    final customCategories = ref.watch(customIncomeCategoriesProvider);

    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        // System categories
        ...systemCategories.map((category) {
          final isSelected = category.id == selectedCategoryId && !isOtherSelected;
          return GestureDetector(
            onTap: () => onChanged(category.id),
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
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? category.color
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Custom categories
        ...customCategories.map((category) {
          final isSelected = category.id == selectedCategoryId && !isOtherSelected;
          return GestureDetector(
            onTap: () => onChanged(category.id),
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
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? category.color
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Other option for new custom categories
        GestureDetector(
          onTap: onOtherSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
            decoration: BoxDecoration(
              color: isOtherSelected
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color: isOtherSelected
                    ? AppColors.warning
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
                      ? AppColors.warning
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.other ?? 'Other',
                  style: AppTypography.labelMedium.copyWith(
                    color: isOtherSelected
                        ? AppColors.warning
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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

/// Expense Category Selector
class _ExpenseCategorySelector extends ConsumerWidget {
  final String? selectedCategoryId;
  final bool isOtherSelected;
  final ValueChanged<String> onChanged;
  final VoidCallback onOtherSelected;
  final bool isDark;
  final AppLocalizations? l10n;

  const _ExpenseCategorySelector({
    required this.selectedCategoryId,
    required this.isOtherSelected,
    required this.onChanged,
    required this.onOtherSelected,
    required this.isDark,
    this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter out system "other" since we have custom "Other" option
    final systemCategories = ExpenseCategories.all.where((c) => c.id != 'other').toList();
    final customCategories = ref.watch(customExpenseCategoriesProvider);

    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        // System categories
        ...systemCategories.map((category) {
          final isSelected = category.id == selectedCategoryId && !isOtherSelected;
          return GestureDetector(
            onTap: () => onChanged(category.id),
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
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? category.color
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Custom categories
        ...customCategories.map((category) {
          final isSelected = category.id == selectedCategoryId && !isOtherSelected;
          return GestureDetector(
            onTap: () => onChanged(category.id),
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
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? category.color
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Other option for new custom categories
        GestureDetector(
          onTap: onOtherSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing8,
            ),
            decoration: BoxDecoration(
              color: isOtherSelected
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color: isOtherSelected
                    ? AppColors.warning
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
                      ? AppColors.warning
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.other ?? 'Other',
                  style: AppTypography.labelMedium.copyWith(
                    color: isOtherSelected
                        ? AppColors.warning
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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

/// Payment Method Selector
class _PaymentMethodSelector extends StatelessWidget {
  final bool isDark;
  final List<PaymentMethod> paymentMethods;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final Future<void> Function() onAddNew;
  final AppLocalizations? l10n;

  const _PaymentMethodSelector({
    required this.isDark,
    required this.paymentMethods,
    required this.selectedId,
    required this.onChanged,
    required this.onAddNew,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (paymentMethods.isEmpty) {
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
              Icon(LucideIcons.plus, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  l10n?.addPaymentMethodFirst ?? 'Add a payment method',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    method.displayName,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
                Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  l10n?.addNew ?? 'Add New',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bank Account Selector
class _BankAccountSelector extends StatelessWidget {
  final bool isDark;
  final List<BankAccount> bankAccounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddNew;
  final AppLocalizations? l10n;

  const _BankAccountSelector({
    required this.isDark,
    required this.bankAccounts,
    required this.selectedId,
    required this.onChanged,
    required this.onAddNew,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
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

/// Merchant Selector
class _MerchantSelector extends ConsumerStatefulWidget {
  final String selectedMerchant;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _MerchantSelector({
    required this.selectedMerchant,
    required this.onChanged,
    required this.isDark,
    this.l10n,
  });

  @override
  ConsumerState<_MerchantSelector> createState() => _MerchantSelectorState();
}

class _MerchantSelectorState extends ConsumerState<_MerchantSelector> {
  static const _popularMerchants = [
    'Netflix',
    'Spotify',
    'Amazon Prime',
    'Disney+',
    'YouTube Premium',
    'Electricity Bill',
    'Internet Bill',
    'Phone Bill',
  ];

  bool _showCustomInput = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final savedMerchants = ref.read(merchantsProvider);
    final allKnownMerchants = [..._popularMerchants, ...savedMerchants];
    if (!allKnownMerchants.any((m) => m.toLowerCase() == widget.selectedMerchant.toLowerCase()) &&
        widget.selectedMerchant.isNotEmpty) {
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
                          : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }),
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
                          : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }),
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
                          : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.l10n?.other ?? 'Other',
                      style: AppTypography.labelMedium.copyWith(
                        color: _showCustomInput
                            ? AppColors.warning
                            : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showCustomInput) ...[
          const SizedBox(height: AppDimensions.spacing12),
          TextFormField(
            controller: _customController,
            decoration: InputDecoration(
              hintText: widget.l10n?.enterMerchantName ?? 'Enter merchant name...',
            ),
            onChanged: (value) {
              if (value.trim().isNotEmpty) widget.onChanged(value.trim());
            },
          ),
        ],
      ],
    );
  }
}
