# Android permissions

GREAT SAGE Mobile uses the device microphone for speech-to-text.

The Android application must declare:

- `android.permission.RECORD_AUDIO`

On Android, microphone access is a dangerous permission and must also be requested at runtime before recording.

The speech recognition implementation should only start after the user explicitly taps the microphone control.

## Text-to-speech

Text-to-speech playback does not require microphone permission. The app uses the Android TTS engine through `flutter_tts`.

## CI note

The repository currently generates the Android platform project during GitHub Actions. The manifest and runtime permission wiring will be added to the generated Android project when the Android platform layer is committed.
