import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/app_lock_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Lock app when it goes to background (paused state)
    if (state == AppLifecycleState.paused) {
      ref.read(appLockEnabledProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appIsLockedProvider);
    final appLockEnabled = ref.watch(appLockEnabledProvider);

    // If app lock is disabled or app is unlocked, show the child
    if (!appLockEnabled || !isLocked) {
      return widget.child;
    }

    // Show lock screen
    return _LockOverlay(
      onUnlock: () async {
        await ref.read(appLockEnabledProvider.notifier).unlock();
      },
    );
  }
}

class _LockOverlay extends StatefulWidget {
  final Future<void> Function() onUnlock;

  const _LockOverlay({required this.onUnlock});

  @override
  State<_LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<_LockOverlay> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger authentication on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    await widget.onUnlock();
    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                LucideIcons.wallet,
                size: 48,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // App Name
            Text(
              l10n?.appName ?? 'FlowLedger',
              style: AppTypography.h1.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Lock message
            Text(
              l10n?.appIsLocked ?? 'App is locked',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),

            const Spacer(flex: 2),

            // Unlock button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.fingerprint, size: 24),
                  label: Text(
                    _isAuthenticating
                        ? (l10n?.authenticating ?? 'Authenticating...')
                        : (l10n?.unlock ?? 'Unlock'),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hint text
            Text(
              l10n?.useFaceIdTouchIdOrPin ?? 'Use Face ID, Touch ID, or device PIN',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
