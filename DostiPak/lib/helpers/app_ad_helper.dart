import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rishtpak/constants/constants.dart';
import 'package:rishtpak/models/user_model.dart';

class AppAdHelper {
  // Local Variables
  static InterstitialAd? _interstitialAd;

  // Get Interstitial Ad ID
  static String get _interstitialID {
    if (Platform.isAndroid) {
      return ANDROID_INTERSTITIAL_ID;
    } else if (Platform.isIOS) {
      return IOS_INTERSTITIAL_ID;
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  // Create & load Interstitial Ad (google_mobile_ads 6.x API).
  // Ads are disabled while the ad unit id in constants.dart is empty.
  static Future<void> _createInterstitialAd() async {
    if (_interstitialID.isEmpty) {
      debugPrint('AppAdHelper -> interstitial ads disabled (empty ad unit id)');
      return;
    }

    await InterstitialAd.load(
      adUnitId: _interstitialID,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('AppAdHelper -> ad loaded.');
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
            // Called when an ad opens an overlay that covers the screen.
            onAdShowedFullScreenContent: (InterstitialAd ad) =>
                debugPrint('AppAdHelper -> ad opened.'),
            // Called when an ad removes an overlay that covers the screen.
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              debugPrint('AppAdHelper -> ad closed.');
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              debugPrint('AppAdHelper -> ad failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
            },
          );
          _interstitialAd?.show();
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AppAdHelper -> ad failed to load: ${error.message}');
          _interstitialAd?.dispose();
          _interstitialAd = null;
        },
      ),
    );
  }

  // Show Interstitial Ads for Non VIP Users
  static Future<void> showInterstitialAd() async {
    /// Check User VIP Status
    if (!UserModel().userIsVip) {
      await _createInterstitialAd();
    } else {
      debugPrint('User is VIP');
    }
  }

  // Dispose Interstitial Ad
  static void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
