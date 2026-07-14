import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/animated_snackbar.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  DateTime? _birthDate;
  String? _birthDateError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100, 1, 1);
    final maxDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: minDate,
      lastDate: maxDate,
      helpText: l10n?.selectYourBirthDate ?? 'Select your birth date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.darkCard,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        final age = _calculateAge(picked);
        if (age < 12) {
          _birthDateError = l10n?.mustBe12YearsOld ?? 'You must be at least 12 years old to use this app';
        } else {
          _birthDateError = null;
        }
      });
    }
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    // Validate birthdate
    if (_birthDate == null) {
      setState(() {
        _birthDateError = l10n?.pleaseSelectBirthDate ?? 'Please select your birth date';
      });
      return;
    }

    final age = _calculateAge(_birthDate!);
    if (age < 12) {
      setState(() {
        _birthDateError = l10n?.mustBe12YearsOld ?? 'You must be at least 12 years old to use this app';
      });
      AnimatedSnackbar.showError(
        context,
        l10n?.mustBe12YearsOldMessage ?? 'You must be at least 12 years old to use FlowLedger',
      );
      return;
    }

    setState(() => _isLoading = true);

    final (success, isReactivated) = await ref.read(authProvider.notifier).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          birthDate: _birthDate,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (isReactivated) {
          // Reactivated user - they're already signed in, go to home
          AnimatedSnackbar.showSuccess(context, l10n?.welcomeBackMessage ?? 'Welcome back! Your account has been reactivated.');
          context.go('/home');
        } else {
          // New user - show verification dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              final dialogL10n = AppLocalizations.of(dialogContext);
              return AlertDialog(
                title: Text(dialogL10n?.accountCreatedTitle ?? 'Account Created!'),
                content: Text(
                  dialogL10n?.verificationEmailSentDesc ??
                  'We\'ve sent a verification email to your inbox.\n\n'
                  '1. Check your email\n'
                  '2. Click "Confirm your mail"\n'
                  '3. Return here and sign in with your credentials\n\n'
                  'The verification link may open the app or a web page - '
                  'either way, your email will be verified!',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.pop(); // Go back to login
                    },
                    child: Text(dialogL10n?.gotItGoToSignInBtn ?? 'Got it, go to Sign In'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        final error = ref.read(authProvider).errorMessage;
        if (error != null) {
          // Check if it's a deleted user trying to re-register
          if (error.toLowerCase().contains('previous account was deleted')) {
            _showDeletedUserDialog();
          }
          // Check if it's a "user already exists" error
          else if (error.toLowerCase().contains('already exists') ||
              error.toLowerCase().contains('already registered')) {
            _showUserExistsDialog();
          } else {
            AnimatedSnackbar.showError(context, error);
          }
        }
      }
    }
  }

  void _showDeletedUserDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n?.accountPreviouslyDeleted ?? 'Account Previously Deleted',
          style: AppTypography.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          l10n?.reactivateAccountDesc ??
          'Your previous account was deleted but can be reactivated.\n\n'
          'To reactivate your account:\n'
          '1. Go to Sign In\n'
          '2. Tap "Forgot Password"\n'
          '3. Reset your password\n'
          '4. Sign in with the new password\n\n'
          'Your account will be automatically reactivated when you sign in.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop(); // Go back to login screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n?.goToSignIn ?? 'Go to Sign In'),
          ),
        ],
      ),
    );
  }

  void _showUserExistsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n?.accountAlreadyExists ?? 'Account Already Exists',
          style: AppTypography.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          l10n?.accountExistsGoogleHint ??
          'An account with this email already exists.\n\n'
          'If you signed up with Google before, please use "Continue with Google" to sign in.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop(); // Go back to login screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n?.goToSignIn ?? 'Go to Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    // Pass isSignUp: true to allow reactivation of deleted accounts
    final success = await ref.read(authProvider.notifier).signInWithGoogle(isSignUp: true);

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

  void _goToLogin() {
    context.pop();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(isDark, l10n),

              const SizedBox(height: 32),

              // Sign up form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildNameField(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildBirthDateField(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildEmailField(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildPasswordField(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(isDark, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sign up button
              _buildSignUpButton(isDark, l10n),

              const SizedBox(height: 24),

              // Divider
              _buildDivider(isDark, l10n),

              const SizedBox(height: 24),

              // Google sign up
              _buildGoogleSignUpButton(isDark, l10n),

              const SizedBox(height: 32),

              // Login link
              _buildLoginLink(isDark, l10n),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.createAccountTitle ?? 'Create Account',
          style: AppTypography.h1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.signUpToBackupDesc ?? 'Sign up to backup and sync your data across all your devices',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(bool isDark, AppLocalizations? l10n) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: l10n?.nameLabel ?? 'Name',
        hintText: l10n?.enterYourNameHint ?? 'Enter your name',
        prefixIcon: Icon(
          LucideIcons.user,
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
          return l10n?.pleaseEnterName ?? 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildBirthDateField(bool isDark, AppLocalizations? l10n) {
    final hasError = _birthDateError != null;
    final age = _birthDate != null ? _calculateAge(_birthDate!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _selectBirthDate,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: hasError ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.cake,
                  color: hasError
                      ? AppColors.error
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.birthDateLabel ?? 'Birth Date',
                        style: AppTypography.caption.copyWith(
                          color: hasError
                              ? AppColors.error
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _birthDate != null
                            ? '${DateFormat('dd MMM yyyy').format(_birthDate!)} (${l10n?.yearsOld(age!) ?? '$age years old'})'
                            : l10n?.selectYourBirthDateHint ?? 'Select your birth date',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _birthDate != null
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                              : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.calendar,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _birthDateError!,
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
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
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: l10n?.passwordLabel ?? 'Password',
        hintText: l10n?.createPasswordHint ?? 'Create a password',
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
        helperText: l10n?.atLeast6Characters ?? 'At least 6 characters',
        helperStyle: AppTypography.caption.copyWith(
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n?.pleaseEnterAPassword ?? 'Please enter a password';
        }
        if (value.length < 6) {
          return l10n?.passwordMustBe6Chars ?? 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(bool isDark, AppLocalizations? l10n) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signUp(),
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: l10n?.confirmPasswordLabel ?? 'Confirm Password',
        hintText: l10n?.reenterPasswordHint ?? 'Re-enter your password',
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
          return l10n?.pleaseConfirmYourPassword ?? 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return l10n?.passwordsDoNotMatch ?? 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton(bool isDark, AppLocalizations? l10n) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
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
                l10n?.createAccount ?? 'Create Account',
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

  Widget _buildGoogleSignUpButton(bool isDark, AppLocalizations? l10n) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signUpWithGoogle,
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

  Widget _buildLoginLink(bool isDark, AppLocalizations? l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n?.alreadyHaveAccountQuestion ?? 'Already have an account? ',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        GestureDetector(
          onTap: _goToLogin,
          child: Text(
            l10n?.signIn ?? 'Sign In',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
