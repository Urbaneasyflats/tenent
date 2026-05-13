# UrbanEasy Resident App

Flutter mobile app for UrbanEasy residents and tenants.

## Requirements

- Flutter SDK matching `pubspec.yaml`
- Dart SDK from Flutter
- Android Studio or Android SDK command-line tools
- Xcode and CocoaPods for iOS builds on macOS
- Firebase Android config at `android/app/google-services.json`
- Firebase iOS config at `ios/Runner/GoogleService-Info.plist`

## Setup

```powershell
git clone <repository-url>
cd tenent
flutter pub get
```

For Android release builds, keep local signing files outside Git history:

- `android/key.properties`
- `android/app/upload-keystore.jks`

The Gradle release signing setup reads `android/key.properties` locally.

## Run

```powershell
flutter run
```

To run on a specific device:

```powershell
flutter devices
flutter run -d <device-id>
```

## Android Builds

Debug or release APK:

```powershell
flutter build apk
```

Play Store app bundle:

```powershell
flutter build appbundle
```

Output paths:

- APK: `build/app/outputs/flutter-apk/`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## iOS Build

Run on macOS:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```

Open `ios/Runner.xcworkspace` in Xcode for signing, archive, and App Store upload.

## Firebase

Firebase configuration files are required for app initialization and push notifications:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Do not rename the Android package/application id unless Firebase app registration is also updated.

## Repository Hygiene

Generated folders such as `build/`, `.dart_tool/`, Gradle caches, iOS Pods, IDE files, and local signing secrets are ignored by `.gitignore`.

Before committing:

```powershell
git status
flutter pub get
flutter build apk
flutter build appbundle
```
