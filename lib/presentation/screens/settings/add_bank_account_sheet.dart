import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/bank_account.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/common/bottom_sheet_handle.dart';

class AddBankAccountSheet extends StatefulWidget {
  final BankAccount? account;

  const AddBankAccountSheet({super.key, this.account});

  static Future<BankAccount?> show(BuildContext context, {BankAccount? account}) {
    return showModalBottomSheet<BankAccount>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBankAccountSheet(account: account),
    );
  }

  @override
  State<AddBankAccountSheet> createState() => _AddBankAccountSheetState();
}

class _AddBankAccountSheetState extends State<AddBankAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;

  late String _selectedBank;
  late BankAccountType _selectedType;
  late Color _selectedColor;
  late TextEditingController _customAccountTypeController;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _accountNameController = TextEditingController(
      text: widget.account?.accountName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? '',
    );
    _ifscController = TextEditingController(
      text: widget.account?.ifscCode ?? '',
    );
    _customAccountTypeController = TextEditingController(
      text: widget.account?.customAccountTypeLabel ?? '',
    );
    _selectedBank = widget.account?.bankName ?? Banks.indian.first;
    _selectedType = widget.account?.accountType ?? BankAccountType.savings;
    _selectedColor = widget.account?.color ?? AccountColors.options.first;
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _customAccountTypeController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      // Validate custom account type if 'Other' is selected
      if (_selectedType == BankAccountType.other && _customAccountTypeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.pleaseEnterCustomAccountType ?? 'Please enter a custom account type name')),
        );
        return;
      }

      final account = BankAccount(
        id: widget.account?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        bankName: _selectedBank,
        accountName: _accountNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim().isEmpty
            ? null
            : _ifscController.text.trim().toUpperCase(),
        accountType: _selectedType,
        customAccountTypeLabel: _selectedType == BankAccountType.other
            ? _customAccountTypeController.text.trim()
            : null,
        color: _selectedColor,
        createdAt: widget.account?.createdAt ?? DateTime.now(),
      );
      Navigator.pop(context, account);
    }
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
                  isEditing ? 'Edit Account' : 'Add Bank Account',
                  style: AppTypography.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
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

                    // Privacy Notice
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 18),
                          const SizedBox(width: AppDimensions.spacing8),
                          Expanded(
                            child: Text(
                              'FlowLedger stores data locally on your device only. We do not collect or store any sensitive financial information like full account numbers or passwords.',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // Bank Name Dropdown
                    _buildLabel('Bank Name', isRequired: true, isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    _BankSelector(
                      selectedBank: _selectedBank,
                      onChanged: (bank) {
                        setState(() => _selectedBank = bank);
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // Account Name
                    _buildLabel('Account Name', isRequired: true, isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _accountNameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., "Salary Account", "Savings"',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Account name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // Account Type
                    _buildLabel('Account Type', isRequired: true, isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    _AccountTypeSelector(
                      selectedType: _selectedType,
                      onChanged: (type) {
                        setState(() => _selectedType = type);
                      },
                      isDark: isDark,
                    ),

                    // Custom Account Type Input (when "Other" is selected)
                    if (_selectedType == BankAccountType.other) ...[
                      const SizedBox(height: AppDimensions.spacing16),
                      _buildLabel('Custom Account Type', isRequired: true, isDark: isDark),
                      const SizedBox(height: AppDimensions.spacing8),
                      TextFormField(
                        controller: _customAccountTypeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Trading Account, PPF, etc.',
                        ),
                        validator: (value) {
                          if (_selectedType == BankAccountType.other &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Custom account type is required';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spacing20),

                    // Last 4 digits (required)
                    _buildLabel('Account Number (Last 4 digits)', isRequired: true, isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        hintText: 'e.g., 1234',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last 4 digits are required';
                        }
                        if (value.trim().length != 4) {
                          return 'Please enter exactly 4 digits';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // IFSC Code (optional)
                    _buildLabel('IFSC Code (Optional)', isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    TextFormField(
                      controller: _ifscController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g., HDFC0001234',
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // Color Selector
                    _buildLabel('Color', isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    _ColorSelector(
                      selectedColor: _selectedColor,
                      onChanged: (color) {
                        setState(() => _selectedColor = color);
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(isEditing ? 'Update Account' : 'Add Account'),
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

  Widget _buildLabel(String text, {bool isRequired = false, required bool isDark}) {
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

/// Bank Selector with search
class _BankSelector extends StatelessWidget {
  final String selectedBank;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _BankSelector({
    required this.selectedBank,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBankPicker(context),
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
              LucideIcons.landmark,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Text(
                selectedBank,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 20,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showBankPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankPickerSheet(
        selectedBank: selectedBank,
        onSelected: (bank) {
          onChanged(bank);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  final String selectedBank;
  final ValueChanged<String> onSelected;

  const _BankPickerSheet({
    required this.selectedBank,
    required this.onSelected,
  });

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  final _customBankController = TextEditingController();
  List<String> _filteredBanks = Banks.all;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBanks);
    // Check if current selection is a custom bank
    if (!Banks.all.contains(widget.selectedBank) && widget.selectedBank.isNotEmpty) {
      _customBankController.text = widget.selectedBank;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customBankController.dispose();
    super.dispose();
  }

  void _filterBanks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBanks = Banks.all
          .where((bank) => bank.toLowerCase().contains(query))
          .toList();
    });
  }

  void _submitCustomBank() {
    final customName = _customBankController.text.trim();
    if (customName.isNotEmpty) {
      widget.onSelected(customName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      child: Column(
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingHorizontal,
            ),
            child: Text(
              'Select Bank',
              style: AppTypography.h4.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingHorizontal,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search banks...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),

          // "Other" option with custom input
          if (_showCustomInput)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingHorizontal,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _customBankController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter bank name...',
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.check, color: AppColors.primary),
                        onPressed: _submitCustomBank,
                      ),
                    ),
                    onSubmitted: (_) => _submitCustomBank(),
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  TextButton(
                    onPressed: () => setState(() => _showCustomInput = false),
                    child: Text(
                      'Back to list',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBanks.length + 1, // +1 for "Other" option
                itemBuilder: (context, index) {
                  // "Other" option at the end
                  if (index == _filteredBanks.length) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 20,
                          color: AppColors.warning,
                        ),
                      ),
                      title: Text(
                        'Other (Enter custom name)',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                      onTap: () => setState(() => _showCustomInput = true),
                    );
                  }

                  final bank = _filteredBanks[index];
                  final isSelected = bank == widget.selectedBank;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.landmark,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      bank,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () => widget.onSelected(bank),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Account Type Selector
class _AccountTypeSelector extends StatelessWidget {
  final BankAccountType selectedType;
  final ValueChanged<BankAccountType> onChanged;
  final bool isDark;

  const _AccountTypeSelector({
    required this.selectedType,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: BankAccountType.values.map((type) {
        final isSelected = type == selectedType;
        return GestureDetector(
          onTap: () => onChanged(type),
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
              type.label,
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
      }).toList(),
    );
  }
}

/// Color Selector
class _ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onChanged;
  final bool isDark;

  const _ColorSelector({
    required this.selectedColor,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacing12,
      runSpacing: AppDimensions.spacing12,
      children: AccountColors.options.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    LucideIcons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
