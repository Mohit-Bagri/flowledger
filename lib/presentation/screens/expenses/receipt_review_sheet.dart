import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/receipt.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/common/bottom_sheet_handle.dart';

/// Receipt Review Sheet - Review and edit extracted receipt data
class ReceiptReviewSheet extends StatefulWidget {
  final Receipt receipt;
  final File imageFile;

  const ReceiptReviewSheet({
    super.key,
    required this.receipt,
    required this.imageFile,
  });

  static Future<Receipt?> show(
    BuildContext context, {
    required Receipt receipt,
    required File imageFile,
  }) {
    return showModalBottomSheet<Receipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptReviewSheet(
        receipt: receipt,
        imageFile: imageFile,
      ),
    );
  }

  @override
  State<ReceiptReviewSheet> createState() => _ReceiptReviewSheetState();
}

class _ReceiptReviewSheetState extends State<ReceiptReviewSheet> {
  late TextEditingController _merchantController;
  late DateTime? _selectedDate;
  late List<ReceiptItem> _items;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.receipt.merchantName ?? '');
    _selectedDate = widget.receipt.extractedDate;
    _items = List.from(widget.receipt.items);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

  double get _selectedTotal {
    return _items
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.total);
  }

  int get _selectedCount {
    return _items.where((item) => item.isSelected).length;
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        isSelected: !_items[index].isSelected,
      );
    });
  }

  void _editItem(int index) async {
    final result = await _EditItemDialog.show(
      context,
      item: _items[index],
    );
    if (result != null) {
      setState(() {
        _items[index] = result;
      });
    }
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _addNewItem() async {
    final result = await _EditItemDialog.show(
      context,
      item: null,
    );
    if (result != null) {
      setState(() {
        _items.add(result);
      });
    }
  }

  void _useThisData() {
    final updatedReceipt = widget.receipt.copyWith(
      merchantName: _merchantController.text.trim().isEmpty
          ? null
          : _merchantController.text.trim(),
      extractedDate: _selectedDate,
      items: _items,
      extractedTotal: _selectedTotal,
    );
    Navigator.pop(context, updatedReceipt);
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
                  l10n?.reviewReceipt ?? 'Review Receipt',
                  style: AppTypography.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _selectedCount > 0 ? _useThisData : null,
                  child: Text(
                    l10n?.use ?? 'Use',
                    style: AppTypography.labelLarge.copyWith(
                      color: _selectedCount > 0
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppDimensions.screenPaddingHorizontal,
                right: AppDimensions.screenPaddingHorizontal,
                bottom: bottomPadding + AppDimensions.spacing24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spacing16),

                  // Receipt image preview (thumbnail)
                  GestureDetector(
                    onTap: () => _showImagePreview(context),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(AppDimensions.radiusMedium - 1),
                            ),
                            child: Image.file(
                              widget.imageFile,
                              width: 80,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimensions.spacing12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.checkCircle,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.receiptScanned ?? 'Receipt scanned',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_items.length} ${l10n?.itemsDetected ?? 'items detected'}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n?.tapToViewFullImage ?? 'Tap to view full image',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: AppDimensions.spacing12),
                            child: Icon(
                              LucideIcons.expand,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacing24),

                  // Merchant Name
                  _buildLabel(l10n?.merchantName ?? 'Merchant Name', isDark),
                  const SizedBox(height: AppDimensions.spacing8),
                  TextFormField(
                    controller: _merchantController,
                    decoration: InputDecoration(
                      hintText: l10n?.enterMerchantName ?? 'Enter merchant name',
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacing16),

                  // Date
                  _buildLabel(l10n?.date ?? 'Date', isDark),
                  const SizedBox(height: AppDimensions.spacing8),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
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
                            LucideIcons.calendar,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: AppDimensions.spacing12),
                          Text(
                            _selectedDate != null
                                ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                : (l10n?.selectDate ?? 'Select date'),
                            style: AppTypography.bodyMedium.copyWith(
                              color: _selectedDate != null
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary)
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacing24),

                  // Items Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(l10n?.items ?? 'Items', isDark),
                      TextButton.icon(
                        onPressed: _addNewItem,
                        icon: Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          l10n?.addItem ?? 'Add Item',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacing8),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacing24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.receipt,
                              size: 32,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: AppDimensions.spacing12),
                            Text(
                              l10n?.noItemsDetected ?? 'No items detected',
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.tapAddItemToAddManually ?? 'Tap "Add Item" to add manually',
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _ItemTile(
                              item: item,
                              isDark: isDark,
                              onToggle: () => _toggleItem(index),
                              onEdit: () => _editItem(index),
                              onDelete: () => _deleteItem(index),
                              showDivider: index < _items.length - 1,
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppDimensions.spacing16),

                  // Total summary
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.selectedTotal ?? 'Selected Total',
                              style: AppTypography.labelMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_selectedCount of ${_items.length} ${l10n?.items ?? 'items'}',
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(_selectedTotal),
                          style: AppTypography.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Raw text toggle (optional)
                  if (widget.receipt.rawText != null && widget.receipt.rawText!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacing16),
                    GestureDetector(
                      onTap: () => setState(() => _showRawText = !_showRawText),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.spacing12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.fileText,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: AppDimensions.spacing8),
                            Text(
                              l10n?.viewRawExtractedText ?? 'View raw extracted text',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showRawText
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showRawText) ...[
                      const SizedBox(height: AppDimensions.spacing8),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacing12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: Text(
                          widget.receipt.rawText!,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: AppDimensions.spacing24),

                  // Use button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedCount > 0 ? _useThisData : null,
                      child: Text(l10n?.useThisData(_selectedCount) ?? 'Use This Data ($_selectedCount items)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: InteractiveViewer(
                child: Image.file(widget.imageFile),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                  label: Text(l10n?.close ?? 'Close'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ReceiptItem item;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  const _ItemTile({
    required this.item,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing12),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item.isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 2,
                    ),
                  ),
                  child: item.isSelected
                      ? const Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: item.isSelected
                            ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)
                            : (isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary),
                        decoration: item.isSelected
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        '${item.quantity} × ${CurrencyFormatter.format(item.price)}',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                  ],
                ),
              ),

              // Price
              Text(
                CurrencyFormatter.format(item.total),
                style: AppTypography.labelLarge.copyWith(
                  color: item.isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: AppDimensions.spacing8),

              // Edit button
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),

              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 48,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

/// Dialog for editing/adding an item
class _EditItemDialog extends StatefulWidget {
  final ReceiptItem? item;

  const _EditItemDialog({this.item});

  static Future<ReceiptItem?> show(BuildContext context, {ReceiptItem? item}) {
    return showDialog<ReceiptItem>(
      context: context,
      builder: (context) => _EditItemDialog(item: item),
    );
  }

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(
      text: widget.item?.price.toStringAsFixed(2) ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '1',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text);
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (name.isEmpty || price == null || price <= 0) {
      return;
    }

    final item = widget.item?.copyWith(
          name: name,
          price: price,
          quantity: quantity,
        ) ??
        ReceiptItem.create(
          name: name,
          price: price,
          quantity: quantity,
        );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.item != null ? (l10n?.editItem ?? 'Edit Item') : (l10n?.addItem ?? 'Add Item')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n?.itemName ?? 'Item Name',
              hintText: l10n?.itemNameHint ?? 'e.g., Coffee',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: l10n?.price ?? 'Price',
                    prefixText: '${CurrencyFormatter.selectedCurrency.symbol} ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: l10n?.qty ?? 'Qty',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.item != null ? (l10n?.update ?? 'Update') : (l10n?.add ?? 'Add')),
        ),
      ],
    );
  }
}
