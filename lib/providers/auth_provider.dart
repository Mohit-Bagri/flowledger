import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/revenue_cat_service.dart';

/// Auth state enum
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;

  AuthNotifier(this._supabaseService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Check current auth state
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Listen to auth changes
    _supabaseService.authStateChanges.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        // Tie RevenueCat identity to this Supabase user so purchases
        // sync across devices logged into the same account
        RevenueCatService.instance.login(user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        RevenueCatService.instance.logout();
      } else if (event == AuthChangeEvent.tokenRefreshed && user != null) {
        state = state.copyWith(user: user);
      }
    });
  }

  /// Sign up with email
  /// Returns a tuple-like result: (success, isReactivated)
  /// - success: true if signup/reactivation succeeded
  /// - For reactivated users, they're already signed in and should go to home
  /// - For new users, they need to verify email first
  Future<(bool success, bool isReactivated)> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    DateTime? birthDate,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _supabaseService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      birthDate: birthDate,
    );

    if (result.success) {
      // Check if this was a reactivation (user is already authenticated)
      final isReactivated = result.user != null && _supabaseService.isAuthenticated;

      if (isReactivated) {
        // Reactivated user - they're already signed in
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
        );
        return (true, true);
      } else {
        // New user - needs to verify email
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: result.message,
        );
        return (true, false);
      }
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: result.message,
      );
      return (false, false);
    }
  }

  /// Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _supabaseService.signInWithEmail(
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: result.message,
      );
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle({bool isSignUp = false}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _supabaseService.signInWithGoogle(isSignUp: isSignUp);

    if (result.success && result.user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: result.message,
      );
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _supabaseService.sendPasswordResetEmail(email);

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: result.message,
    );

    return result.success;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabaseService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(SupabaseService.instance);
});

/// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final userDisplayNameProvider = Provider<String?>((ref) {
  return SupabaseService.instance.userDisplayName;
});

final userEmailProvider = Provider<String?>((ref) {
  return SupabaseService.instance.userEmail;
});

final userAvatarUrlProvider = Provider<String?>((ref) {
  return SupabaseService.instance.userAvatarUrl;
});
