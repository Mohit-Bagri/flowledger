import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service for handling biometric authentication
class BiometricService {
  static BiometricService? _instance;
  static BiometricService get instance => _instance ??= BiometricService._();

  BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuth = await _localAuth.isDeviceSupported();
      return canAuthWithBiometrics || canAuth;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate user with biometrics
  /// Returns true if authentication successful, false otherwise
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // If biometrics not available, allow the action
        return true;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/password as fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Authenticate specifically for editing financial data
  Future<bool> authenticateForEdit() async {
    return authenticate(
      reason: 'Authenticate to edit this transaction',
    );
  }

  /// Authenticate specifically for deleting financial data
  Future<bool> authenticateForDelete() async {
    return authenticate(
      reason: 'Authenticate to delete this transaction',
    );
  }
}
