import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rishtpak/helpers/app_localizations.dart';
import 'package:rishtpak/models/app_model.dart';
import 'package:rishtpak/models/user_model.dart';
import 'package:rishtpak/screens/splash_screen.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/constants.dart';

Future<void> main() async {
  // Initialized before calling runApp to init firebase app
  WidgetsFlutterBinding.ensureInitialized();

  // Modern edge-to-edge style status bar (black icons on transparent bg)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize firebase app
  // (Firebase config is provided by android/app/google-services.json
  //  - keep this default initialization, FlutterFire CLI options file is
  //  not generated in this repo)
  await Firebase.initializeApp();

  // Firebase App Check - Play Integrity provider on Android.
  // (Register the app in the Firebase console first:
  //  App Check -> Apps -> com.mallucupid.app -> Play Integrity)
  await FirebaseAppCheck.instance
      .activate(androidProvider: AndroidProvider.playIntegrity);

  // Initialize Google Mobile Ads SDK
  // (Ad unit ids in constants.dart are empty => ads are disabled)
  await MobileAds.instance.initialize();

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  /// Check iOS device
  if (Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  runApp(const MyApp());
}

// Define the Navigator global key state to be used when the build context is not available!
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppModel>(
      model: AppModel(),
      child: ScopedModel<UserModel>(
        model: UserModel(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: APP_NAME,
          debugShowCheckedModeBanner: false,

          /// Setup translations
          localizationsDelegates: [
            // AppLocalizations is where the lang translations is loaded
            AppLocalizations.delegate,
            // country_code_picker 3.x exports CountryLocalizations
            // from the main library
            CountryLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: SUPPORTED_LOCALES,

          /// Returns a locale which will be used by the app
          localeResolutionCallback: (locale, supportedLocales) {
            // Check if the current device locale is supported
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale!.languageCode) {
                return supportedLocale;
              }
            }

            /// If the locale of the device is not supported, use the first one
            /// from the list (English, in this case).
            return supportedLocales.first;
          },
          home: SplashScreen(),
          theme: _appTheme(),
        ),
      ),
    );
  }
}

/// App theme
ThemeData _appTheme() {
  const ColorScheme colorScheme = ColorScheme.light(
    primary: APP_PRIMARY_COLOR,
    onPrimary: Colors.white,
    secondary: APP_PRIMARY_COLOR,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  return ThemeData(
    colorScheme: colorScheme,
    primaryColor: APP_PRIMARY_COLOR,
    scaffoldBackgroundColor: Colors.white,
    inputDecorationTheme: const InputDecorationTheme(
        errorStyle: TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        )),
    appBarTheme: AppBarTheme(
      color: Colors.white,
      elevation: Platform.isIOS ? 0 : 4.0,
      iconTheme: const IconThemeData(color: Colors.black),
      titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 18),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
  );
}
