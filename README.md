# Mallu Cupid

Mallu Cupid is a Flutter dating application for discovering profiles, matching with
other users, and communicating through conversations. The app uses Firebase for
authentication, profile data, media storage, and notifications.

## Project Layout

The Flutter application is in [DostiPak](DostiPak).

```text
DostiPak/
	android/       Android platform project
	ios/           iOS platform project
	assets/        Images and other bundled assets
	lib/
		api/         Firestore-backed API helpers
		constants/   App and database constants
		datas/       Firestore data objects
		models/      Application and user state
		screens/     Full-screen views
		tabs/        Main navigation tabs
		widgets/     Reusable UI components
```

The Dart package name remains `rishtpak` because the existing source imports use
`package:rishtpak/...`. The display name shown to users is `Mallu Cupid`.

## Main Features

- Firebase email/password authentication and phone OTP authentication
- Firestore user profiles, likes, visits, matches, conversations, and messages
- Firebase Storage profile and gallery images
- Location-based profile discovery and Passport location selection
- Push notifications through Firebase Cloud Messaging and OneSignal
- Profile reporting, blocking, account deletion, and online status
- VIP subscriptions, wallet support, and Google Mobile Ads
- English localization support
- Mallu Cupid logo and app icon assets

## Requirements

- Flutter SDK with Dart 3.13 or newer
- Android Studio and an Android SDK for Android builds
- Xcode and CocoaPods for iOS builds on macOS
- A configured Firebase project

Flutter is not included in this repository. Install it from the official
[Flutter installation guide](https://docs.flutter.dev/get-started/install), then
verify the installation:

```bash
flutter doctor
```

## Firebase Setup

The configured Android Firebase project is `mallucupid-91706`, and the Android
application ID is `com.mallucupid.app`.

The Android configuration file belongs at:

```text
DostiPak/android/app/google-services.json
```

For iOS, add the Firebase iOS application in the Firebase console and place its
downloaded `GoogleService-Info.plist` at:

```text
DostiPak/ios/Runner/GoogleService-Info.plist
```

Firebase Authentication providers, Firestore, Storage, FCM, and any required
OAuth settings must also be enabled in the Firebase console. Do not commit new
private keys, service-account files, or production secrets.

## Install Dependencies

Run commands from the Flutter project directory:

```bash
cd DostiPak
flutter pub get
```

## Run the App

Connect an emulator or physical device, then run:

```bash
cd DostiPak
flutter devices
flutter run
```

The app starts at the splash screen. It checks the Firebase session, then routes
the user to sign in, sign up, the home screen, or the blocked-account screen.

## Authentication Flow

1. `SplashScreen` calls `UserModel.authUserAccount()`.
2. Firebase Auth is checked through `currentUser`.
3. The matching document is loaded from the Firestore `Users` collection.
4. Existing active users enter `HomeScreen`.
5. Authenticated users without a Firestore profile enter `SignUpScreen`.
6. Users with `blocked` or `flagged` status enter `BlockedAccountScreen`.

Email/password login is handled in `PhoneNumberScreen`. The legacy phone OTP
flow uses `verifyPhoneNumber()` and `signInWithOTP()` in `UserModel`.

## Branding

The current branding files are:

- [Mallucupidlogo.png](Mallucupidlogo.png): source logo
- [MallucupidAppicon.png](MallucupidAppicon.png): source launcher icon
- [DostiPak/assets/images/mallucupid_logo.png](DostiPak/assets/images/mallucupid_logo.png): bundled logo
- [DostiPak/assets/images/mallucupid_app_icon.png](DostiPak/assets/images/mallucupid_app_icon.png): bundled icon

The app display name is defined by `APP_NAME` in
[DostiPak/lib/constants/constants.dart](DostiPak/lib/constants/constants.dart).

## Build

```bash
cd DostiPak
flutter analyze
flutter build apk
```

For iOS, run `flutter build ios` on macOS after adding the iOS Firebase
configuration and signing settings.

## Known Setup Notes

- The source code contains older Flutter APIs and integrations; dependency
	upgrades may require small compatibility fixes.
- OneSignal, AdMob, Google Maps, and store subscription settings contain project
	or platform-specific values that must be configured before production release.
- Release builds require Android signing credentials or an iOS provisioning
	profile and distribution certificate.
