import 'dart:io';

import 'package:rishtpak/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rishtpak/helpers/geo_helper.dart';
import 'package:rishtpak/models/user_model.dart';
import 'package:rishtpak/models/app_model.dart';

class AppHelper {
  /// Local variables
  final _firestore = FirebaseFirestore.instance;

  /// Check and request location permission
  Future<void> checkLocationPermission(
      {required VoidCallback onGpsDisabled,
      required VoidCallback onDenied,
      required VoidCallback onGranted}) async {
    /// Check if GPS is enabled
    if (!(await Geolocator.isLocationServiceEnabled())) {
      // Callback function
      onGpsDisabled();
      debugPrint('onGpsDisabled() -> disabled');
    } else {
      /// Request permission
      final LocationPermission permission =
          await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.denied:
          onDenied();
          debugPrint('permission: denied');
          break;
        case LocationPermission.deniedForever:
          onDenied();
          debugPrint('permission: deniedForever');
          break;
        case LocationPermission.unableToDetermine:
          onDenied();
          debugPrint('permission: unableToDetermine');
          break;
        case LocationPermission.whileInUse:
          onGranted();
          debugPrint('permission: whileInUse');
          break;
        case LocationPermission.always:
          onGranted();
          debugPrint('permission: always');
          break;
      }
    }
  }

  /// Get User location from formatted address
  Future<Placemark> getUserAddress(double latitude, double longitude) async {
    /// Place object containing formatted address info
    Placemark place;

    ///  Get Placemark to retrieve user location
    final List<Placemark> places =
        await placemarkFromCoordinates(latitude, longitude);

    /// Get and returns the first place
    place = places.first;

    return place;
  }

  /// Get distance between current user and another user
  /// Returns distance in (Kilometers - KM)
  int getDistanceBetweenUsers(
      {required double userLat, required double userLong}) {
    /// Current user location center
    final double centerLat = UserModel().user.userGeoPoint.latitude;
    final double centerLng = UserModel().user.userGeoPoint.longitude;

    /// Return distance (double) between users then round to int
    /// (GeoHelper replaces the old geoflutterfire GeoFirePoint.distance)
    return GeoHelper.haversineDistanceKm(centerLat, centerLng, userLat, userLong)
        .round();
  }

  /// Get app store URL - Google Play / Apple Store
  String get _appStoreUrl {
    String url = "";
    final String androidPackageName = AppModel().appInfo.androidPackageName;
    final String iOsAppId = AppModel().appInfo.iOsAppId;
    // Check device OS
    if (Platform.isAndroid) {
      url = "https://play.google.com/store/apps/details?id=$androidPackageName";
    } else if (Platform.isIOS) {
      url = "https://apps.apple.com/app/id=$iOsAppId";
    }
    return url;
  }

  /// Get app current version from Cloud Firestore Database,
  /// that is the same with Google Play Store / Apple Store app version
  Future<int> getAppStoreVersion() async {
    final DocumentSnapshot appInfo =
        await _firestore.collection(C_APP_INFO).doc('settings').get();
    // Cast Firestore data (untyped snapshots) to a typed map
    final Map<String, dynamic> appData =
        appInfo.data()! as Map<String, dynamic>;
    // Update AppInfo object
    AppModel().setAppInfo(appData);
    // Check Platform
    if (Platform.isAndroid) {
      return appData[ANDROID_APP_CURRENT_VERSION] ?? 1;
    } else if (Platform.isIOS) {
      return appData[IOS_APP_CURRENT_VERSION] ?? 1;
    }
    return 1;
  }

  /// Update app info data in database
  Future<void> updateAppInfo(Map<String, dynamic> data) async {
    // Update app data
    _firestore.collection(C_APP_INFO).doc('settings').update(data);
  }

  /// URL opening helper (stub).
  ///
  /// The `url_launcher` package is not part of the dependency set anymore,
  /// so every "open link" feature logs the target URL instead of launching
  /// a browser. Wire a real launcher here if deep-linking is needed later.
  void _launchUrl(String url) {
    debugPrint('AppHelper._launchUrl() -> $url (launch stub)');
  }

  /// Share app method
  Future<void> shareApp() async {
    // share package removed - log the app store url
    _launchUrl(_appStoreUrl);
  }

  /// Review app method
  Future<void> reviewApp() async {
    // Check OS and get correct url
    final String url =
        Platform.isIOS ? "https://apps.apple.com/app/idWRITE_APP_ID" : _appStoreUrl;
    _launchUrl(url);
  }

  /// Open app store - Google Play / Apple Store
  Future<void> openAppStore() async {
    _launchUrl(_appStoreUrl);
  }

  /// Open About us in Browser
  Future<void> openAboutUs() async {
    _launchUrl("https://mallucupid.com/about");
  }

  /// Open watch video in Browser
  Future<void> openWatchVideo() async {
    _launchUrl("https://mallucupid.com/video");
  }

  /// Open earn money in Browser
  Future<void> openEarnMoney() async {
    _launchUrl("https://mallucupid.com/earn");
  }

  /// Open Privacy Policy Page in Browser
  Future<void> openPrivacyPage() async {
    _launchUrl(AppModel().appInfo.privacyPolicyUrl);
  }

  /// Open Terms of Services in Browser
  Future<void> openTermsPage() async {
    _launchUrl(AppModel().appInfo.termsOfServicesUrl);
  }
}
