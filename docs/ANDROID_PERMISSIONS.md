# Android permissions

GREAT SAGE Mobile uses the device microphone for speech-to-text and can show Raphael as a floating overlay.

## Microphone

The Android application declares:

- `android.permission.RECORD_AUDIO`

Microphone access must also be granted at runtime. Speech recognition is started only after the user taps the microphone control.

## Text-to-speech

Text-to-speech playback does not require microphone permission. The app uses the Android TTS engine through `flutter_tts`.

## Floating overlay

Raphael uses:

- `android.permission.SYSTEM_ALERT_WINDOW` for drawing over other apps.
- A foreground service with `specialUse` so Android can keep the overlay service running.

The user must explicitly grant the "display over other apps" permission in Android settings before Raphael can appear above other applications.

The overlay also uses a foreground-service notification while active.

These Android-specific capabilities are implemented behind the Flutter `OverlayService` interface, so the rest of the app does not depend directly on Android APIs.
