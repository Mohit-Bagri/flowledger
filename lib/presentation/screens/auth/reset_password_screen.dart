import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/app_router.dart';
import '../../../services/supabase_service.dart';
import '../../widgets/common/animated_snackbar.dart';

/// Screen shown when user clicks password reset link from email
/// Handles the deep link and allows user to set a new password
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword(AppLocalizations? l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use Supabase to update the password
      // The session should already be set from the deep link
      await SupabaseService.instance.client.auth.updateUser(
        supabase_flutter.UserAttributes(password: _passwordController.text),
      );

      setState(() {
        _isLoading = false;
        _resetSuccess = true;
      });

      if (mounted) {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.passwordUpdatedSuccessfully ?? 'Password updated successfully!',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        // Check for specific error messages
        final errorMessage = e.toString().toLowerCase();
        String userMessage;

        if (errorMessage.contains('same_password') ||
            errorMessage.contains('different from the old password') ||
            errorMessage.contains('should be different')) {
          userMessage = l10n?.passwordMustBeDifferent ?? 'New password must be different from your current password. Please choose a different password.';
        } else if (errorMessage.contains('expired') || errorMessage.contains('invalid')) {
          userMessage = l10n?.resetLinkExpired ?? 'This reset link has expired. Please request a new password reset link.';
        } else {
          userMessage = l10n?.failedToResetPassword ?? 'Failed to reset password. The link may have expired. Please try again.';
        }

        AnimatedSnackbar.showError(context, userMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.go(AppRoutes.login),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: _resetSuccess ? _buildSuccessView(isDark, l10n) : _buildFormView(isDark, l10n),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                LucideIcons.keyRound,
                color: AppColors.primary,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Header
          Text(
            l10n?.createNewPassword ?? 'Create New Password',
            style: AppTypography.h1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.newPasswordMustBeDifferent ?? 'Your new password must be different from previously used passwords.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                // New Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n?.newPassword ?? 'New Password',
                    hintText: l10n?.enterNewPassword ?? 'Enter new password',
                    prefixIcon: Icon(
                      LucideIcons.lock,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.pleaseEnterPassword ?? 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return l10n?.passwordMinLength ?? 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _resetPassword(l10n),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n?.confirmPassword ?? 'Confirm Password',
                    hintText: l10n?.confirmNewPassword ?? 'Confirm new password',
                    prefixIcon: Icon(
                      LucideIcons.keyRound,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.pleaseConfirmPassword ?? 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return l10n?.passwordsDoNotMatch ?? 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Reset Password button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _resetPassword(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n?.resetPassword ?? 'Reset Password',
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
  }

  Widget _buildSuccessView(bool isDark, AppLocalizations? l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            color: AppColors.success,
            size: 50,
          ),
        ),

        const SizedBox(height: 32),

        Text(
          l10n?.passwordResetSuccessTitle ?? 'Password Reset!',
          style: AppTypography.h2.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          l10n?.passwordResetSuccessMessage ?? 'Your password has been successfully reset.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),

        const SizedBox(height: 48),

        // Continue to login button
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n?.continueToSignIn ?? 'Continue to Sign In',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
