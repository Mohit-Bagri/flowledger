import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle runtime permissions for both Android and iOS
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Request camera permission
  /// Returns true if permission is granted
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (context.mounted) {
        final shouldOpenSettings = await _showPermissionDeniedDialog(
          context,
          'Camera Permission Required',
          'Camera access is needed to scan receipts. Please enable it in Settings.',
        );
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }

    return false;
  }

  /// Request photo library permission
  /// Returns true if permission is granted
  Future<bool> requestPhotoLibraryPermission(BuildContext context) async {
    Permission permission;

    if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      // Android 13+ uses READ_MEDIA_IMAGES, older uses READ_EXTERNAL_STORAGE
      permission = Permission.photos;
    }

    final status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted || result.isLimited;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpenSettings = await _showPermissionDeniedDialog(
          context,
          'Photo Library Permission Required',
          'Photo library access is needed to select receipt images. Please enable it in Settings.',
        );
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }

    return false;
  }

  /// Request notification permission (mainly for Android 13+)
  /// Returns true if permission is granted
  Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpenSettings = await _showPermissionDeniedDialog(
          context,
          'Notification Permission Required',
          'Notifications help you stay on track with expense tracking reminders. Please enable it in Settings.',
        );
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }

    return false;
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check if photo library permission is granted
  Future<bool> isPhotoLibraryPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Show permission request dialog with custom UI
  Future<bool> showPermissionRequestDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String permissionType,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionRequestDialog(
        title: title,
        message: message,
        permissionType: permissionType,
        icon: icon,
      ),
    ) ?? false;
  }

  Future<bool> _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// Custom permission request dialog widget
class _PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String message;
  final String permissionType;
  final IconData icon;

  const _PermissionRequestDialog({
    required this.title,
    required this.message,
    required this.permissionType,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Allow'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to show permission dialogs from anywhere
extension PermissionContext on BuildContext {
  Future<bool> requestCameraPermission() async {
    return await PermissionService.instance.requestCameraPermission(this);
  }

  Future<bool> requestPhotoLibraryPermission() async {
    return await PermissionService.instance.requestPhotoLibraryPermission(this);
  }

  Future<bool> requestNotificationPermission() async {
    return await PermissionService.instance.requestNotificationPermission(this);
  }
}
