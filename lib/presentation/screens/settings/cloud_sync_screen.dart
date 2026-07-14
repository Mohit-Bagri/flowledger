import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/sync_service.dart';
import '../../../services/supabase_service.dart';
import '../../providers/storage_providers.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/animated_snackbar.dart';
import '../../widgets/common/upgrade_dialog.dart';
import '../../widgets/common/banner_ad_widget.dart';

/// Provider for sync status
final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

/// Provider for last sync time
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for auto-sync toggle
final autoSyncProvider = StateProvider<bool>((ref) => false);

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  bool _isSyncing = false;
  StreamSubscription<SyncStateEvent>? _syncStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
    _listenToSyncState();
  }

  @override
  void dispose() {
    _syncStateSubscription?.cancel();
    super.dispose();
  }

  /// Listen to sync state stream for auto-sync updates
  void _listenToSyncState() {
    _syncStateSubscription = SyncService.instance.syncStateStream.listen((event) {
      if (mounted) {
        // Update the last sync time provider when sync completes
        ref.read(lastSyncTimeProvider.notifier).state = event.lastSyncTime;
        ref.read(syncStatusProvider.notifier).state = event.status;

        // Also refresh providers if data was downloaded during auto-sync
        if (event.result != null && event.result!.success && event.result!.downloaded > 0) {
          _refreshAllProviders();
        }
      }
    });
  }

  Future<void> _loadLastSyncTime() async {
    await SyncService.instance.initialize();
    ref.read(lastSyncTimeProvider.notifier).state = SyncService.instance.lastSyncTime;
    ref.read(autoSyncProvider.notifier).state = SyncService.instance.autoSyncEnabled;
  }

  Future<void> _toggleAutoSync(bool value) async {
    // Check premium access before enabling auto-sync
    if (value) {
      final hasFeature = ref.read(subscriptionProvider.notifier).hasFeature(
        PremiumFeature.cloudSync,
      );
      if (!hasFeature) {
        UpgradeDialog.show(context, feature: PremiumFeature.cloudSync);
        return;
      }
    }

    await SyncService.instance.setAutoSync(value);
    ref.read(autoSyncProvider.notifier).state = value;

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      if (value) {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.autoSyncEnabled ?? 'Auto-sync enabled. Changes will sync automatically.',
        );
      } else {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.autoSyncDisabled ?? 'Auto-sync disabled. Use "Sync Now" to sync manually.',
        );
      }
    }
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    // Check premium access
    final hasFeature = ref.read(subscriptionProvider.notifier).hasFeature(
      PremiumFeature.cloudSync,
    );
    if (!hasFeature) {
      UpgradeDialog.show(context, feature: PremiumFeature.cloudSync);
      return;
    }

    setState(() => _isSyncing = true);
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    final result = await SyncService.instance.syncAll();

    // Refresh providers if any data was downloaded
    if (result.success && result.downloaded > 0) {
      _refreshAllProviders();
    }

    setState(() => _isSyncing = false);
    ref.read(syncStatusProvider.notifier).state = result.success ? SyncStatus.success : SyncStatus.error;
    ref.read(lastSyncTimeProvider.notifier).state = SyncService.instance.lastSyncTime;

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      if (result.success) {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.syncedUpDown(result.uploaded, result.downloaded) ?? 'Synced ${result.uploaded} up, ${result.downloaded} down',
        );
      } else {
        AnimatedSnackbar.showError(context, result.message ?? (l10n?.syncFailed ?? 'Sync failed'));
      }
    }
  }

  Future<void> _backupData() async {
    if (_isSyncing) return;

    // Check premium access
    final hasFeature = ref.read(subscriptionProvider.notifier).hasFeature(
      PremiumFeature.cloudBackup,
    );
    if (!hasFeature) {
      UpgradeDialog.show(context, feature: PremiumFeature.cloudBackup);
      return;
    }

    setState(() => _isSyncing = true);
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    final result = await SyncService.instance.backupToCloud();

    setState(() => _isSyncing = false);
    ref.read(syncStatusProvider.notifier).state = result.success ? SyncStatus.success : SyncStatus.error;
    ref.read(lastSyncTimeProvider.notifier).state = SyncService.instance.lastSyncTime;

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      if (result.success) {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.backedUpItems(result.uploaded) ?? 'Backed up ${result.uploaded} items',
        );
      } else {
        AnimatedSnackbar.showError(context, result.message ?? (l10n?.backupFailed ?? 'Backup failed'));
      }
    }
  }

  Future<void> _restoreData() async {
    if (_isSyncing) return;

    // Check premium access
    final hasFeature = ref.read(subscriptionProvider.notifier).hasFeature(
      PremiumFeature.cloudBackup,
    );
    if (!hasFeature) {
      UpgradeDialog.show(context, feature: PremiumFeature.cloudBackup);
      return;
    }

    final l10n = AppLocalizations.of(context);

    // Show confirmation dialog with clear warning
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.restoreFromCloudQuestion ?? 'Restore from Cloud?'),
        content: Text(
          l10n?.restoreWarning ??
          '⚠️ WARNING: This will REPLACE all your local data with data from the cloud.\n\n'
          'Any transactions added locally since your last backup will be LOST.\n\n'
          'Use "Sync Now" instead if you want to merge local and cloud data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(l10n?.restore ?? 'Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    final result = await SyncService.instance.restoreFromCloud();

    // IMPORTANT: Refresh all providers to update UI with restored data
    if (result.success) {
      _refreshAllProviders();
    }

    setState(() => _isSyncing = false);
    ref.read(syncStatusProvider.notifier).state = result.success ? SyncStatus.success : SyncStatus.error;
    ref.read(lastSyncTimeProvider.notifier).state = SyncService.instance.lastSyncTime;

    if (mounted) {
      if (result.success) {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.restoredItems(result.downloaded) ?? 'Restored ${result.downloaded} items',
        );
      } else {
        AnimatedSnackbar.showError(context, result.message ?? (l10n?.restoreFailed ?? 'Restore failed'));
      }
    }
  }

  /// Refresh all data providers after restore to update UI
  void _refreshAllProviders() {
    // Refresh all storage-backed providers
    // NOTE: income_transactions is DEPRECATED - all income data is in income_sources
    ref.read(bankAccountsProvider.notifier).refresh();
    ref.read(paymentMethodsProvider.notifier).refresh();
    ref.read(incomeSourcesProvider.notifier).refresh();
    ref.read(expensesProvider.notifier).refresh();
    ref.read(customExpenseCategoriesProvider.notifier).refresh();
    ref.read(customIncomeCategoriesProvider.notifier).refresh();
    ref.read(merchantsProvider.notifier).refresh();
    ref.read(budgetsProvider.notifier).refresh();
    ref.read(goalsProvider.notifier).refresh();
    ref.read(recurringTransactionsProvider.notifier).refresh();
  }

  void _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Your local data will be cleared for privacy. Sign in again to restore your data from the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      // Refresh all providers to clear UI state
      _refreshAllProviders();
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = ref.watch(isPremiumProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.cloudSync ?? 'Cloud Sync',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: !isPremium
          ? _buildPremiumGate(isDark, l10n)
          : ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // Account section
          if (isAuthenticated) ...[
            _buildAccountCard(isDark, authState),
            const SizedBox(height: 24),
          ],

          // Sync Status Card
          _buildSyncStatusCard(isDark, lastSync, isAuthenticated),

          const SizedBox(height: 24),

          // Auto-sync toggle (only show when authenticated)
          if (isAuthenticated) ...[
            _buildAutoSyncToggle(isDark),
            const SizedBox(height: 24),
          ],

          // Sync Actions
          if (isAuthenticated) ...[
            _buildActionCard(
              isDark,
              icon: LucideIcons.refreshCw,
              title: l10n?.syncNow ?? 'Sync Now',
              subtitle: l10n?.uploadAndDownloadChanges ?? 'Upload and download changes',
              onTap: _syncData,
              isLoading: _isSyncing,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              isDark,
              icon: LucideIcons.upload,
              title: l10n?.backupToCloud ?? 'Backup to Cloud',
              subtitle: l10n?.uploadAllLocalData ?? 'Upload all local data',
              onTap: _backupData,
              isLoading: _isSyncing,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              isDark,
              icon: LucideIcons.download,
              title: l10n?.restoreFromCloud ?? 'Restore from Cloud',
              subtitle: l10n?.downloadAllCloudData ?? 'Download all cloud data',
              onTap: _restoreData,
              isLoading: _isSyncing,
            ),
            const SizedBox(height: 24),
            // Danger Zone - Delete Cloud Data
            _buildDangerZone(isDark),
          ] else ...[
            _buildSignInPrompt(isDark),
          ],

          const SizedBox(height: 32),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
            child: Text(
              isAuthenticated
                  ? (l10n?.dataEncryptedSecurely ?? 'Your data is encrypted and securely stored in the cloud. Sync to access it from any device.')
                  : (l10n?.signInToBackupData ?? 'Sign in to backup your data and sync across devices.'),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Premium gate - shows when user doesn't have premium access
  Widget _buildPremiumGate(bool isDark, AppLocalizations? l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.cloud,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              l10n?.cloudSyncPremiumTitle ?? 'Cloud Sync is a PRO Feature',
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n?.cloudSyncPremiumDesc ?? 'Upgrade to PRO to backup your data securely and access it from any device.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Features list
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildPremiumFeatureItem(
                    icon: LucideIcons.upload,
                    title: l10n?.backupToCloud ?? 'Backup to Cloud',
                    description: l10n?.backupDesc ?? 'Securely store all your data',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeatureItem(
                    icon: LucideIcons.smartphone,
                    title: l10n?.accessAnyDevice ?? 'Access from Any Device',
                    description: l10n?.accessAnyDeviceDesc ?? 'Sync across all your devices',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeatureItem(
                    icon: LucideIcons.refreshCw,
                    title: l10n?.autoSync ?? 'Auto-Sync',
                    description: l10n?.autoSyncDesc ?? 'Changes sync automatically',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () => context.push('/paywall'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.sparkles, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.upgradeToPro ?? 'Upgrade to PRO',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(bool isDark, AuthState authState) {
    // Use profile provider for consistent display name
    final profile = ref.watch(profileProvider);
    final displayName = profile.displayName ??
        authState.user?.email?.split('@').first ??
        'User';
    final email = profile.email ?? authState.user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.moreVertical,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            onSelected: (value) {
              if (value == 'signout') {
                _signOut();
              } else if (value == 'delete') {
                _deleteAccount();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    const SizedBox(width: 12),
                    Text('Sign Out', style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text('Delete Account', style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          '⚠️ This will permanently delete:\n\n'
          '• Your profile\n'
          '• All income records\n'
          '• All expense records\n'
          '• All bank accounts\n'
          '• All payment methods\n'
          '• All budgets and goals\n'
          '• All recurring transactions\n'
          '• All custom categories\n'
          '• All merchants\n\n'
          'This action CANNOT be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Continue',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation with typing
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(),
    );

    if (secondConfirm != true || !mounted) return;

    // Perform deletion
    setState(() => _isSyncing = true);

    final result = await SupabaseService.instance.deleteAccount();

    setState(() => _isSyncing = false);

    if (mounted) {
      if (result.success) {
        AnimatedSnackbar.showSuccess(context, result.message ?? 'Account deleted');
        ref.read(authProvider.notifier).signOut();
        context.go('/');
      } else {
        AnimatedSnackbar.showError(context, result.message ?? 'Failed to delete account');
      }
    }
  }

  Widget _buildSyncStatusCard(bool isDark, DateTime? lastSync, bool isAuthenticated) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
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
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isAuthenticated ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAuthenticated ? LucideIcons.checkCircle : LucideIcons.cloudOff,
                      color: isAuthenticated ? AppColors.success : AppColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated ? (l10n?.connected ?? 'Connected') : (l10n?.notConnected ?? 'Not Connected'),
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAuthenticated
                              ? (lastSync != null
                                  ? (l10n?.lastSynced(_formatLastSync(lastSync, l10n)) ?? 'Last synced: ${_formatLastSync(lastSync, l10n)}')
                                  : (l10n?.neverSynced ?? 'Never synced'))
                              : (l10n?.signInToEnableCloudSync ?? 'Sign in to enable cloud sync'),
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSyncing)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoSyncToggle(bool isDark) {
    final autoSyncEnabled = ref.watch(autoSyncProvider);

    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  autoSyncEnabled ? LucideIcons.zap : LucideIcons.zapOff,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.autoSync ?? 'Auto-Sync',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      autoSyncEnabled
                          ? (l10n?.autoSyncDesc ?? 'Changes sync automatically')
                          : (l10n?.syncManuallyWithSyncNow ?? 'Sync manually with "Sync Now"'),
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: autoSyncEnabled,
                onChanged: _toggleAutoSync,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(bool isDark) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.cloud,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.signInToEnableSync ?? 'Sign in to Enable Sync',
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.backupDataAccessAnywhere ?? 'Backup your data and access it from any device',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: Text(
                    l10n?.signIn ?? 'Sign In',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatLastSync(DateTime dateTime, AppLocalizations? l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n?.justNow ?? 'Just now';
    } else if (difference.inHours < 1) {
      return l10n?.minAgo(difference.inMinutes) ?? '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return l10n?.hoursAgo(difference.inHours) ?? '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return l10n?.daysAgo(difference.inDays) ?? '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  Widget _buildDangerZone(bool isDark) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.dangerZone ?? 'Danger Zone',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _isSyncing ? null : _deleteAllCloudData,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      color: AppColors.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.deleteAllCloudData ?? 'Delete All Cloud Data',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n?.deleteCloudDataDesc ?? 'Permanently delete all data from cloud and local storage',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.error.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllCloudData() async {
    if (_isSyncing) return;

    final l10n = AppLocalizations.of(context);

    // Check premium access - cloud sync is a premium feature
    final hasFeature = ref.read(subscriptionProvider.notifier).hasFeature(
      PremiumFeature.cloudSync,
    );
    if (!hasFeature) {
      UpgradeDialog.show(context, feature: PremiumFeature.cloudSync);
      return;
    }

    // First confirmation dialog
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.deleteAllCloudData ?? 'Delete All Cloud Data?',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          l10n?.deleteCloudDataWarning ??
          '⚠️ This will PERMANENTLY delete:\n\n'
          '• All transactions from cloud\n'
          '• All bank accounts from cloud\n'
          '• All payment methods from cloud\n'
          '• All budgets and goals from cloud\n'
          '• All recurring transactions from cloud\n'
          '• All custom categories from cloud\n'
          '• All merchants from cloud\n\n'
          'Local data will also be cleared.\n\n'
          'This action CANNOT be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n?.continueText ?? 'Continue',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation with typing DELETE
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteCloudDataConfirmationDialog(),
    );

    if (secondConfirm != true || !mounted) return;

    // Perform deletion
    setState(() => _isSyncing = true);

    try {
      // Delete cloud data
      final cloudDeleted = await SyncService.instance.deleteCloudData();

      // Clear local data
      await SyncService.instance.clearAllLocalData();

      // Refresh all providers to update UI
      _refreshAllProviders();

      setState(() => _isSyncing = false);

      if (mounted) {
        if (cloudDeleted) {
          AnimatedSnackbar.showSuccess(
            context,
            l10n?.allDataDeletedSuccessfully ?? 'All cloud and local data deleted successfully',
          );
        } else {
          AnimatedSnackbar.showError(
            context,
            l10n?.failedToDeleteCloudData ?? 'Failed to delete cloud data',
          );
        }
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        AnimatedSnackbar.showError(
          context,
          l10n?.errorDeletingData ?? 'Error deleting data: $e',
        );
      }
    }
  }
}

/// Dialog requiring user to type DELETE to confirm cloud data deletion
class _DeleteCloudDataConfirmationDialog extends StatefulWidget {
  @override
  State<_DeleteCloudDataConfirmationDialog> createState() => _DeleteCloudDataConfirmationDialogState();
}

class _DeleteCloudDataConfirmationDialogState extends State<_DeleteCloudDataConfirmationDialog> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isValid = _controller.text.trim().toUpperCase() == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          Text(l10n?.finalConfirmation ?? 'Final Confirmation'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.typeDeleteToConfirmCloudData ?? 'Type DELETE to permanently delete all cloud and local data:',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                borderSide: BorderSide(
                  color: _isValid ? AppColors.error : AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
          ),
          child: Text(l10n?.deleteForever ?? 'Delete Forever'),
        ),
      ],
    );
  }
}

/// Dialog requiring user to type DELETE to confirm account deletion
class _DeleteConfirmationDialog extends StatefulWidget {
  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isValid = _controller.text.trim().toUpperCase() == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          const Text('Final Confirmation'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type DELETE to permanently delete your account:',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                borderSide: BorderSide(
                  color: _isValid ? AppColors.error : AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
          ),
          child: const Text('Delete Forever'),
        ),
      ],
    );
  }
}
