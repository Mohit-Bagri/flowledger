import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, Supabase;
import 'package:app_links/app_links.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/app_lock_provider.dart';
import 'presentation/providers/currency_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/screens/lock/lock_screen.dart';
import 'data/storage/storage_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service (uses Hive internally)
  await StorageService.instance.init();

  // Initialize Supabase (only if credentials are configured)
  try {
    if (SupabaseConfig.url != 'YOUR_SUPABASE_URL') {
      await SupabaseService.initialize();
      await SyncService.instance.initialize();
    }
  } catch (e) {
    debugPrint('Supabase initialization skipped: $e');
  }

  // Initialize notification service
  await NotificationService.instance.initialize();

  // Schedule notifications based on saved settings
  final notificationSettings = await NotificationService.instance.getSettings();
  await NotificationService.instance.rescheduleAllNotifications(notificationSettings);

  // Check and send weekly summary if it's Sunday
  await NotificationService.instance.checkAndSendWeeklySummary();

  // Initialize AdMob (non-blocking — continues even if it fails)
  await AdService.initialize();

  // Check if onboarding has been completed
  final showOnboarding = StorageService.instance.getSetting<bool>(
    'onboarding_completed',
    defaultValue: false,
  ) != true;

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      child: FlowLedgerApp(showOnboarding: showOnboarding),
    ),
  );
}

class FlowLedgerApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const FlowLedgerApp({super.key, this.showOnboarding = false});

  @override
  ConsumerState<FlowLedgerApp> createState() => _FlowLedgerAppState();
}

class _FlowLedgerAppState extends ConsumerState<FlowLedgerApp> {
  late final GoRouter _router;
  late final AppLinks _appLinks;

  // Key for pending email change in SharedPreferences
  static const String _pendingEmailChangeKey = 'pending_email_change';

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(showOnboarding: widget.showOnboarding);
    _appLinks = AppLinks();

