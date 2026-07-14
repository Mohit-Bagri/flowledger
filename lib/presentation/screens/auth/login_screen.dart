import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/animated_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final error = ref.read(authProvider).errorMessage;
        if (error != null) {
          AnimatedSnackbar.showError(context, error);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).signInWithGoogle();

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final error = ref.read(authProvider).errorMessage;
        if (error != null && !error.contains('cancelled')) {
          AnimatedSnackbar.showError(context, error);
        }
      }
    }
  }

  void _goToSignUp() {
    context.push('/signup');
  }

  void _goToForgotPassword() {
    context.push('/forgot-password');
  }

  void _skipSignIn() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo and title
              _buildHeader(isDark, l10n),

              const SizedBox(height: 48),

              // Login form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildEmailField(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildPasswordField(isDark, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _goToForgotPassword,
                  child: Text(
                    l10n?.forgotPasswordQuestion ?? 'Forgot Password?',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // Hint for Google users
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n?.signedUpWithGoogleHint ?? 'Signed up with Google? Skip the form and use the Google button below.',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sign in button
              _buildSignInButton(isDark, l10n),

              const SizedBox(height: 24),

              // Divider
              _buildDivider(isDark, l10n),

              const SizedBox(height: 24),

              // Google sign in
              _buildGoogleSignInButton(isDark, l10n),

              const SizedBox(height: 32),

              // Sign up link
              _buildSignUpLink(isDark, l10n),

              const SizedBox(height: 24),

              // Skip button
              _buildSkipButton(isDark, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations? l10n) {
    return Column(
      children: [
        // App icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.wallet,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n?.welcomeBackTitle ?? 'Welcome Back',
          style: AppTypography.h1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.signInToSyncDataDesc ?? 'Sign in to sync your data across devices',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isDark, AppLocalizations? l10n) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: l10n?.emailLabel ?? 'Email',
        hintText: l10n?.enterYourEmailHint ?? 'Enter your email',
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
          return l10n?.pleaseEnterYourEmail ?? 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
          return l10n?.pleaseEnterValidEmail ?? 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isDark, AppLocalizations? l10n) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signInWithEmail(),
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: l10n?.passwordLabel ?? 'Password',
        hintText: l10n?.enterYourPasswordHint ?? 'Enter your password',
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
          return l10n?.pleaseEnterYourPassword ?? 'Please enter your password';
        }
        if (value.length < 6) {
          return l10n?.passwordMin6Chars ?? 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton(bool isDark, AppLocalizations? l10n) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithEmail,
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
                l10n?.signIn ?? 'Sign In',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(bool isDark, AppLocalizations? l10n) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n?.orContinueWithText ?? 'or continue with',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(bool isDark, AppLocalizations? l10n) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleLogo(),
            const SizedBox(width: 12),
            Text(
              l10n?.continueWithGoogle ?? 'Continue with Google',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SvgPicture.asset(
      'assets/icons/google_logo.svg',
      width: 24,
      height: 24,
    );
  }

  Widget _buildSignUpLink(bool isDark, AppLocalizations? l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n?.dontHaveAccountQuestion ?? "Don't have an account? ",
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        GestureDetector(
          onTap: _goToSignUp,
          child: Text(
            l10n?.signUp ?? 'Sign Up',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(bool isDark, AppLocalizations? l10n) {
    return TextButton(
      onPressed: _skipSignIn,
      child: Text(
        l10n?.skipForNow ?? 'Skip for now',
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}
