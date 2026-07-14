import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/bank_account.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/common/bottom_sheet_handle.dart';

class AddPaymentMethodSheet extends StatefulWidget {
  final PaymentMethod? method;
  final PaymentMethodType? initialType;

  const AddPaymentMethodSheet({
    super.key,
    this.method,
    this.initialType,
  });

  static Future<PaymentMethod?> show(
    BuildContext context, {
    PaymentMethod? method,
    PaymentMethodType? initialType,
  }) {
    return showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentMethodSheet(
        method: method,
        initialType: initialType,
      ),
    );
  }

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _lastFourDigitsController;
  late final TextEditingController _upiIdController;
  late final TextEditingController _chequeDetailsController;

  late PaymentMethodType _selectedType;
  late Color _selectedColor;

  bool get isEditing => widget.method != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.method?.name ?? '',
    );
    _lastFourDigitsController = TextEditingController(
      text: widget.method?.lastFourDigits ?? '',
    );
    _upiIdController = TextEditingController(
      text: widget.method?.upiId ?? '',
    );
    _chequeDetailsController = TextEditingController();
    _selectedType = widget.method?.type ?? widget.initialType ?? PaymentMethodType.upi;
    _selectedColor = widget.method?.color ?? AccountColors.options.first;

    // Set default name based on type
    if (widget.method == null && widget.initialType != null) {
      _setDefaultNameForType(widget.initialType!);
    }
  }

  void _setDefaultNameForType(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.upi:
        _nameController.text = 'Google Pay';
        break;
      case PaymentMethodType.creditCard:
        _nameController.text = '';
        break;
      case PaymentMethodType.debitCard:
        _nameController.text = '';
        break;
      case PaymentMethodType.cash:
        _nameController.text = 'Cash';
        break;
      case PaymentMethodType.wallet:
        _nameController.text = '';
        break;
      case PaymentMethodType.bankTransfer:
        _nameController.text = '';
        break;
      case PaymentMethodType.cheque:
        _nameController.text = 'Cheque';
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastFourDigitsController.dispose();
    _upiIdController.dispose();
    _chequeDetailsController.dispose();
    super.dispose();
  }

  void _save() {
    // Cash doesn't need validation
    if (_selectedType == PaymentMethodType.cash) {
      final method = PaymentMethod(
        id: widget.method?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: PaymentMethodType.cash,
        name: 'Cash',
        color: AppColors.success,
        createdAt: widget.method?.createdAt ?? DateTime.now(),
      );
      Navigator.pop(context, method);
      return;
    }

    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();

      // Build name with additional details for certain types
      if (_selectedType == PaymentMethodType.cheque && _chequeDetailsController.text.isNotEmpty) {
        name = '$name (${_chequeDetailsController.text.trim()})';
      }

      final method = PaymentMethod(
        id: widget.method?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        name: name,
        lastFourDigits: _selectedType == PaymentMethodType.creditCard ||
                _selectedType == PaymentMethodType.debitCard
            ? _lastFourDigitsController.text.trim()
            : null,
        upiId: _selectedType == PaymentMethodType.upi
            ? (_upiIdController.text.trim().isEmpty
                ? null
                : _upiIdController.text.trim())
            : null,
        color: _selectedColor,
        createdAt: widget.method?.createdAt ?? DateTime.now(),
      );
      Navigator.pop(context, method);
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
                  isEditing
                      ? (l10n?.editPaymentMethod ?? 'Edit Payment Method')
                      : (l10n?.addPaymentMethod ?? 'Add Payment Method'),
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

                    // Privacy Notice
                    _PrivacyNotice(isDark: isDark, l10n: l10n),

                    const SizedBox(height: AppDimensions.spacing20),

                    // Payment Type
                    _buildLabel(l10n?.paymentType ?? 'Payment Type', isRequired: true, isDark: isDark),
                    const SizedBox(height: AppDimensions.spacing8),
                    _PaymentTypeSelector(
                      selectedType: _selectedType,
                      onChanged: (type) {
                        setState(() {
                          _selectedType = type;
                          if (!isEditing) {
                            _setDefaultNameForType(type);
                          }
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppDimensions.spacing20),

                    // Type-specific fields
                    ..._buildTypeSpecificFields(isDark, l10n),

                    // Color Selector (not for cash)
                    if (_selectedType != PaymentMethodType.cash) ...[
                      const SizedBox(height: AppDimensions.spacing20),
                      _buildLabel(l10n?.color ?? 'Color', isDark: isDark),
                      const SizedBox(height: AppDimensions.spacing8),
                      _ColorSelector(
                        selectedColor: _selectedColor,
                        onChanged: (color) {
                          setState(() => _selectedColor = color);
                        },
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spacing32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(isEditing ? (l10n?.updateMethod ?? 'Update Method') : (l10n?.addMethod ?? 'Add Method')),
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

  List<Widget> _buildTypeSpecificFields(bool isDark, AppLocalizations? l10n) {
    switch (_selectedType) {
      case PaymentMethodType.cash:
        // Cash has no additional fields
        return [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.banknote, color: AppColors.success, size: 24),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Text(
                    l10n?.cashPaymentsTracked ?? 'Cash payments will be tracked without any additional details.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];

      case PaymentMethodType.upi:
        return [
          _buildLabel(l10n?.upiApp ?? 'UPI App', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          _UpiAppSelector(
            selectedApp: _nameController.text,
            onChanged: (app) {
              setState(() => _nameController.text = app);
            },
            isDark: isDark,
            l10n: l10n,
          ),
          const SizedBox(height: AppDimensions.spacing20),
          _buildLabel(l10n?.upiIdOptional ?? 'UPI ID (Optional)', isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          TextFormField(
            controller: _upiIdController,
            decoration: const InputDecoration(
              hintText: 'e.g., yourname@okbank',
            ),
          ),
        ];

      case PaymentMethodType.creditCard:
        return [
          _buildLabel(l10n?.cardName ?? 'Card Name', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          _CardNameSelector(
            selectedName: _nameController.text,
            cardType: 'Credit',
            onChanged: (name) {
              setState(() => _nameController.text = name);
            },
            isDark: isDark,
            l10n: l10n,
          ),
          const SizedBox(height: AppDimensions.spacing20),
          _buildLabel(l10n?.lastFourDigits ?? 'Last 4 Digits', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          TextFormField(
            controller: _lastFourDigitsController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'e.g., 1234',
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n?.lastFourDigitsRequired ?? 'Last 4 digits are required';
              }
              if (value.trim().length != 4) {
                return l10n?.enterExactly4Digits ?? 'Please enter exactly 4 digits';
              }
              return null;
            },
          ),
        ];

      case PaymentMethodType.debitCard:
        return [
          _buildLabel(l10n?.cardName ?? 'Card Name', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          _CardNameSelector(
            selectedName: _nameController.text,
            cardType: 'Debit',
            onChanged: (name) {
              setState(() => _nameController.text = name);
            },
            isDark: isDark,
            l10n: l10n,
          ),
          const SizedBox(height: AppDimensions.spacing20),
          _buildLabel(l10n?.lastFourDigits ?? 'Last 4 Digits', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          TextFormField(
            controller: _lastFourDigitsController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'e.g., 1234',
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n?.lastFourDigitsRequired ?? 'Last 4 digits are required';
              }
              if (value.trim().length != 4) {
                return l10n?.enterExactly4Digits ?? 'Please enter exactly 4 digits';
              }
              return null;
            },
          ),
        ];

      case PaymentMethodType.bankTransfer:
        return [
          _buildLabel(l10n?.transferType ?? 'Transfer Type', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          _BankTransferSelector(
            selectedType: _nameController.text,
            onChanged: (type) {
              setState(() => _nameController.text = type);
            },
            isDark: isDark,
            l10n: l10n,
          ),
        ];

      case PaymentMethodType.wallet:
        return [
          _buildLabel(l10n?.walletName ?? 'Wallet Name', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          _WalletSelector(
            selectedWallet: _nameController.text,
            onChanged: (wallet) {
              setState(() => _nameController.text = wallet);
            },
            isDark: isDark,
            l10n: l10n,
          ),
        ];

      case PaymentMethodType.cheque:
        return [
          _buildLabel(l10n?.chequeDetails ?? 'Cheque Details', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          TextFormField(
            controller: _chequeDetailsController,
            decoration: InputDecoration(
              hintText: l10n?.chequeNumberHint ?? 'e.g., Cheque No. 123456',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n?.chequeDetailsRequired ?? 'Cheque details are required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: AppColors.primary, size: 16),
                const SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: Text(
                    l10n?.chequeReferenceInfo ?? 'Enter cheque number or any reference for tracking.',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];

      case PaymentMethodType.other:
        return [
          _buildLabel(l10n?.name ?? 'Name', isRequired: true, isDark: isDark),
          const SizedBox(height: AppDimensions.spacing8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: l10n?.enterPaymentMethodName ?? 'Enter payment method name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n?.nameRequired ?? 'Name is required';
              }
              return null;
            },
          ),
        ];
    }
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

/// Privacy Notice Widget
class _PrivacyNotice extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;

  const _PrivacyNotice({required this.isDark, this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              l10n?.privacyNotice ?? 'FlowLedger stores data locally on your device only. We do not collect or store any sensitive financial information like full card numbers, CVV or bank passwords.',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment Type Selector
class _PaymentTypeSelector extends StatelessWidget {
  final PaymentMethodType selectedType;
  final ValueChanged<PaymentMethodType> onChanged;
  final bool isDark;

  const _PaymentTypeSelector({
    required this.selectedType,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: PaymentMethodType.values.map((type) {
        final isSelected = type == selectedType;
        return GestureDetector(
          onTap: () => onChanged(type),
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
                  type.icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: AppTypography.labelSmall.copyWith(
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
      }).toList(),
    );
  }
}

/// UPI App Selector
class _UpiAppSelector extends StatefulWidget {
  final String selectedApp;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _UpiAppSelector({
    required this.selectedApp,
    required this.onChanged,
    required this.isDark,
    this.l10n,
  });

  @override
  State<_UpiAppSelector> createState() => _UpiAppSelectorState();
}

class _UpiAppSelectorState extends State<_UpiAppSelector> {
  bool _showCustomInput = false;
  final _customAppController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!UpiApps.popular.contains(widget.selectedApp) && widget.selectedApp.isNotEmpty) {
      _customAppController.text = widget.selectedApp;
      _showCustomInput = true;
    }
  }

  @override
  void dispose() {
    _customAppController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            ...UpiApps.popular.map((app) {
              final isSelected = app == widget.selectedApp && !_showCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() => _showCustomInput = false);
                  widget.onChanged(app);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing16,
                    vertical: AppDimensions.spacing12,
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
                    app,
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
            GestureDetector(
              onTap: () => setState(() => _showCustomInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                  vertical: AppDimensions.spacing12,
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
                    Icon(LucideIcons.plus, size: 14, color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(width: 4),
                    Text(widget.l10n?.other ?? 'Other', style: AppTypography.labelMedium.copyWith(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showCustomInput) ...[
          const SizedBox(height: AppDimensions.spacing12),
          TextFormField(
            controller: _customAppController,
            decoration: InputDecoration(hintText: widget.l10n?.enterUpiAppName ?? 'Enter UPI app name...'),
            validator: (value) {
              if (_showCustomInput && (value == null || value.trim().isEmpty)) {
                return widget.l10n?.upiAppNameRequired ?? 'UPI app name is required';
              }
              return null;
            },
            onChanged: (value) {
              if (value.trim().isNotEmpty) widget.onChanged(value.trim());
            },
          ),
        ],
      ],
    );
  }
}

/// Card Name Selector (for Credit/Debit cards)
class _CardNameSelector extends StatefulWidget {
  final String selectedName;
  final String cardType;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _CardNameSelector({
    required this.selectedName,
    required this.cardType,
    required this.onChanged,
    required this.isDark,
    this.l10n,
  });

  @override
  State<_CardNameSelector> createState() => _CardNameSelectorState();
}

class _CardNameSelectorState extends State<_CardNameSelector> {
  bool _showCustomInput = false;
  final _customController = TextEditingController();

  List<String> get _popularCards => [
    'HDFC ${widget.cardType} Card',
    'ICICI ${widget.cardType} Card',
    'SBI ${widget.cardType} Card',
    'Axis ${widget.cardType} Card',
    'Kotak ${widget.cardType} Card',
  ];

  @override
  void initState() {
    super.initState();
    if (!_popularCards.contains(widget.selectedName) && widget.selectedName.isNotEmpty) {
      _customController.text = widget.selectedName;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            ..._popularCards.map((card) {
              final isSelected = card == widget.selectedName && !_showCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() => _showCustomInput = false);
                  widget.onChanged(card);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12, vertical: AppDimensions.spacing8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: isSelected ? AppColors.primary : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  ),
                  child: Text(card, style: AppTypography.labelMedium.copyWith(color: isSelected ? AppColors.primary : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() => _showCustomInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12, vertical: AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: _showCustomInput ? AppColors.warning.withValues(alpha: 0.2) : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(width: 4),
                    Text(widget.l10n?.other ?? 'Other', style: AppTypography.labelMedium.copyWith(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
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
            decoration: InputDecoration(hintText: 'e.g., "My ${widget.cardType} Card"'),
            validator: (value) => (value == null || value.trim().isEmpty) ? (widget.l10n?.cardNameRequired ?? 'Card name is required') : null,
            onChanged: (value) {
              if (value.trim().isNotEmpty) widget.onChanged(value.trim());
            },
          ),
        ],
      ],
    );
  }
}

/// Bank Transfer Type Selector
class _BankTransferSelector extends StatefulWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _BankTransferSelector({
    required this.selectedType,
    required this.onChanged,
    required this.isDark,
    this.l10n,
  });

  @override
  State<_BankTransferSelector> createState() => _BankTransferSelectorState();
}

class _BankTransferSelectorState extends State<_BankTransferSelector> {
  static const _transferTypes = ['NEFT', 'RTGS', 'IMPS', 'UPI Transfer'];
  bool _showCustomInput = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_transferTypes.contains(widget.selectedType) && widget.selectedType.isNotEmpty) {
      _customController.text = widget.selectedType;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            ..._transferTypes.map((type) {
              final isSelected = type == widget.selectedType && !_showCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() => _showCustomInput = false);
                  widget.onChanged(type);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16, vertical: AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: isSelected ? AppColors.primary : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  ),
                  child: Text(type, style: AppTypography.labelMedium.copyWith(color: isSelected ? AppColors.primary : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() => _showCustomInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16, vertical: AppDimensions.spacing12),
                decoration: BoxDecoration(
                  color: _showCustomInput ? AppColors.warning.withValues(alpha: 0.2) : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(width: 4),
                    Text(widget.l10n?.other ?? 'Other', style: AppTypography.labelMedium.copyWith(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
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
            decoration: InputDecoration(hintText: widget.l10n?.enterTransferType ?? 'Enter transfer type...'),
            validator: (value) => (value == null || value.trim().isEmpty) ? (widget.l10n?.transferTypeRequired ?? 'Transfer type is required') : null,
            onChanged: (value) {
              if (value.trim().isNotEmpty) widget.onChanged(value.trim());
            },
          ),
        ],
      ],
    );
  }
}

/// Wallet Selector
class _WalletSelector extends StatefulWidget {
  final String selectedWallet;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _WalletSelector({
    required this.selectedWallet,
    required this.onChanged,
    required this.isDark,
    this.l10n,
  });

  @override
  State<_WalletSelector> createState() => _WalletSelectorState();
}

class _WalletSelectorState extends State<_WalletSelector> {
  static const _wallets = ['Paytm Wallet', 'PhonePe Wallet', 'Amazon Pay Wallet', 'Freecharge Wallet', 'MobiKwik Wallet'];
  bool _showCustomInput = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_wallets.contains(widget.selectedWallet) && widget.selectedWallet.isNotEmpty) {
      _customController.text = widget.selectedWallet;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            ..._wallets.map((wallet) {
              final isSelected = wallet == widget.selectedWallet && !_showCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() => _showCustomInput = false);
                  widget.onChanged(wallet);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12, vertical: AppDimensions.spacing8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: isSelected ? AppColors.primary : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  ),
                  child: Text(wallet, style: AppTypography.labelMedium.copyWith(color: isSelected ? AppColors.primary : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() => _showCustomInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12, vertical: AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: _showCustomInput ? AppColors.warning.withValues(alpha: 0.2) : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(width: 4),
                    Text(widget.l10n?.other ?? 'Other', style: AppTypography.labelMedium.copyWith(color: _showCustomInput ? AppColors.warning : (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
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
            decoration: const InputDecoration(hintText: 'e.g., "My Wallet"'),
            validator: (value) => (value == null || value.trim().isEmpty) ? (widget.l10n?.walletNameRequired ?? 'Wallet name is required') : null,
            onChanged: (value) {
              if (value.trim().isNotEmpty) widget.onChanged(value.trim());
            },
          ),
        ],
      ],
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
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
              boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: isSelected ? const Icon(LucideIcons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }
}
