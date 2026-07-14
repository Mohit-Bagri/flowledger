import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/biometric_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../widgets/common/banner_ad_widget.dart';

/// Provider for merchant mandatory setting
final merchantMandatoryProvider = StateNotifierProvider<MerchantMandatoryNotifier, bool>(
  (ref) => MerchantMandatoryNotifier(),
);

class MerchantMandatoryNotifier extends StateNotifier<bool> {
  static const _prefKey = 'merchant_mandatory';

  MerchantMandatoryNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefKey) ?? true; // Default to mandatory
  }

  Future<void> setMandatory(bool mandatory) async {
    state = mandatory;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, mandatory);
  }
}

class MerchantsScreen extends ConsumerWidget {
  const MerchantsScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedMerchants = ref.watch(merchantsProvider);
    final isMerchantMandatory = ref.watch(merchantMandatoryProvider);

    // Filter out saved merchants that are already in popular list
    final customMerchants = savedMerchants
        .where((m) => !_popularMerchants.any((p) => p.toLowerCase() == m.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.merchants ?? 'Merchants'),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // ========== MERCHANT SETTINGS ==========
          _MerchantSettingCard(
            isDark: isDark,
            isMandatory: isMerchantMandatory,
            onChanged: (value) {
              ref.read(merchantMandatoryProvider.notifier).setMandatory(value);
            },
            l10n: l10n,
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // ========== POPULAR MERCHANTS ==========
          _SectionTitle(
            title: (l10n?.popularMerchants ?? 'Popular Merchants').toUpperCase(),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          _SubSectionHeader(
            title: l10n?.suggestions ?? 'Suggestions',
            count: _popularMerchants.length,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          _MerchantCard(
            isDark: isDark,
            children: _popularMerchants.asMap().entries.map((entry) {
              final index = entry.key;
              final merchant = entry.value;
              final isLast = index == _popularMerchants.length - 1;
              return _MerchantTile(
                name: merchant,
                isSystem: true,
                showDivider: !isLast,
                isDark: isDark,
                l10n: l10n,
              );
            }).toList(),
          ),

          const SizedBox(height: AppDimensions.spacing32),

          // ========== CUSTOM MERCHANTS ==========
          _SectionTitle(
            title: (l10n?.customMerchants ?? 'Custom Merchants').toUpperCase(),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          _SubSectionHeader(
            title: l10n?.yourMerchants ?? 'Your Merchants',
            count: customMerchants.length,
            isDark: isDark,
            onAdd: () => _showAddMerchantSheet(context, ref, l10n),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          if (customMerchants.isEmpty)
            _EmptyMerchantCard(
              message: l10n?.noCustomMerchantsYet ?? 'No custom merchants yet',
              hint: l10n?.addByTappingPlus ?? 'Add one by tapping the + button above or by adding an expense with a new merchant',
              isDark: isDark,
            )
          else
            _MerchantCard(
              isDark: isDark,
              children: customMerchants.asMap().entries.map((entry) {
                final index = entry.key;
                final merchant = entry.value;
                final isLast = index == customMerchants.length - 1;
                return _MerchantTile(
                  name: merchant,
                  isSystem: false,
                  showDivider: !isLast,
                  isDark: isDark,
                  onEdit: () => _editMerchant(context, ref, merchant, l10n),
                  onDelete: () => _deleteMerchant(context, ref, merchant, l10n),
                  l10n: l10n,
                );
              }).toList(),
            ),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  void _showAddMerchantSheet(BuildContext context, WidgetRef ref, AppLocalizations? l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.bottomSheetRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              Text(
                l10n?.addMerchant ?? 'Add Merchant',
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: l10n?.merchantName ?? 'Merchant name...',
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      await ref.read(merchantsProvider.notifier).addMerchant(controller.text.trim());
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(l10n?.addMerchant ?? 'Add Merchant'),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  void _editMerchant(BuildContext context, WidgetRef ref, String oldMerchantName, AppLocalizations? l10n) async {
    // Step 1: Show confirmation/warning dialog
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.editMerchant ?? 'Edit Merchant'),
        content: Text(l10n?.renameMerchantNote ?? 'This will rename "$oldMerchantName" in your saved merchants list.\n\nNote: This only updates the suggestion list. Existing expenses store merchant names directly and will keep the original name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.continue_ ?? 'Continue'),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    // Step 2: Authenticate
    final authenticated = await BiometricService.instance.authenticateForEdit();
    if (!authenticated) return;

    // Step 3: Show edit sheet
    if (!context.mounted) return;
    _showEditMerchantSheet(context, ref, oldMerchantName, l10n);
  }

  void _showEditMerchantSheet(BuildContext context, WidgetRef ref, String oldMerchantName, AppLocalizations? l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: oldMerchantName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.bottomSheetRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              Text(
                l10n?.editMerchant ?? 'Edit Merchant',
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: l10n?.merchantName ?? 'Merchant name...',
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty && controller.text.trim() != oldMerchantName) {
                      // Delete old and add new
                      await ref.read(merchantsProvider.notifier).deleteMerchant(oldMerchantName);
                      await ref.read(merchantsProvider.notifier).addMerchant(controller.text.trim());
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } else if (controller.text.trim() == oldMerchantName) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n?.saveChanges ?? 'Save Changes'),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMerchant(BuildContext context, WidgetRef ref, String merchantName, AppLocalizations? l10n) async {
    // Step 1: Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteMerchant ?? 'Delete Merchant'),
        content: Text(l10n?.deleteMerchantNote ?? 'Are you sure you want to delete "$merchantName" from your saved merchants?\n\nNote: This only removes it from the suggestion list. Existing expenses will keep their merchant names.'),
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

    // Step 2: Authenticate after confirmation
    final authenticated = await BiometricService.instance.authenticateForDelete();
    if (!authenticated) return;

    // Step 3: Delete
    await ref.read(merchantsProvider.notifier).deleteMerchant(merchantName);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;
  final VoidCallback? onAdd;

  const _SubSectionHeader({
    required this.title,
    required this.count,
    required this.isDark,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const Spacer(),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                LucideIcons.plus,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _MerchantCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _EmptyMerchantCard extends StatelessWidget {
  final String message;
  final String hint;
  final bool isDark;

  const _EmptyMerchantCard({
    required this.message,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            LucideIcons.store,
            size: 32,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            hint,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MerchantTile extends StatelessWidget {
  final String name;
  final bool isSystem;
  final bool showDivider;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final AppLocalizations? l10n;

  const _MerchantTile({
    required this.name,
    required this.isSystem,
    required this.showDivider,
    required this.isDark,
    this.onEdit,
    this.onDelete,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              LucideIcons.store,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          title: Text(
            name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          trailing: isSystem
              ? Text(
                  l10n?.popular ?? 'Popular',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                )
              : PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 18, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(l10n?.edit ?? 'Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing16,
            endIndent: AppDimensions.spacing16,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

/// Settings card for merchant mandatory/optional toggle
class _MerchantSettingCard extends StatelessWidget {
  final bool isDark;
  final bool isMandatory;
  final ValueChanged<bool> onChanged;
  final AppLocalizations? l10n;

  const _MerchantSettingCard({
    required this.isDark,
    required this.isMandatory,
    required this.onChanged,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.settings,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Text(
                l10n?.merchantSettings ?? 'Merchant Settings',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.merchantFieldMandatory ?? 'Merchant field is mandatory',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMandatory
                          ? (l10n?.merchantMandatoryNote ?? 'You must enter a merchant when adding expenses')
                          : (l10n?.merchantOptionalNote ?? 'Merchant field is optional when adding expenses'),
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isMandatory,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
