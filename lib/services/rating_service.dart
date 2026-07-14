import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the "Rate Us" prompt lifecycle.
///
/// Logic:
/// - First prompt: 2 days after first app open
/// - Repeat: every 2 days if user taps "Ask me later"
/// - Never shown again if user taps "Don't ask again"
class RatingService {
  RatingService._();
  static final RatingService instance = RatingService._();

  // ──────────────────────────────────────────────
  // CONFIGURE: Replace with your store URL or feedback form link
  // Examples:
  //   Play Store: 'https://play.google.com/store/apps/details?id=com.yourapp'
  //   App Store:  'https://apps.apple.com/app/idYOUR_APP_ID'
  //   Feedback:   'mailto:feedback@yourapp.com?subject=FlowLedger Feedback'
  static const String feedbackUrl = 'mailto:feedback@flowledger.app?subject=FlowLedger Feedback';
  // ──────────────────────────────────────────────

  static const String _keyFirstOpen = 'rating_first_open_ms';
  static const String _keyLastPrompt = 'rating_last_prompt_ms';
  static const String _keyDeclined = 'rating_declined';

  /// In debug builds use a 30-second delay so you can test the dialog quickly.
  /// In release builds the delay is 2 days.
  static final Duration _promptDelay = kDebugMode
      ? const Duration(seconds: 30)
      : const Duration(days: 2);

  /// Call once on app start to record the very first open date.
  Future<void> recordFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyFirstOpen)) {
      await prefs.setInt(_keyFirstOpen, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Returns true if the rating dialog should be shown right now.
  Future<bool> shouldShowRating() async {
    final prefs = await SharedPreferences.getInstance();

    // User permanently dismissed
    if (prefs.getBool(_keyDeclined) == true) return false;

    final firstOpenMs = prefs.getInt(_keyFirstOpen);
    if (firstOpenMs == null) return false;

    final now = DateTime.now();
    final firstOpen = DateTime.fromMillisecondsSinceEpoch(firstOpenMs);

    // Not enough time since first open
    if (now.difference(firstOpen) < _promptDelay) return false;

    final lastPromptMs = prefs.getInt(_keyLastPrompt);
    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      // Not enough time since last prompt
      if (now.difference(lastPrompt) < _promptDelay) return false;
    }

    return true;
  }

  /// Call when the dialog is shown (covers "Ask me later" reset).
  Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPrompt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Call when the user taps "Don't ask again".
  Future<void> markDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDeclined, true);
  }

  /// DEBUG ONLY — clears all rating keys so the popup can appear again.
  /// Call from DevTools or add a debug button to trigger this.
  Future<void> resetForTesting() async {
    assert(kDebugMode, 'resetForTesting should only be called in debug mode');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstOpen);
    await prefs.remove(_keyLastPrompt);
    await prefs.remove(_keyDeclined);
    debugPrint('[RatingService] Reset — popup will appear in 30 seconds');
  }
}
