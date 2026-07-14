import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/config/ads_config.dart';
import 'revenue_cat_service.dart';

/// Manages Google AdMob banner and interstitial ads.
///
/// Usage:
///   • Call [AdService.initialize()] in main.dart after other service inits.
///   • Call [AdService.instance.showInterstitialIfDue()] after user actions
///     (add/edit/delete income or expense).
///   • Use [BannerAdWidget] for banner ads on screen bottoms.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  /// Count of user actions since last interstitial was shown.
  int _actionCount = 0;

  /// Initialize AdMob SDK. Call once from main.dart.
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      instance._initialized = true;
      instance._preloadInterstitial();
      debugPrint('[AdService] Initialized');
    } catch (e) {
      debugPrint('[AdService] Initialization error: $e');
    }
  }

  bool get isInitialized => _initialized;

  /// Preload the next interstitial ad in the background.
  void _preloadInterstitial() {
    if (!_initialized || _isLoadingInterstitial || _interstitialAd != null) {
      return;
    }
    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Call this after a user action (add/edit/delete income or expense).
  ///
  /// Shows an interstitial ad once every [AdsConfig.interstitialFrequency]
  /// actions. Silently skips if user is premium or ad is not ready.
  Future<void> showInterstitialIfDue() async {
    if (!_initialized) return;

    // Skip for premium users
    final isPremium = await RevenueCatService.instance.isPremium();
    if (isPremium) return;

    _actionCount++;
    if (_actionCount < AdsConfig.interstitialFrequency) {
      _preloadInterstitial(); // Keep preloading for when it's due
      return;
    }

    // Reset counter and show ad if available
    _actionCount = 0;
    await _showInterstitial();
  }

  Future<void> _showInterstitial() async {
    final ad = _interstitialAd;
    if (ad == null) {
      _preloadInterstitial(); // Try loading for next time
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitial(); // Preload next one immediately
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitial();
        debugPrint('[AdService] Interstitial failed to show: $error');
      },
    );

    await ad.show();
  }
}
