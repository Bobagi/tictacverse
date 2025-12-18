# Tic Tac Verse

Offline cross-platform Tic Tac Toe (Android + iOS) built with Flutter, with multiple game modes and AdMob monetization.

## Requirements

- Flutter (stable) installed and on PATH
- Android Studio (Android SDK + Emulator)
- Xcode (iOS Simulator)
- CocoaPods

Validate:
```bash
flutter doctor -v
```

It must show no issues for Android toolchain and Xcode.

---

## Project Structure

* `lib/` app code
* `assets/` board/symbols assets (optional theming)
* `lib/l10n/` localization ARB files (generated code via `flutter gen-l10n`)
* `android/` Android project (Manifest includes AdMob App ID)
* `ios/` iOS project

---

## Setup

Install dependencies:

```bash
flutter pub get
```

Generate localization code:

```bash
flutter gen-l10n
```

---

## Running on Android (Emulator)

### Create/Start an emulator

* Open Android Studio
* Device Manager
* Create a device (Pixel / API 36 recommended)
* Start the emulator

Check devices:

```bash
flutter devices
```

Run the app (default: test ads):

```bash
flutter run -d emulator-5554 --dart-define=ADS_MODE=test
```

If your emulator ID is different, use the ID shown by `flutter devices`.

### Choose ads mode when running on Android emulator

No ads:

```bash
flutter run -d emulator-5554 --dart-define=ADS_MODE=off
```

Test ads:

```bash
flutter run -d emulator-5554 --dart-define=ADS_MODE=test
```

Real ads:

```bash
flutter run -d emulator-5554 --dart-define=ADS_MODE=real
```

---

## Running on iOS (Simulator)

Start the iOS simulator:

```bash
open -a Simulator
```

Check devices:

```bash
flutter devices
```

Run the app on the simulator device id:

```bash
flutter run -d <ios_simulator_device_id>
```

---

## Viewing Crash Logs (Android)

If the app opens and closes, use logcat:

```bash
~/Library/Android/sdk/platform-tools/adb logcat -c
~/Library/Android/sdk/platform-tools/adb logcat *:S AndroidRuntime:E flutter:E
```

---

## Ads (AdMob)

### Android: required App ID

Already set in:
`android/app/src/main/AndroidManifest.xml`

### iOS: required App ID (mandatory before running ads)

Add to `ios/Runner/Info.plist`:

* Key: `GADApplicationIdentifier`
* Value: your AdMob App ID

Use test App ID while developing.

---

## Common Commands

List devices:

```bash
flutter devices
```

Clean build:

```bash
flutter clean
flutter pub get
```

Run verbose:

```bash
flutter run -v
```

---

## Notes

* Use AdMob test unit IDs while developing.
* Replace with real AdMob unit IDs only when preparing release builds.
* Keep game logic independent from UI and ads logic.
