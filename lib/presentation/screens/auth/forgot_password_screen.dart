import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/animated_snackbar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail(AppLocalizations? l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).sendPasswordResetEmail(
          _emailController.text.trim(),
        );

    setState(() {
      _isLoading = false;
      _emailSent = success;
    });

    if (mounted) {
      if (success) {
        AnimatedSnackbar.showSuccess(
          context,
          l10n?.passwordResetEmailSent ?? 'Password reset email sent!',
        );
      } else {
        final error = ref.read(authProvider).errorMessage;
        if (error != null) {
          AnimatedSnackbar.showError(context, error);
        }
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
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: _emailSent ? _buildSuccessView(isDark, l10n) : _buildFormView(isDark, l10n),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
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

        const SizedBox(height: 32),

        // Header
        Text(
          l10n?.forgotPassword ?? 'Forgot Password?',
          style: AppTypography.h1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n?.forgotPasswordDescription ?? "No worries! Enter your email and we'll send you a link to reset your password.",
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),

        const SizedBox(height: 16),

        // Google account warning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.info,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.googlePasswordResetWarning ?? 'Signed up with Google? Password reset won\'t work. Use "Continue with Google" on the login page instead.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Email field
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _sendResetEmail(l10n),
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              labelText: l10n?.email ?? 'Email',
              hintText: l10n?.enterYourEmail ?? 'Enter your email',
              prefixIcon: Icon(
                LucideIcons.mail,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
              if (value == null || value.trim().isEmpty) {
                return l10n?.pleaseEnterEmail ?? 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return l10n?.pleaseEnterValidEmail ?? 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 32),

        // Send button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _sendResetEmail(l10n),
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
                    l10n?.sendResetLink ?? 'Send Reset Link',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Back to login
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l10n?.backToSignIn ?? 'Back to Sign In',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
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
            LucideIcons.mailCheck,
            color: AppColors.success,
            size: 50,
          ),
        ),

        const SizedBox(height: 32),

        Text(
          l10n?.checkYourEmail ?? 'Check Your Email',
          style: AppTypography.h2.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          '${l10n?.weSentPasswordResetLink ?? 'We sent a password reset link to'}\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),

        const SizedBox(height: 32),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              _buildInstructionItem(isDark, '1', l10n?.checkEmailInbox ?? 'Check your email inbox'),
              const SizedBox(height: 12),
              _buildInstructionItem(isDark, '2', l10n?.clickResetLink ?? 'Click the reset link'),
              const SizedBox(height: 12),
              _buildInstructionItem(isDark, '3', l10n?.createNewPassword ?? 'Create your new password'),
              const SizedBox(height: 12),
              _buildInstructionItem(isDark, '4', l10n?.signInWithNewPassword ?? 'Sign in with new password'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Note about reset location
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.smartphone,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.resetLinkDeviceNote ?? 'Open the email on a device with FlowLedger installed. The reset link will open in the app.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Back to login button
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n?.backToSignIn ?? 'Back to Sign In',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resend link
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            l10n?.didntReceiveEmailTryAgain ?? "Didn't receive the email? Try again",
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(bool isDark, String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
