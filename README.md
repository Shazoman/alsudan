# ALSUDAN – Upgraded Build

This bundle upgrades the ALSUDAN Flutter app with:

- Native contact retrieval/picker using `flutter_contacts 2.1.0`.
- MTN, Airtel, Glo, 9mobile and Smile selection in Airtime and Data.
- Transaction history saved locally with date, exact time, reference, amount, status and balance before/after.
- Fingerprint/biometric login setting that persists after restart.
- Fingerprint login is shown on the Login screen only when enabled in Settings.
- Disabling biometric login removes the biometric login path.
- Modern Settings screen with Account, Security, Preferences, Support & Legal sections.
- 4-column × 3-row dashboard service grid.

## Important Android integration

Because `local_auth` requires a `FlutterFragmentActivity`, this bundle includes:

`android/app/src/main/kotlin/com/alsudan/alsudan/MainActivity.kt`

If your existing Android project uses a different Kotlin package/namespace, copy the class body into your existing `MainActivity.kt` and keep your existing package declaration.

## Install into an existing ALSUDAN project

Replace `lib/main.dart` and `pubspec.yaml`, then merge the Android manifest permissions. Ensure your existing MainActivity extends `FlutterFragmentActivity`.

Run:

```bash
flutter clean
rm -rf .dart_tool
flutter pub get
flutter run
```

## Contact API note

`flutter_contacts 2.1.0` uses the permissions API and the native picker API. The app requests contact read permission before requesting name/phone properties from the native picker.

## Biometric behavior

1. Open Settings.
2. Turn on Fingerprint / Biometric Login.
3. The device biometric prompt must succeed before the switch becomes enabled.
4. Return to Login: the fingerprint button is available.
5. Turn the setting off: biometric login is blocked and the Login screen no longer shows the fingerprint button.

The purchase actions are local/demo transactions. A real VTU production app still needs a secure backend, provider API integration, server-side authorization, OTP/MFA service, fraud/risk engine and secure payment gateway.
