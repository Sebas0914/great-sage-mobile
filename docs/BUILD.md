# Android APK build

The repository contains the Flutter Android platform project and can build a release APK through GitHub Actions.

## Manual build

1. Open the repository's Actions tab.
2. Select **Build Android APK**.
3. Choose **Run workflow**.
4. After the workflow finishes, open its artifacts.
5. Download **great-sage-mobile-apk**.

## Local build

With Flutter installed:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The generated APK is normally located at `build/app/outputs/flutter-apk/app-release.apk`.

## Android permissions

The release build includes the microphone and floating-overlay declarations required by the current app. Android still requires the user to grant microphone access at runtime and overlay access from system settings.
