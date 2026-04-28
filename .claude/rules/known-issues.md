---
paths:
  - "lib/domain/services/voice_service.dart"
  - "lib/presentation/screens/daily/widgets/voice_session_sheet.dart"
  - "lib/presentation/screens/daily/widgets/voice_input_sheet.dart"
---

# Known issues — speech_to_text

**Android Kotlin `Unresolved reference 'Registrar'`**
`^6.x` uses the legacy `Registrar` API removed in newer Kotlin/Gradle. Fix: use `^7.0.0` in `pubspec.yaml`, then `flutter pub upgrade speech_to_text`.

**iOS Simulator `error_speech_recognizer_connection_interrupted`**
`SFSpeechRecognizer` requires Apple servers — unreliable in simulator. Use a physical iPhone or `flutter run -d macos`.

**Android emulator (`error_language_unavailable`, `error_speech_timeout`, `error_no_match`)**
Emulator needs Google Play Services + downloaded language packs; microphone passthrough unreliable. Use a real Android device or `flutter run -d macos`.
