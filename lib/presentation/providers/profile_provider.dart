import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../services/supabase_service.dart';

// Key for storing pending email change
const String _pendingEmailChangeKey = 'pending_email_change';

/// Profile state
class ProfileState {
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime? birthDate;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.displayName,
    this.email,
    this.avatarUrl,
    this.birthDate,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? birthDate,
    bool? isLoading,
    String? error,
    bool clearBirthDate = false,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    debugPrint('ProfileNotifier: Constructor called');
    // Delay the initial load slightly to ensure auth state is stable
    Future.microtask(() => _loadProfile());
  }

  final _service = SupabaseService.instance;

  /// Load profile from Supabase
  Future<void> _loadProfile({bool forceRefreshSession = false}) async {
    if (!_service.isAuthenticated) {
      debugPrint('_loadProfile: Not authenticated, skipping');
      return;
    }

    debugPrint('_loadProfile: Starting');
    state = state.copyWith(isLoading: true);

    try {
      // Get from user auth metadata (this is the source of truth for email)
      final displayName = _service.userDisplayName;
      final email = _service.userEmail;
      final avatarUrl = _service.userAvatarUrl;

      debugPrint('_loadProfile: email from auth: $email, displayName: $displayName');

      state = ProfileState(
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
        isLoading: false,
      );
      debugPrint('_loadProfile: Set initial state from auth metadata');

      // Then try to get from profiles table (separate try-catch to not fail everything)
      try {
        final profile = await _service.getUserProfile();
        debugPrint('_loadProfile: Got profile from table = $profile');
        if (profile != null) {
          DateTime? birthDate;
          if (profile['birth_date'] != null) {
            birthDate = DateTime.tryParse(profile['birth_date'].toString());
          }

          // Check if profile has email that differs from auth email
          final profileEmail = profile['email'] as String?;

          // Auth email is the source of truth - if they differ, sync profile to match auth
          if (email != null && profileEmail != null && email != profileEmail) {
            debugPrint('_loadProfile: Email mismatch detected - auth: $email, profile: $profileEmail');
            debugPrint('_loadProfile: Will sync auth email to profiles table');
            // Sync email in background (don't await to not block UI)
            _service.client
                .from('profiles')
                .update({'email': email})
                .eq('id', _service.currentUser!.id)
                .then((_) => debugPrint('_loadProfile: Email synced to profiles table'))
                .catchError((e) => debugPrint('_loadProfile: Failed to sync email: $e'));
          }

          state = state.copyWith(
            displayName: profile['full_name'] ?? displayName,
            avatarUrl: profile['avatar_url'] ?? avatarUrl,
            birthDate: birthDate,
            email: email, // Always use auth email as source of truth
          );
          debugPrint('_loadProfile: Updated state with profile table data');
        }
      } catch (profileError) {
        debugPrint('_loadProfile: Error fetching profile table (non-critical): $profileError');
        // Don't fail - we already have the basic data from auth metadata
      }
    } catch (e) {
      debugPrint('_loadProfile: Error loading profile: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load profile');
    }
  }

  /// Refresh profile data
  Future<void> refresh({bool forceRefreshSession = false}) async {
    debugPrint('ProfileNotifier.refresh() called, forceRefreshSession=$forceRefreshSession');

    if (!_service.isAuthenticated) {
      debugPrint('ProfileNotifier.refresh(): Not authenticated, skipping');
      return;
    }

    // If force refresh, refresh the session first to get latest user data
    if (forceRefreshSession) {
      try {
        debugPrint('Force refreshing session to get latest user data...');
        await _service.client.auth.refreshSession();
        debugPrint('Session refreshed successfully');
      } catch (e) {
        debugPrint('Session refresh failed: $e');
      }
    }

    // Get the current email from auth - this is the source of truth
    final authEmail = _service.userEmail;
    debugPrint('Current auth email after refresh: $authEmail');

    await _loadProfile(forceRefreshSession: false); // Don't refresh again in _loadProfile

    // Sync auth email to profiles table if they differ
    final profileEmail = state.email;
    if (authEmail != null && (profileEmail == null || profileEmail != authEmail)) {
      debugPrint('Syncing email from auth ($authEmail) to profiles table (current profile email: $profileEmail)');
      try {
        await _service.client
            .from('profiles')
            .update({'email': authEmail})
            .eq('id', _service.currentUser!.id);
        state = state.copyWith(email: authEmail);
        debugPrint('Email synced and state updated to: $authEmail');
      } catch (e) {
        debugPrint('Failed to sync email to profiles: $e');
      }
    }
  }

  /// Update display name
  Future<bool> updateDisplayName(String name) async {
    if (name.trim().isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateUserProfile(fullName: name.trim());
      if (success) {
        state = state.copyWith(displayName: name.trim(), isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to update name');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to update name');
      return false;
    }
  }

  /// Update birth date
  Future<bool> updateBirthDate(DateTime? birthDate) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateUserProfile(birthDate: birthDate);
      if (success) {
        state = state.copyWith(
          birthDate: birthDate,
          isLoading: false,
          clearBirthDate: birthDate == null,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to update birth date');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating birth date: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to update birth date');
      return false;
    }
  }

  /// Upload avatar image
  Future<bool> uploadAvatar(File imageFile) async {
    if (!_service.isAuthenticated) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _service.currentUser!;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('Uploading avatar: $fileName');
      debugPrint('File path: ${imageFile.path}');
      debugPrint('File exists: ${await imageFile.exists()}');

      // Upload to Supabase Storage
      final uploadResponse = await _service.client.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      debugPrint('Upload response: $uploadResponse');

      // Get public URL
      final publicUrl = _service.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      debugPrint('Public URL: $publicUrl');

      // Update profile with new avatar URL
      final success = await _service.updateUserProfile(avatarUrl: publicUrl);

      debugPrint('Profile update success: $success');

      if (success) {
        // Also update user metadata
        await _service.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': publicUrl}),
        );
        state = state.copyWith(avatarUrl: publicUrl, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to update avatar');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to upload avatar: $e');
      return false;
    }
  }

  /// Delete avatar
  Future<bool> deleteAvatar() async {
    if (!_service.isAuthenticated || state.avatarUrl == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Update profile to remove avatar URL
      final success = await _service.updateUserProfile(avatarUrl: '');

      if (success) {
        state = state.copyWith(avatarUrl: null, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete avatar');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to delete avatar');
      return false;
    }
  }

  /// Initiate email change (sends verification to new email)
  Future<AuthResult> initiateEmailChange(String newEmail) async {
    final trimmedEmail = newEmail.trim().toLowerCase();

    if (trimmedEmail.isEmpty) {
      return AuthResult.failure('Please enter a valid email');
    }

    // Check if it's the same email
    if (trimmedEmail == _service.userEmail?.toLowerCase()) {
      return AuthResult.failure('This is already your current email address');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('initiateEmailChange: Changing email to $trimmedEmail');
      await _service.client.auth.updateUser(
        UserAttributes(email: trimmedEmail),
        emailRedirectTo: 'com.flowledger.flowledger://email-callback',
      );

      // Store the pending email change so we can detect when it completes
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingEmailChangeKey, trimmedEmail);
      debugPrint('initiateEmailChange: Stored pending email change: $trimmedEmail');

      state = state.copyWith(isLoading: false);
      debugPrint('initiateEmailChange: Verification email sent');
      return AuthResult.success(
        message: 'Verification email sent to $trimmedEmail. Please check your inbox and click the link to confirm the change.',
      );
    } on AuthException catch (e) {
      debugPrint('initiateEmailChange: AuthException: ${e.message}');
      state = state.copyWith(isLoading: false, error: 'Failed to change email');

      // Check for common errors
      final message = e.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already exists') ||
          message.contains('email address is already') ||
          message.contains('duplicate') ||
          message.contains('unique constraint') ||
          message.contains('email_unique')) {
        return AuthResult.failure(
          'This email is already registered in the system. It may be linked to another account or a previous email change. Please use a different email or contact support.',
        );
      }
      if (message.contains('rate limit') || message.contains('security purposes')) {
        return AuthResult.failure(
          'Please wait a few minutes before requesting another email change.',
        );
      }
      if (message.contains('same email') || message.contains('identical')) {
        return AuthResult.failure(
          'This is already your current email address.',
        );
      }
      return AuthResult.failure('Failed to change email: ${e.message}');
    } catch (e) {
      debugPrint('initiateEmailChange: Error: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to change email');

      // Check if the error message contains email conflict info
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('already') || errorStr.contains('duplicate') || errorStr.contains('unique')) {
        return AuthResult.failure(
          'This email is already registered. Please use a different email.',
        );
      }
      return AuthResult.failure('Failed to change email. Please try again.');
    }
  }

  /// Sync email from auth to profiles table after email change is confirmed
  Future<void> syncEmailToProfile() async {
    final authEmail = _service.userEmail;
    if (authEmail == null || !_service.isAuthenticated) return;

    debugPrint('syncEmailToProfile: Syncing email $authEmail to profiles table');
    try {
      await _service.client
          .from('profiles')
          .update({'email': authEmail})
          .eq('id', _service.currentUser!.id);
      state = state.copyWith(email: authEmail);
      debugPrint('syncEmailToProfile: Email synced successfully');
    } catch (e) {
      debugPrint('syncEmailToProfile: Failed to sync email: $e');
    }
  }
}
