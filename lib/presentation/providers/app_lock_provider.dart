import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/biometric_service.dart';

/// Provider for whether app lock is currently active (app is locked)
final appIsLockedProvider = StateProvider<bool>((ref) => false);

/// Provider for whether app lock setting is enabled
final appLockEnabledProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier(ref);
});

/// Provider to check if biometric is available on device
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return await BiometricService.instance.isBiometricAvailable();
});

class AppLockNotifier extends StateNotifier<bool> {
  static const String _appLockKey = 'app_lock_enabled';
  final Ref _ref;

  AppLockNotifier(this._ref) : super(false) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_appLockKey) ?? false;
    state = isEnabled;

    // If app lock is enabled, lock the app on startup
    if (isEnabled) {
      _ref.read(appIsLockedProvider.notifier).state = true;
    }
  }

  /// Enable or disable app lock
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      // Verify biometric is available before enabling
      final isAvailable = await BiometricService.instance.isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      // Authenticate to enable app lock
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Authenticate to enable App Lock',
      );
      if (!authenticated) {
        return false;
      }
    }

    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockKey, enabled);

    // If disabling, also unlock the app
    if (!enabled) {
      _ref.read(appIsLockedProvider.notifier).state = false;
    }

    return true;
  }

  /// Attempt to unlock the app
  Future<bool> unlock() async {
    final authenticated = await BiometricService.instance.authenticate(
      reason: 'Authenticate to unlock FlowLedger',
    );

    if (authenticated) {
      _ref.read(appIsLockedProvider.notifier).state = false;
    }

    return authenticated;
  }

  /// Lock the app (called when app goes to background)
  void lock() {
    if (state) {
      _ref.read(appIsLockedProvider.notifier).state = true;
    }
  }
}
