import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/config/ads_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/ad_service.dart';
import '../../providers/subscription_provider.dart';

/// A banner ad widget that sits at the bottom of main screens.
///
/// • Hidden for premium users (checks [isPremiumProvider]).
/// • Shows a "Remove ads → Go Pro" link below the banner.
/// • Gracefully shows nothing if ads are not initialized.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdService.instance.isInitialized) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    // Premium users never see ads
    if (isPremium) return const SizedBox.shrink();

    // Ad not ready yet
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: borderColor),
        SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
        // "Remove ads" nudge
        GestureDetector(
          onTap: () => context.push('/paywall'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Remove ads · Go Pro',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
