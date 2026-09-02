import 'dart:async';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  // Catch every uncaught async error so a background failure can never
  // silently kill the app. Startup steps below are individually guarded:
  // a failure in an OPTIONAL service (ads / app check) must never prevent
  // the UI from launching.
  await runZonedGuarded(() async {
    // 1) Firebase core - REQUIRED. If this fails we still render a visible
    //    error screen instead of closing instantly, so the problem can be
    //    diagnosed (bad google-services.json, missing Play services, ...).
    try {
      await Firebase.initializeApp();
    } catch (e, s) {
      debugPrint('main -> Firebase.initializeApp FAILED: $e\n$s');
      runApp(StartupErrorScreen(
        title: 'Startup problem',
        detail: 'Firebase failed to initialize.\n\n$e',
      ));
      return;
    }

    // 2) Firebase App Check - Play Integrity provider on Android.
    //    (Register the app in the Firebase console first:
    //     App Check -> Apps -> com.mallucupid.app -> Play Integrity)
    //    NON-FATAL: devices without Google Play Services (or Play Integrity
    //    trouble) fall back to the debug provider, and finally continue
    //    without App Check rather than crashing.
    try {
      await FirebaseAppCheck.instance
          .activate(androidProvider: AndroidProvider.playIntegrity);
    } catch (e, s) {
      debugPrint('main -> AppCheck playIntegrity failed, trying debug: $e');
      try {
        await FirebaseAppCheck.instance
            .activate(androidProvider: AndroidProvider.debug);
      } catch (e2, s2) {
        debugPrint('main -> AppCheck unavailable, continuing without: '
            '$e2\n$s2');
      }
    }

    // 3) Google Mobile Ads - OPTIONAL. The AdMob APPLICATION_ID must exist
    //    in AndroidManifest.xml (Google test app id is set there) and the
    //    ad unit ids in constants.dart are empty => no ads are requested.
    //    Guarded anyway so a bad ads config can NEVER crash the app.
    try {
      await MobileAds.instance.initialize();
    } catch (e, s) {
      debugPrint('main -> MobileAds init skipped (ads disabled): $e\n$s');
    }

    // 4) iOS foreground notification presentation options.
    if (Platform.isIOS) {
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e, s) {
        debugPrint('main -> iOS notification options skipped: $e\n$s');
      }
    }

    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('main -> uncaught zone error: $error\n$stack');
  });
}

// Define the Navigator global key state to be used when the build context is not available!
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Full-screen error page shown when a REQUIRED startup step fails
/// (e.g. Firebase initialization). Better than an instant close: the user
/// sees what happened and can retry.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFE91E63), size: 64),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please check your internet connection and try again. '
                    'If the problem continues, reinstall the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: APP_TEXT_MUTED),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detail,
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: APP_TEXT_COLOR),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: APP_PRIMARY_COLOR,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: () => main(),
                    child: const Text('Try again',
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

/// App theme - rose identity, light surfaces, NO pure black anywhere.
ThemeData _appTheme() {
  const ColorScheme colorScheme = ColorScheme.light(
    primary: APP_PRIMARY_COLOR,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFE3EC),
    onPrimaryContainer: APP_PRIMARY_DARK_COLOR,
    secondary: APP_ACCENT_COLOR,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: APP_TEXT_COLOR,
    error: APP_ERROR_COLOR,
  );

  return ThemeData(
    colorScheme: colorScheme,
    primaryColor: APP_PRIMARY_COLOR,
    scaffoldBackgroundColor: Colors.white,
    // Charcoal-plum text instead of pure black, everywhere.
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: APP_TEXT_COLOR),
      bodyMedium: TextStyle(color: APP_TEXT_COLOR),
      bodySmall: TextStyle(color: APP_TEXT_MUTED),
      titleLarge: TextStyle(color: APP_TEXT_COLOR),
      titleMedium: TextStyle(color: APP_TEXT_COLOR),
      titleSmall: TextStyle(color: APP_TEXT_COLOR),
    ).apply(bodyColor: APP_TEXT_COLOR, displayColor: APP_TEXT_COLOR),
    inputDecorationTheme: const InputDecorationTheme(
        errorStyle: TextStyle(fontSize: 16),
        labelStyle: TextStyle(color: APP_TEXT_MUTED),
        hintStyle: TextStyle(color: APP_TEXT_FAINT),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        )),
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      elevation: 0.5,
      shadowColor: APP_SHADOW_COLOR,
      surfaceTintColor: Colors.white,
      iconTheme: IconThemeData(color: APP_PRIMARY_COLOR),
      titleTextStyle: TextStyle(color: APP_TEXT_MUTED, fontSize: 18),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: APP_PRIMARY_COLOR,
        foregroundColor: Colors.white,
        disabledBackgroundColor: APP_ACCENT_COLOR.withOpacity(0.45),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: APP_PRIMARY_COLOR),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: APP_PRIMARY_COLOR,
        side: const BorderSide(color: APP_PRIMARY_COLOR),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states
              .contains(WidgetState.selected)
          ? APP_PRIMARY_COLOR
          : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: APP_TEXT_FAINT, width: 1.6),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(APP_PRIMARY_COLOR),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states
              .contains(WidgetState.selected)
          ? APP_PRIMARY_COLOR
          : APP_TEXT_FAINT),
      trackColor: WidgetStateProperty.resolveWith((states) => states
              .contains(WidgetState.selected)
          ? APP_ACCENT_COLOR.withOpacity(0.45)
          : APP_DIVIDER_COLOR),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: APP_PRIMARY_COLOR,
      linearTrackColor: APP_DIVIDER_COLOR,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: APP_TEXT_COLOR,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: APP_DIVIDER_COLOR),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
          color: APP_TEXT_COLOR, fontSize: 18, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: APP_PRIMARY_COLOR,
      foregroundColor: Colors.white,
    ),
  );
}
