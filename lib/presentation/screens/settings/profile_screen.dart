import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show UserAttributes;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/supabase_service.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/animated_snackbar.dart';
import '../../widgets/common/banner_ad_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _showEditNameDialog() async {
    final profile = ref.read(profileProvider);
    final controller = TextEditingController(text: profile.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(controller: controller),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await ref.read(profileProvider.notifier).updateDisplayName(newName);
    }
  }

  Future<void> _showBirthDatePicker() async {
    final profile = ref.read(profileProvider);
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: profile.birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birth date',
    );

    if (selectedDate != null) {
      final success = await ref.read(profileProvider.notifier).updateBirthDate(selectedDate);
      if (mounted && success) {
        AnimatedSnackbar.showSuccess(context, 'Birth date updated');
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );

    if (result == true && mounted) {
      AnimatedSnackbar.showSuccess(context, 'Password updated successfully');
    }
  }

  Future<void> _linkGoogleAccount() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await SupabaseService.instance.linkGoogleIdentity();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        AnimatedSnackbar.showSuccess(context, result.message ?? 'Google account linked!');
        setState(() {}); // Refresh UI to show updated state
      } else {
        AnimatedSnackbar.showError(context, result.message ?? 'Failed to link Google account');
      }
    }
  }

  Future<void> _unlinkGoogleAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Google Account?'),
        content: const Text(
          'You will no longer be able to sign in with Google. '
          'You can still sign in with your email and password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Unlink',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await SupabaseService.instance.unlinkGoogleIdentity();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        AnimatedSnackbar.showSuccess(context, result.message ?? 'Google account unlinked');
        setState(() {}); // Refresh UI to show updated state
      } else {
        AnimatedSnackbar.showError(context, result.message ?? 'Failed to unlink Google account');
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out?\n\n'
          'Your local data will remain on this device, but you won\'t be able to sync until you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await ref.read(authProvider.notifier).signOut();

    if (mounted) {
      AnimatedSnackbar.showSuccess(context, 'Signed out successfully');
      context.go(AppRoutes.login);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // First confirmation with list of what will be deleted
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
            child: const Text(
              'Continue',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation with typing DELETE
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(),
    );

    if (secondConfirm != true || !mounted) return;

    // Show loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Perform deletion
    final result = await SupabaseService.instance.deleteAccount();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        AnimatedSnackbar.showSuccess(context, result.message ?? 'Account deleted');
        ref.read(authProvider.notifier).signOut();
        context.go(AppRoutes.login);
      } else {
        AnimatedSnackbar.showError(context, result.message ?? 'Failed to delete account');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final isAuthenticated = SupabaseService.instance.isAuthenticated;
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
          l10n?.profile ?? 'Profile',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: !isAuthenticated
          ? _NotSignedInView(isDark: isDark)
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              children: [
                // Avatar section - displays initial from display name
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: _DefaultAvatar(
                      name: profile.displayName,
                      isDark: isDark,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Profile info cards
                _ProfileItem(
                  icon: LucideIcons.user,
                  label: l10n?.displayName ?? 'Display Name',
                  value: profile.displayName ?? 'Not set',
                  isDark: isDark,
                  onTap: _showEditNameDialog,
                  trailing: const Icon(LucideIcons.pencil, size: 18),
                ),

                const SizedBox(height: AppDimensions.spacing12),

                _ProfileItem(
                  icon: LucideIcons.mail,
                  label: l10n?.email ?? 'Email',
                  value: profile.email ?? 'Not available',
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.changeEmail),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                ),

                const SizedBox(height: AppDimensions.spacing12),

                // Only show change password for email/password users (not Google-only)
                if (!SupabaseService.instance.isGoogleOnlyUser) ...[
                  _ProfileItem(
                    icon: LucideIcons.keyRound,
                    label: l10n?.changePassword ?? 'Change Password',
                    value: l10n?.updateYourPassword ?? 'Update your account password',
                    isDark: isDark,
                    onTap: _showChangePasswordDialog,
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                ],

                // Google Account Linking section
                // Show "Link Google" for email/password users without Google linked
                // Show "Google Connected" with unlink option for users with both
                if (SupabaseService.instance.hasEmailIdentity) ...[
                  if (!SupabaseService.instance.hasGoogleLinked)
                    _ProfileItem(
                      icon: LucideIcons.link,
                      label: l10n?.linkGoogleAccount ?? 'Link Google Account',
                      value: l10n?.linkGoogleDescription ?? 'Sign in with Google or email',
                      isDark: isDark,
                      onTap: _linkGoogleAccount,
                      trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    )
                  else
                    _ProfileItem(
                      icon: LucideIcons.checkCircle,
                      label: l10n?.googleConnected ?? 'Google Connected',
                      value: l10n?.googleConnectedDescription ?? 'You can sign in with Google or email',
                      isDark: isDark,
                      onTap: _unlinkGoogleAccount,
                      trailing: Icon(
                        LucideIcons.unlink,
                        size: 18,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  const SizedBox(height: AppDimensions.spacing12),
                ],

                _ProfileItem(
                  icon: LucideIcons.cake,
                  label: l10n?.birthDate ?? 'Birth Date',
                  value: profile.birthDate != null
                      ? DateFormat.yMMMMd().format(profile.birthDate!)
                      : 'Not set',
                  isDark: isDark,
                  onTap: _showBirthDatePicker,
                  trailing: const Icon(LucideIcons.calendar, size: 18),
                ),

                const SizedBox(height: 32),

                // Sign Out
                _ProfileItem(
                  icon: LucideIcons.logOut,
                  label: l10n?.signOut ?? 'Sign Out',
                  value: l10n?.signOutOfAccount ?? 'Sign out of your account',
                  isDark: isDark,
                  onTap: _confirmSignOut,
                ),

                const SizedBox(height: 32),

                // Danger zone
                Text(
                  l10n?.dangerZone ?? 'Danger Zone',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing12),

                _ProfileItem(
                  icon: LucideIcons.trash2,
                  label: l10n?.deleteAccount ?? 'Delete Account',
                  value: l10n?.permanentlyDelete ?? 'Permanently delete your account and all data',
                  isDark: isDark,
                  onTap: _confirmDeleteAccount,
                  isDestructive: true,
                ),
              ],
            ),
    );
  }
}

class _NotSignedInView extends StatelessWidget {
  final bool isDark;

  const _NotSignedInView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.userCircle,
            size: 80,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Not signed in',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to manage your profile',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String? name;
  final bool isDark;

  const _DefaultAvatar({this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';

    return Center(
      child: Text(
        initial,
        style: AppTypography.h1.copyWith(
          color: AppColors.primary,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                IconTheme(
                  data: IconThemeData(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatelessWidget {
  final TextEditingController controller;

  const _EditNameDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      title: Text(
        'Edit Display Name',
        style: AppTypography.h4.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter your name',
          filled: true,
          fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            borderSide: BorderSide.none,
          ),
        ),
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text(
            'Save',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// Dialog for changing password
class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Parse error message to show user-friendly message
        final errorMessage = e.toString().toLowerCase();
        String userMessage;

        if (errorMessage.contains('same_password') ||
            errorMessage.contains('different from the old password') ||
            errorMessage.contains('should be different')) {
          userMessage = 'New password must be different from your current password.';
        } else if (errorMessage.contains('weak') || errorMessage.contains('strength')) {
          userMessage = 'Password is too weak. Please choose a stronger password.';
        } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
          userMessage = 'Network error. Please check your connection and try again.';
        } else {
          userMessage = 'Failed to change password. Please try again.';
        }

        AnimatedSnackbar.showError(context, userMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      title: Text(
        'Change Password',
        style: AppTypography.h4.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm new password',
                prefixIcon: const Icon(LucideIcons.keyRound),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update Password'),
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
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      title: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          Text(
            'Final Confirmation',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
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
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
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