    // Listen to auth state changes to reload sync time and profile for new user
    if (SupabaseConfig.url != 'YOUR_SUPABASE_URL') {
      // Set up deep link listener for email change and other auth flows
      _setupDeepLinkListener();
      // Track if we've had a successful sign in this session to avoid false sign-outs
      bool hadSession = SupabaseService.instance.isAuthenticated;

      SupabaseService.instance.authStateChanges.listen((state) async {
        debugPrint('=== Auth state changed ===');
        debugPrint('Event: ${state.event}');
        debugPrint('Session exists: ${state.session != null}');
        debugPrint('User: ${state.session?.user.email ?? "null"}');
        debugPrint('Had session before: $hadSession');

        // Handle password recovery deep link FIRST before other handlers
        // This needs priority because signedIn fires alongside passwordRecovery
        if (state.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('Password recovery event received, navigating to reset screen');
          hadSession = state.session != null;
          // Use a microtask to ensure the widget tree is ready
          Future.microtask(() {
            // Temporarily unlock app if locked (password reset should be accessible)
            ref.read(appIsLockedProvider.notifier).state = false;
            // Navigate to reset password screen
            _router.go('/reset-password');
          });
          return; // Don't process other events for this auth state change
        }

        // Handle user update (email change, profile update)
        if (state.event == AuthChangeEvent.userUpdated) {
          debugPrint('=== USER UPDATED EVENT ===');

          // The new email comes from the session passed in the event
          final newEmail = state.session?.user.email;
          debugPrint('New email from auth session: $newEmail');

          // Get the current profile email (what we have cached locally)
          final profileState = ref.read(profileProvider);
          final cachedEmail = profileState.email;
          debugPrint('Cached email in profile state: $cachedEmail');

          // Read pending email change from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final pendingEmailChange = prefs.getString(_pendingEmailChangeKey);
          debugPrint('Pending email change from prefs: $pendingEmailChange');

          // Detect email change
          bool emailChanged = false;

          if (pendingEmailChange != null && newEmail != null) {
            // We have a pending email change request
            if (pendingEmailChange.toLowerCase() == newEmail.toLowerCase()) {
              debugPrint('EMAIL CHANGE DETECTED: pending email matches new email');
              emailChanged = true;
              // Clear the pending email change
              await prefs.remove(_pendingEmailChangeKey);
              debugPrint('Cleared pending email change from prefs');
            }
          } else if (cachedEmail != null && newEmail != null && cachedEmail.toLowerCase() != newEmail.toLowerCase()) {
            // Cached email differs from new auth email
            debugPrint('EMAIL CHANGE DETECTED: cached email differs from new email');
            emailChanged = true;
          }

          try {
            // IMPORTANT: Sync the new email to profiles table
            if (newEmail != null) {
              debugPrint('Syncing new email to profiles table: $newEmail');
              final userId = state.session?.user.id;
              if (userId != null) {
                await SupabaseService.instance.client
                    .from('profiles')
                    .update({'email': newEmail})
                    .eq('id', userId);
                debugPrint('Email synced to profiles table successfully');
              }
            }

            // Refresh the profile to pick up the new email
            debugPrint('Refreshing profile provider...');
            ref.read(profileProvider.notifier).refresh(forceRefreshSession: true);

            // Navigate to confirmation screen if email changed
            if (emailChanged) {
              debugPrint('Navigating to email change confirmation screen');
              Future.microtask(() {
                // Temporarily unlock app if locked
                ref.read(appIsLockedProvider.notifier).state = false;
                // Navigate to email change confirmed screen
                _router.go('/email-change-confirmed');
              });
            }
          } catch (e) {
            debugPrint('Error in userUpdated handler: $e');
          }
          debugPrint('=== END USER UPDATED EVENT ===');
          return;
        }

        // Handle token refresh (also refreshes user data)
        if (state.event == AuthChangeEvent.tokenRefreshed) {
          debugPrint('Token refreshed - refreshing profile');
          try {
            ref.read(profileProvider.notifier).refresh();
          } catch (e) {
            debugPrint('Error refreshing profile on token refresh: $e');
          }
          return;
        }

        // Handle initial session (app startup)
        if (state.event == AuthChangeEvent.initialSession) {
          debugPrint('Initial session event');
          hadSession = state.session != null;
          if (state.session != null) {
            debugPrint('Initial session has user: ${state.session?.user.email}');
            try {
              ref.read(profileProvider.notifier).refresh();
            } catch (e) {
              debugPrint('Error refreshing profile on initial session: $e');
            }
          }
          return;
        }

        // When user signs in (not from password recovery), reload sync time and profile
        if (state.event == AuthChangeEvent.signedIn && state.session != null) {
          debugPrint('User signed in - loading user data for ${state.session?.user.email}');
          hadSession = true;
          try {
            // Don't await this - let it run in the background to not block UI
            SyncService.instance.onUserChanged().then((_) {
              debugPrint('onUserChanged completed');
            }).catchError((e) {
              debugPrint('onUserChanged error: $e');
            });
            // Refresh profile data for the new user
            ref.read(profileProvider.notifier).refresh();
          } catch (e) {
            debugPrint('Error in signedIn handler: $e');
          }
          return;
        }

        // When user signs out, clear local data
        // Only clear if we actually had a session before (prevents clearing on app startup)
        if (state.event == AuthChangeEvent.signedOut) {
          debugPrint('SignedOut event received');
          if (hadSession) {
            debugPrint('Had session before, clearing sync state');
            hadSession = false;
            try {
              // Note: signOut() in SupabaseService already handles clearing
              // This is just a safety net
              await SyncService.instance.clearSyncState();
            } catch (e) {
              debugPrint('Error clearing data on sign out: $e');
            }
          } else {
            debugPrint('No previous session, ignoring signedOut event');
          }
        }
      });

      // Check for initial deep link on cold start (handle password recovery)
      _handleInitialDeepLink();
    }
  }

  /// Handle initial deep link when app opens from cold start
  Future<void> _handleInitialDeepLink() async {
    // Give Supabase time to process the initial deep link
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if there's a recovery session
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('Initial session found: ${session.user.email}');
      // The auth state listener will handle navigation
    }

    // Also check for any initial deep link that may need manual processing
    try {
      final initialLink = await _appLinks.getInitialLinkString();
      if (initialLink != null) {
        debugPrint('Initial deep link found: $initialLink');
        await _handleDeepLink(Uri.parse(initialLink));
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  /// Set up listener for incoming deep links (when app is already running)
  void _setupDeepLinkListener() {
    _appLinks.stringLinkStream.listen((String? link) async {
      if (link != null) {
        debugPrint('=== DEEP LINK RECEIVED ===');
        debugPrint('Link: $link');
        await _handleDeepLink(Uri.parse(link));
      }
    }, onError: (error) {
      debugPrint('Deep link stream error: $error');
    });
  }

  /// Process a deep link URL
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('=== PROCESSING DEEP LINK ===');
    debugPrint('URI: $uri');
    debugPrint('Host: ${uri.host}');
    debugPrint('Fragment: ${uri.fragment}');
    debugPrint('Query: ${uri.query}');

    // Check if this is an email-callback
    if (uri.host == 'email-callback' && uri.fragment.isNotEmpty) {
      final params = Uri.splitQueryString(uri.fragment);
      final type = params['type'];
      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'];
      final message = params['message'];

      debugPrint('Email callback detected');
      debugPrint('Type: $type');
      debugPrint('Has access token: ${accessToken != null}');
      debugPrint('Has refresh token: ${refreshToken != null}');
      debugPrint('Message: $message');

      // Handle the actual email change confirmation (with tokens)
      if (type == 'email_change' && accessToken != null && refreshToken != null) {
        debugPrint('=== EMAIL CHANGE DEEP LINK DETECTED ===');
        await _handleEmailChangeCallback(accessToken, refreshToken);
        return;
      }

      // Handle the "first confirmation" message (double opt-in flow)
      // This happens when user clicks link from OLD email - they still need to click link from NEW email
      if (message != null && message.contains('confirm')) {
        debugPrint('=== EMAIL CHANGE FIRST CONFIRMATION ===');
        // Show a snackbar informing user to check their new email
        _showEmailChangeFirstConfirmationSnackbar();
        return;
      }
    }

    // Handle login-callback and reset-callback URLs - these use PKCE with query params
    // These use query parameters (?code=...) and need Supabase to process them
    if (uri.host == 'login-callback' || uri.host == 'reset-callback') {
      debugPrint('Auth callback URL detected, letting Supabase handle it');
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        debugPrint('Supabase processed auth callback URL');
      } catch (e) {
        debugPrint('Supabase auth callback processing error (may be expected): $e');
      }
      return;
    }

    debugPrint('Unhandled deep link, ignoring');
    debugPrint('=== END PROCESSING DEEP LINK ===');
  }

  /// Handle email change callback - update session and sync email to profiles
  Future<void> _handleEmailChangeCallback(String accessToken, String refreshToken) async {
    try {
      debugPrint('Setting session with access and refresh tokens...');

      // Set the session using both tokens - this keeps the user logged in with new email
      final response = await Supabase.instance.client.auth.setSession(refreshToken);

      if (response.session != null) {
        debugPrint('Session set successfully from email change deep link');
        debugPrint('New email: ${response.session!.user.email}');

        final newEmail = response.session!.user.email;
        final userId = response.session!.user.id;

        if (newEmail != null) {
          // Sync the new email to profiles table
          debugPrint('Syncing new email to profiles table: $newEmail');
          try {
            await SupabaseService.instance.client
                .from('profiles')
                .update({'email': newEmail})
                .eq('id', userId);
            debugPrint('Email synced to profiles table successfully');
          } catch (e) {
            debugPrint('Error syncing email to profiles: $e');
          }

          // Check if we have a pending email change
          final prefs = await SharedPreferences.getInstance();
          final pendingEmailChange = prefs.getString(_pendingEmailChangeKey);

          debugPrint('Pending email from prefs: $pendingEmailChange');
          debugPrint('New email: $newEmail');

          // Refresh profile to pick up new email
          ref.read(profileProvider.notifier).refresh(forceRefreshSession: true);

          // Navigate to confirmation screen
          if (pendingEmailChange != null &&
              pendingEmailChange.toLowerCase() == newEmail.toLowerCase()) {
            debugPrint('Pending email matches new email - navigating to confirmation');
            await prefs.remove(_pendingEmailChangeKey);

            Future.microtask(() {
              ref.read(appIsLockedProvider.notifier).state = false;
              _router.go('/email-change-confirmed');
            });
          } else {
            // Email changed but no pending email stored - still navigate to confirmation
            debugPrint('No pending email match, but still navigating to confirmation');
            Future.microtask(() {
              ref.read(appIsLockedProvider.notifier).state = false;
              _router.go('/email-change-confirmed');
            });
          }
        }
      } else {
        debugPrint('Failed to set session from email change deep link - response.session is null');
      }
    } catch (e) {
      debugPrint('Error processing email change deep link: $e');
    }
    debugPrint('=== END EMAIL CHANGE HANDLING ===');
  }

  /// Show a snackbar when user clicks one of the email change confirmation links
  /// This informs them to check the other email for the second confirmation
  void _showEmailChangeFirstConfirmationSnackbar() {
    // Use a GlobalKey or navigate to show the snackbar
    // Since we're in the app state, we can use a simple approach with ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'First confirmation complete! Please check your OTHER email inbox and click the confirmation link there to finish changing your email. Both links must be clicked.',
            ),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch appThemeModeProvider to ensure it initializes and loads saved preference
    // This also keeps themeProvider in sync
    ref.watch(appThemeModeProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    // Watch app lock provider to initialize it
    ref.watch(appLockEnabledProvider);

    // Watch currency provider to initialize it and sync with CurrencyFormatter
    ref.watch(currencyProvider);

    return MaterialApp.router(
      title: 'FlowLedger',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization Configuration
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: SupportedLanguages.supportedLocales,

      // Router Configuration
      routerConfig: _router,

      // App Lock - wraps the entire app
      builder: (context, child) {
        return LockScreen(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
