import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'debug_service.dart';
import 'ad_helper.dart';

class AdService {
  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }

  static String get bannerAdUnitId {
    if (kIsWeb) return ''; 
    return AdHelper.bannerAdUnitId;
  }

  static BannerAd? createBannerAd() {
    if (kIsWeb) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.mediumRectangle, // Close to "Native" look
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => DebugService.info('Ad loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          DebugService.error('Ad failed to load', error);
        },
      ),
    );
  }
}
