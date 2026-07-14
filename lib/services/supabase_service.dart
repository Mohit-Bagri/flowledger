import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_service.dart';

/// Key for storing locally blocked (deleted) user emails
const String _deletedUsersKey = 'deleted_user_emails';

/// Supabase configuration
class SupabaseConfig {
  // Replace these with your own Supabase project credentials.
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Google OAuth Client IDs — replace with your own from Google Cloud Console.
  static const String webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  static const String iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
  static const String androidClientId = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
}

/// Service for handling Supabase authentication and client management
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Handle deep links for password reset and email confirmation
        pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
      ),
    );
    _instance = SupabaseService._();
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    DateTime? birthDate,
  }) async {
    try {
      // Build user metadata
      final Map<String, dynamic> userData = {};
      if (displayName != null) {
        userData['display_name'] = displayName;
      }
      if (birthDate != null) {
        userData['birth_date'] = birthDate.toIso8601String().split('T')[0]; // YYYY-MM-DD format
      }

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData.isNotEmpty ? userData : null,
        emailRedirectTo: 'com.flowledger.flowledger://login-callback',
      );

      if (response.user != null) {
        // Check if this is a "fake success" - user already exists but Supabase returned user object
        // This happens when email is already registered. The user object will have empty identities.
        final identities = response.user!.identities;
        if (identities == null || identities.isEmpty) {
          debugPrint('signUpWithEmail: User already exists (empty identities), checking profile status');
          // User already exists - check if they were deleted
          final profileStatus = await _getProfileStatus(response.user!.id);
          if (profileStatus == 'deleted') {
            // Deleted user trying to re-register - they need to use forgot password
            return AuthResult.failure(
              'Your previous account was deleted. To reactivate it, please use "Forgot Password" on the Sign In screen to reset your password, then sign in.',
            );
          } else {
            // Active user trying to sign up again - tell them to sign in
            return AuthResult.failure(
              'An account with this email already exists. Please sign in instead.',
            );
          }
        }

        // Check if this user had a deleted profile and reactivate it
        final profileStatus = await _getProfileStatus(response.user!.id);
        if (profileStatus == 'deleted') {
          debugPrint('signUpWithEmail: Reactivating deleted profile for returning user');
          await _reactivateProfile(response.user!.id, displayName, null);
          if (response.user!.email != null) {
            await _removeFromDeletedUsersList(response.user!.email!);
          }
          return AuthResult.success(
            user: response.user,
            message: 'Welcome back! Your account has been reactivated. Please check your email to verify.',
          );
        }

        return AuthResult.success(
          user: response.user,
          message: 'Account created! Please check your email to verify.',
        );
      } else {
        return AuthResult.failure('Sign up failed. Please try again.');
      }
    } on AuthException catch (e) {
      // Check if the error is "user already registered" - they may be a deleted user trying to re-register
      final message = e.message.toLowerCase();
      if (message.contains('user already registered')) {
        debugPrint('signUpWithEmail: User already exists, checking if deleted user trying to re-register');

        // First, check if this is a deleted user by looking at the profiles table directly
        // This works because profiles table is readable by anyone (RLS allows select for own rows,
        // but we can check by email which might be exposed)
        try {
          final profileByEmail = await client
              .from('profiles')
              .select('id, status, email')
              .eq('email', email.toLowerCase().trim())
              .maybeSingle();

          if (profileByEmail != null && profileByEmail['status'] == 'deleted') {
            debugPrint('signUpWithEmail: Found deleted profile by email, attempting password-based reactivation');

            // Try to sign in with provided password
            try {
              final signInResponse = await client.auth.signInWithPassword(
                email: email,
                password: password,
              );

              if (signInResponse.user != null) {
                // Reactivate the deleted account
                debugPrint('signUpWithEmail: Sign in succeeded, reactivating deleted account');
                final emailUsername = signInResponse.user!.email?.split('@').first ?? 'User';
                final reactivated = await _reactivateProfile(
                  signInResponse.user!.id,
                  displayName ?? emailUsername,
                  null,
                );
                if (reactivated) {
                  if (signInResponse.user!.email != null) {
                    await _removeFromDeletedUsersList(signInResponse.user!.email!);
                  }
                  return AuthResult.success(
                    user: signInResponse.user,
                    message: 'Welcome back! Your account has been reactivated.',
                  );
                }
              }
            } catch (signInError) {
              debugPrint('signUpWithEmail: Sign in failed for deleted user: $signInError');
              // Password was wrong - they need to use forgot password
              return AuthResult.failure(
                'Your previous account was deleted. To reactivate it, please use "Forgot Password" on the Sign In screen to reset your password, then sign in.',
              );
            }
          }
        } catch (profileCheckError) {
          debugPrint('signUpWithEmail: Could not check profile by email: $profileCheckError');
        }

        // If we get here, try the original sign-in approach
        try {
          final signInResponse = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (signInResponse.user != null) {
            // Check if profile is deleted
            final profileStatus = await _getProfileStatus(signInResponse.user!.id);
            debugPrint('signUpWithEmail: Existing user profile status = $profileStatus');

            if (profileStatus == 'deleted') {
              // This is a deleted user trying to re-register - reactivate their account
              debugPrint('signUpWithEmail: Reactivating deleted account');
              final emailUsername = signInResponse.user!.email?.split('@').first ?? 'User';
              final reactivated = await _reactivateProfile(
                signInResponse.user!.id,
                displayName ?? emailUsername,
                null,
              );
              if (reactivated) {
                if (signInResponse.user!.email != null) {
                  await _removeFromDeletedUsersList(signInResponse.user!.email!);
                }
                return AuthResult.success(
                  user: signInResponse.user,
                  message: 'Welcome back! Your account has been reactivated.',
                );
              }
            }

            // Profile is active - user already has an account
            await client.auth.signOut();
            return AuthResult.failure(
              'An account with this email already exists. Please sign in instead.',
            );
          }
        } catch (signInError) {
          debugPrint('signUpWithEmail: Sign in check failed: $signInError');
          // Sign in failed (wrong password) - return helpful message
        }

        return AuthResult.failure(
          'An account with this email already exists. Please sign in instead, or use "Forgot Password" if you don\'t remember your password.',
        );
      }
      return AuthResult.failure(_parseAuthError(e));
    } catch (e) {
      debugPrint('Sign up error: $e');
      return AuthResult.failure('An unexpected error occurred.');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('signInWithEmail: Starting for $email');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('signInWithEmail: Got user ${response.user!.id}');

        // Check if profile exists and its status
        final profileStatus = await _getProfileStatus(response.user!.id);
        debugPrint('signInWithEmail: Profile status = $profileStatus');

        if (profileStatus == 'deleted') {
          debugPrint('signInWithEmail: Profile is deleted, blocking sign-in');
          // Profile was deleted - sign out and tell user to sign up again
          await client.auth.signOut();
          return AuthResult.failure(
            'This account was deleted. Please sign up again with the same email to create a new account.',
          );
        }

        return AuthResult.success(
          user: response.user,
          message: 'Welcome back!',
        );
      } else {
        return AuthResult.failure('Sign in failed. Please try again.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    } catch (e) {
      debugPrint('Sign in error: $e');
      return AuthResult.failure('An unexpected error occurred.');
    }
  }

  /// Sign in with Google
  /// If [isSignUp] is true, deleted accounts will be reactivated (for sign-up flow)
  /// If [isSignUp] is false (default), deleted accounts will be blocked (for sign-in flow)
  Future<AuthResult> signInWithGoogle({bool isSignUp = false}) async {
    try {
      // Use platform-specific client ID
      // Android: don't pass clientId, it uses the one from google-services.json or SHA-1 config
      // iOS: pass the iOS client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? SupabaseConfig.iosClientId : null,
        serverClientId: SupabaseConfig.webClientId,
      );

      debugPrint('Google sign in - starting');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign in - cancelled by user');
        return AuthResult.failure('Google sign in cancelled.');
      }

      debugPrint('Google sign in - got user: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('Google sign in - no idToken');
        return AuthResult.failure('Could not get Google credentials.');
      }

      debugPrint('Google sign in - authenticating with Supabase');
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('Google sign in - Supabase response: user=${response.user?.email}, session=${response.session != null}');

      if (response.user != null) {
        // Check if profile exists and its status
        try {
          final profileStatus = await _getProfileStatus(response.user!.id);
          debugPrint('Google sign in - profile status: $profileStatus');

          if (profileStatus == 'deleted') {
            if (isSignUp) {
              // Sign-up flow: reactivate the deleted account
              debugPrint('Google sign in (signup) - profile is deleted, reactivating account');
              final displayName = googleUser.displayName ?? googleUser.email.split('@').first;
              final avatarUrl = googleUser.photoUrl;

              final reactivated = await _reactivateProfile(
                response.user!.id,
                displayName,
                avatarUrl,
              );
              if (reactivated) {
                if (response.user!.email != null) {
                  await _removeFromDeletedUsersList(response.user!.email!);
                }
                debugPrint('Google sign in (signup) - account reactivated successfully');
                return AuthResult.success(
                  user: response.user,
                  message: 'Welcome back! Your account has been reactivated.',
                );
              }
            } else {
              // Sign-in flow: block and tell user to sign up
              debugPrint('Google sign in - profile is deleted, blocking sign-in');
              await client.auth.signOut();
              await googleSignIn.signOut();
              return AuthResult.failure(
                'This account was deleted. Please sign up again with Google to create a new account.',
              );
            }
          }
        } catch (e) {
          debugPrint('Google sign in - profile check failed (non-critical): $e');
          // Continue with sign-in even if profile check fails
        }

        debugPrint('Google sign in - SUCCESS');
        return AuthResult.success(
          user: response.user,
          message: 'Welcome!',
        );
      } else {
        debugPrint('Google sign in - no user in response');
        return AuthResult.failure('Google sign in failed.');
      }
    } on AuthException catch (e) {
      debugPrint('Google sign in - AuthException: ${e.message}');
      return AuthResult.failure(_parseAuthError(e));
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return AuthResult.failure('Google sign in failed. Please try again.');
    }
  }

  /// Check if an email exists in our profiles table
  Future<bool> _doesEmailExist(String email) async {
    try {
      final response = await client
          .from('profiles')
          .select('id')
          .ilike('email', email.toLowerCase().trim())
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if email exists: $e');
      // If we can't check, assume it exists and let Supabase handle it
      return true;
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      final trimmedEmail = email.toLowerCase().trim();

      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        return AuthResult.failure('Please enter a valid email address.');
      }

      // Check if email exists in our system first
      final emailExists = await _doesEmailExist(trimmedEmail);
      if (!emailExists) {
        return AuthResult.failure(
          'No account found with this email address. Please check the email or create a new account.',
        );
      }

      // Send password reset
      await client.auth.resetPasswordForEmail(
        trimmedEmail,
        redirectTo: 'com.flowledger.flowledger://reset-callback',
      );
      return AuthResult.success(
        message: 'Password reset email sent! Please check your inbox.',
      );
    } on AuthException catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    } catch (e) {
      debugPrint('Password reset error: $e');
      return AuthResult.failure('Failed to send reset email. Please try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Clear all local data before signing out (prevents data from previous user showing)
      await SyncService.instance.clearAllLocalData();

      // Clear sync state before signing out (so next user gets fresh state)
      await SyncService.instance.clearSyncState();

      // Sign out from Google if signed in
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Delete account - marks profile as deleted and removes all user data
  Future<AuthResult> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.failure('Please sign in to delete your account.');
    }

    // Store email before deletion for local blocklist
    final userEmail = user.email;

    try {
      // Step 1: Mark profile as deleted in database (this is the most important step)
      try {
        await client
            .from('profiles')
            .update({
              'status': 'deleted',
              'deleted_at': DateTime.now().toIso8601String(),
              'full_name': '[Deleted User]',
              'avatar_url': null,
            })
            .eq('id', user.id);
        debugPrint('Profile marked as deleted for user: ${user.id}');
      } catch (e) {
        debugPrint('Error marking profile as deleted: $e');
        // Continue anyway - we still want to try other cleanup steps
      }

      // Step 2: Add email to local blocklist (prevents re-login on this device)
      if (userEmail != null) {
        await _addToDeletedUsersList(userEmail);
      }

      // Step 3: Delete all cloud data for this user
      try {
        await SyncService.instance.deleteCloudData();
        debugPrint('Cloud data deleted for user: ${user.id}');
      } catch (e) {
        debugPrint('Error deleting cloud data: $e');
      }

      // Step 4: Try to call Edge Function for complete auth deletion (optional)
      final session = client.auth.currentSession;
      if (session != null) {
        try {
          final response = await client.functions.invoke(
            'delete-user',
            method: HttpMethod.post,
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
            },
          );

          if (response.status == 200) {
            debugPrint('Edge function delete-user succeeded');
          } else {
            debugPrint('Edge function delete-user returned: ${response.status}');
          }
        } catch (e) {
          debugPrint('Edge function not available or failed: $e');
          // This is okay - the profile is already marked deleted
        }
      }

      // Step 5: Clear local state and sign out
      await SyncService.instance.clearSyncState();
      await signOut();

      return AuthResult.success(message: 'Account and all data deleted successfully.');
    } catch (e) {
      debugPrint('Delete account error: $e');
      // Fallback to soft delete method
      return await _softDeleteAccount();
    }
  }

  /// Soft delete account as fallback when Edge Function fails
  /// Updates the profile status to 'deleted' in the database
  Future<AuthResult> _softDeleteAccount() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.failure('Please sign in to delete your account.');
    }

    // Store email before deletion for local blocklist
    final userEmail = user.email;

    try {
      // First, try the RPC function if it exists
      try {
        final response = await client.rpc('soft_delete_user_profile');
        if (response == true) {
          // Add to local blocklist
          if (userEmail != null) {
            await _addToDeletedUsersList(userEmail);
          }
          await SyncService.instance.clearSyncState();
          await signOut();
          return AuthResult.success(message: 'Account data deleted successfully.');
        }
      } catch (e) {
        debugPrint('RPC soft_delete_user_profile not available: $e');
      }

      // Direct database update: Set profile status to 'deleted'
      await client
          .from('profiles')
          .update({
            'status': 'deleted',
            'deleted_at': DateTime.now().toIso8601String(),
            'full_name': '[Deleted User]',
            'avatar_url': null,
          })
          .eq('id', user.id);

      debugPrint('Profile status set to deleted for user: ${user.id}');

      // Add to local blocklist
      if (userEmail != null) {
        await _addToDeletedUsersList(userEmail);
      }

      // Clear all cloud data for this user
      await SyncService.instance.deleteCloudData();

      // Clear local sync state and sign out
      await SyncService.instance.clearSyncState();
      await signOut();

      return AuthResult.success(message: 'Account and all data deleted successfully.');
    } catch (e) {
      debugPrint('Soft delete failed: $e');

      // Last resort - add to blocklist, clear local sync data and sign out
      try {
        if (userEmail != null) {
          await _addToDeletedUsersList(userEmail);
        }
        await SyncService.instance.clearSyncState();
        await signOut();
        return AuthResult.success(
          message: 'Signed out. Please contact support to complete account deletion.',
        );
      } catch (_) {}
    }

    return AuthResult.failure('Failed to delete account. Please contact support.');
  }

  /// Check if user profile is active
  Future<bool> isProfileActive() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await client
          .from('profiles')
          .select('status')
          .eq('id', user.id)
          .single();

      return response['status'] == 'active';
    } catch (e) {
      debugPrint('Error checking profile status: $e');
      return false;
    }
  }

  /// Check profile status during sign-in, returns error message if account is deleted
  /// Returns null if profile is active/valid
  Future<String?> _checkProfileStatus(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // Profile doesn't exist yet - this is fine for new users
        return null;
      }

      final status = response['status'] as String?;
      if (status == 'deleted') {
        return 'This account has been deleted. Please create a new account.';
      }

      return null; // Profile is active
    } catch (e) {
      debugPrint('Error checking profile status: $e');
      return null; // Allow sign-in if we can't check status
    }
  }

  /// Add email to local blocklist of deleted accounts
  Future<void> _addToDeletedUsersList(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedUsers = prefs.getStringList(_deletedUsersKey) ?? [];
    final normalizedEmail = email.toLowerCase().trim();
    if (!deletedUsers.contains(normalizedEmail)) {
      deletedUsers.add(normalizedEmail);
      await prefs.setStringList(_deletedUsersKey, deletedUsers);
      debugPrint('Added $normalizedEmail to local deleted users list');
    }
  }

  /// Check if email is in local blocklist of deleted accounts
  Future<bool> _isEmailInDeletedList(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedUsers = prefs.getStringList(_deletedUsersKey) ?? [];
    final normalizedEmail = email.toLowerCase().trim();
    return deletedUsers.contains(normalizedEmail);
  }

  /// Check if current user's email is blocked locally
  Future<bool> _isCurrentUserBlocked() async {
    final user = currentUser;
    if (user?.email == null) return false;
    return _isEmailInDeletedList(user!.email!);
  }

  /// Remove email from local blocklist (used when re-registering)
  Future<void> _removeFromDeletedUsersList(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedUsers = prefs.getStringList(_deletedUsersKey) ?? [];
    final normalizedEmail = email.toLowerCase().trim();
    if (deletedUsers.contains(normalizedEmail)) {
      deletedUsers.remove(normalizedEmail);
      await prefs.setStringList(_deletedUsersKey, deletedUsers);
      debugPrint('Removed $normalizedEmail from local deleted users list');
    }
  }

  /// Get profile status from database (returns null if profile doesn't exist or status column missing)
  Future<String?> _getProfileStatus(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null; // Profile doesn't exist
      }

      // Check if status key exists in response (column might not exist)
      if (!response.containsKey('status')) {
        return null; // Status column doesn't exist
      }

      return response['status'] as String?;
    } catch (e) {
      // This can happen if the 'status' column doesn't exist in the profiles table
      // In that case, we treat it as no status (allow sign-in)
      debugPrint('Error getting profile status (column may not exist): $e');
      return null;
    }
  }

  /// Reactivate a deleted profile for re-registration
  Future<bool> _reactivateProfile(String userId, String? displayName, String? avatarUrl) async {
    debugPrint('_reactivateProfile: userId=$userId, displayName=$displayName, avatarUrl=$avatarUrl');

    // Get the actual name - never use placeholder names
    String actualName = displayName ?? 'User';

    // If name looks like a placeholder, use email username instead
    if (actualName == 'User' || actualName == '[Deleted User]' || actualName.isEmpty) {
      final user = currentUser;
      if (user != null) {
        // Don't use metadata since it may contain "[Deleted User]"
        // Use email username as fallback
        actualName = user.email?.split('@').first ?? 'User';
        debugPrint('_reactivateProfile: Using email username as name: $actualName');
      }
    }

    try {
      // Update profile in profiles table
      await client
          .from('profiles')
          .update({
            'status': 'active',
            'deleted_at': null,
            'full_name': actualName,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      debugPrint('_reactivateProfile: Profile table updated for user: $userId with name: $actualName');

      // Also update auth user metadata to clear "[Deleted User]" name
      try {
        await client.auth.updateUser(
          UserAttributes(data: {
            'display_name': actualName,
            'full_name': actualName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          }),
        );
        debugPrint('_reactivateProfile: Auth user metadata updated with name: $actualName');
      } catch (e) {
        debugPrint('_reactivateProfile: Failed to update auth metadata (non-critical): $e');
      }

      debugPrint('_reactivateProfile: Profile reactivated successfully for user: $userId with name: $actualName');
      return true;
    } catch (e) {
      debugPrint('_reactivateProfile: Error updating profile: $e');
      // If update fails (maybe profile doesn't exist), try to create it
      try {
        await client.from('profiles').upsert({
          'id': userId,
          'status': 'active',
          'full_name': actualName,
          'avatar_url': avatarUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('_reactivateProfile: Profile created via upsert for user: $userId');
        return true;
      } catch (e2) {
        debugPrint('_reactivateProfile: Error creating profile via upsert: $e2');
        return false;
      }
    }
  }

  /// Get user display name
  String? get userDisplayName {
    final user = currentUser;
    if (user == null) return null;

    // Try to get from user metadata
    final metadata = user.userMetadata;
    if (metadata != null) {
      if (metadata['display_name'] != null) {
        return metadata['display_name'] as String;
      }
      if (metadata['full_name'] != null) {
        return metadata['full_name'] as String;
      }
      if (metadata['name'] != null) {
        return metadata['name'] as String;
      }
    }

    // Fall back to email
    return user.email?.split('@').first;
  }

  /// Get user email
  String? get userEmail => currentUser?.email;

  /// Get user avatar URL
  String? get userAvatarUrl {
    final metadata = currentUser?.userMetadata;
    if (metadata != null && metadata['avatar_url'] != null) {
      return metadata['avatar_url'] as String;
    }
    return null;
  }

  /// Check if user signed up with Google (OAuth only, no password)
  bool get isGoogleOnlyUser {
    final user = currentUser;
    if (user == null) return false;

    // Check if user has Google identity and no email identity
    final identities = user.identities;
    if (identities == null || identities.isEmpty) return false;

    // Look for Google provider
    final hasGoogleIdentity = identities.any((i) => i.provider == 'google');
    // Look for email provider (email/password signup)
    final hasEmailIdentity = identities.any((i) => i.provider == 'email');

    return hasGoogleIdentity && !hasEmailIdentity;
  }

  /// Check if user has Google identity linked
  bool get hasGoogleLinked {
    final user = currentUser;
    if (user == null) return false;

    final identities = user.identities;
    return identities?.any((i) => i.provider == 'google') ?? false;
  }

  /// Check if user has email/password identity
  bool get hasEmailIdentity {
    final user = currentUser;
    if (user == null) return false;

    final identities = user.identities;
    return identities?.any((i) => i.provider == 'email') ?? false;
  }

  /// Link Google account to existing user
  /// This allows users who signed up with email/password to also sign in with Google
  /// Uses native Google Sign-In only (no browser redirect)
  Future<AuthResult> linkGoogleIdentity() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.failure('Please sign in first.');
    }

    if (hasGoogleLinked) {
      return AuthResult.failure('Google account is already linked.');
    }

    final userEmail = user.email?.toLowerCase();
    if (userEmail == null || userEmail.isEmpty) {
      return AuthResult.failure('No email found on your account.');
    }

    GoogleSignIn? googleSignIn;
    try {
      // Use native Google Sign-In (same as sign-up/sign-in flow)
      googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? SupabaseConfig.iosClientId : null,
        serverClientId: SupabaseConfig.webClientId,
      );

      debugPrint('Link Google - starting native sign-in');
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Link Google - cancelled by user');
        return AuthResult.failure('Google sign in cancelled.');
      }

      debugPrint('Link Google - got user: ${googleUser.email}');

      // IMPORTANT: Verify the Google email matches the account email
      final googleEmail = googleUser.email.toLowerCase();
      if (googleEmail != userEmail) {
        debugPrint('Link Google - email mismatch: $googleEmail vs $userEmail');
        await googleSignIn.signOut();
        return AuthResult.failure(
          'The Google account email ($googleEmail) does not match your account email ($userEmail). Please use the same email address.',
        );
      }

      debugPrint('Link Google - email matches, getting credentials');

      // Get the ID token for Supabase
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('Link Google - no idToken');
        await googleSignIn.signOut();
        return AuthResult.failure('Could not get Google credentials.');
      }

      debugPrint('Link Google - signing in with Google to link identity');

      // Sign in with Google credentials - this will link the Google identity
      // to the existing user since the emails match and user is already signed in
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Sign out of Google Sign-In
      await googleSignIn.signOut();

      // Refresh session to get updated identities
      await client.auth.refreshSession();

      debugPrint('Link Google - checking if identity was linked');

      // Check if linking was successful
      if (hasGoogleLinked) {
        return AuthResult.success(
          user: currentUser,
          message: 'Google account linked successfully! You can now sign in with either method.',
        );
      } else {
        // Check if we got signed in as the same user
        if (response.user?.id == user.id) {
          return AuthResult.success(
            user: currentUser,
            message: 'Google account verified! You can now sign in with Google.',
          );
        }
        return AuthResult.failure('Failed to link Google account. Please try again.');
      }
    } on AuthException catch (e) {
      debugPrint('Link Google - AuthException: ${e.message}');
      await googleSignIn?.signOut();

      // Handle specific error cases
      final message = e.message.toLowerCase();
      if (message.contains('identity is already linked')) {
        return AuthResult.failure('This Google account is already linked to another user.');
      }
      if (message.contains('manual linking is disabled')) {
        return AuthResult.failure('Account linking is not enabled. Please contact support.');
      }
      if (message.contains('user already registered')) {
        // This actually means the Google account exists - check if it's the same user
        await client.auth.refreshSession();
        if (hasGoogleLinked) {
          return AuthResult.success(
            user: currentUser,
            message: 'Google account is now linked! You can sign in with either method.',
          );
        }
      }

      return AuthResult.failure(_parseAuthError(e));
    } catch (e) {
      debugPrint('Link Google error: $e');
      await googleSignIn?.signOut();
      return AuthResult.failure('Failed to link Google account. Please try again.');
    }
  }

  /// Unlink Google identity from user account
  /// Only available if user has another sign-in method (email/password)
  Future<AuthResult> unlinkGoogleIdentity() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.failure('Please sign in first.');
    }

    if (!hasGoogleLinked) {
      return AuthResult.failure('No Google account is linked.');
    }

    if (!hasEmailIdentity) {
      return AuthResult.failure('Cannot unlink Google - you need at least one sign-in method. Set up a password first.');
    }

    try {
      // Find the Google identity
      final identities = user.identities;
      final googleIdentity = identities?.firstWhere(
        (i) => i.provider == 'google',
        orElse: () => throw Exception('Google identity not found'),
      );

      if (googleIdentity == null) {
        return AuthResult.failure('Google identity not found.');
      }

      debugPrint('Unlinking Google identity: ${googleIdentity.id}');

      await client.auth.unlinkIdentity(googleIdentity);

      // Refresh the session to get updated identities
      await client.auth.refreshSession();

      return AuthResult.success(
        user: currentUser,
        message: 'Google account unlinked successfully.',
      );
    } on AuthException catch (e) {
      debugPrint('Unlink Google - AuthException: ${e.message}');
      return AuthResult.failure(_parseAuthError(e));
    } catch (e) {
      debugPrint('Unlink Google error: $e');
      return AuthResult.failure('Failed to unlink Google account. Please try again.');
    }
  }

  /// Get user's auth provider type
  String? get authProvider {
    final user = currentUser;
    if (user == null) return null;

    final identities = user.identities;
    if (identities == null || identities.isEmpty) return null;

    // Return the first provider
    return identities.first.provider;
  }

  /// Check if an email exists and what provider it uses
  /// Returns: 'email' for email/password, 'google' for Google, null if not found
  Future<String?> checkEmailProvider(String email) async {
    try {
      // Try to sign in with wrong password to check if user exists
      // Supabase returns different errors for non-existent vs wrong password
      // This is a workaround since Supabase doesn't have a direct API for this

      // First, try to get identities from a potential existing session
      // This won't work for checking other emails, so we use the reset flow
      // to infer if the email is registered

      // For now, we'll rely on the error message from sign-in attempts
      // Return null - the actual check happens during sign-in
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get user profile from profiles table
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('getUserProfile: No current user');
      return null;
    }

    try {
      debugPrint('getUserProfile: Fetching profile for user ${user.id}');
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // Use maybeSingle instead of single to avoid error if no profile
      debugPrint('getUserProfile: Response = $response');
      return response;
    } catch (e) {
      debugPrint('getUserProfile: Error fetching profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? fullName,
    String? avatarUrl,
    String? currency,
    String? locale,
    DateTime? birthDate,
    bool clearBirthDate = false,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (currency != null) updates['currency'] = currency;
      if (locale != null) updates['locale'] = locale;
      if (birthDate != null) {
        updates['birth_date'] = birthDate.toIso8601String().split('T')[0]; // Store as date only
      } else if (clearBirthDate) {
        updates['birth_date'] = null;
      }

      if (updates.isEmpty) return true;

      await client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      // Also update auth metadata if name changed
      if (fullName != null) {
        await client.auth.updateUser(
          UserAttributes(data: {'display_name': fullName}),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Parse auth errors into user-friendly messages
  String _parseAuthError(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password. If you signed up with Google, please use "Continue with Google" instead.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists. If you signed up with Google, please use "Continue with Google" to sign in.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('weak password') || message.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }
    if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    return e.message;
  }
}

/// Result class for auth operations
class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult._({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.success({User? user, String? message}) {
    return AuthResult._(success: true, user: user, message: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, message: message);
  }
}
