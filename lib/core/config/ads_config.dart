import 'dart:io';

/// ════════════════════════════════════════════════════════════════════
/// AD CONFIGURATION — Replace before publishing
/// ════════════════════════════════════════════════════════════════════
///
/// HOW TO SET UP:
/// 1. Create a Google AdMob account at: https://admob.google.com
/// 2. Add your app (Android + iOS) in the AdMob console
/// 3. Create ad units: Banner and Interstitial for each platform
/// 4. Replace the YOUR_* constants below with your real IDs
/// 5. Set [useTestAds] to false before publishing
/// 6. Also update AndroidManifest.xml and Info.plist with your AdMob App ID
///    (see android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist)
///
/// ADMOB APP IDs (add to platform config files):
///   Android → AndroidManifest.xml: com.google.android.gms.ads.APPLICATION_ID
///   iOS     → Info.plist: GADApplicationIdentifier
/// ════════════════════════════════════════════════════════════════════
class AdsConfig {
  AdsConfig._();

  /// Set to true to show Google test ads (safe during development).
  /// Set to false when publishing with real ad unit IDs.
  static const bool useTestAds = true;

  // ── Google test ad unit IDs (safe to use anytime) ──────────────────
  static const String _testBannerId =
      'ca-app-pub-3940256099942544/6300978111'; // Android test banner
  static const String _testBannerIdIos =
      'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712'; // Android test interstitial
  static const String _testInterstitialIdIos =
      'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial

  // ── Your production ad unit IDs ──────────────────────────────────────
  // Replace these with real IDs from your AdMob account before publishing
  static const String _androidBannerId = 'YOUR_ANDROID_BANNER_AD_UNIT_ID';
  static const String _iosBannerId = 'YOUR_IOS_BANNER_AD_UNIT_ID';
  static const String _androidInterstitialId =
      'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';
  static const String _iosInterstitialId =
      'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';

  // ── Computed properties ──────────────────────────────────────────────

  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? _testBannerIdIos : _testBannerId;
    }
    return Platform.isIOS ? _iosBannerId : _androidBannerId;
  }

  static String get interstitialAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? _testInterstitialIdIos : _testInterstitialId;
    }
    return Platform.isIOS ? _iosInterstitialId : _androidInterstitialId;
  }

  /// Interstitial ads are shown at most once every N user actions.
  /// Set to 1 to show on every action, higher numbers = less frequent.
  static const int interstitialFrequency = 1;
}
