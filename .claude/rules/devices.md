---
paths:
  - "pubspec.yaml"
  - "android/**"
  - "ios/**"
  - "lib/main.dart"
---

# Available devices & emulators

| Name                  | ID                       | Platform        |
|-----------------------|--------------------------|-----------------|
| macOS                 | `macos`                  | darwin-arm64    |
| Chrome                | `chrome`                 | web-javascript  |
| iOS Simulator         | `apple_ios_simulator`    | ios             |
| Medium Phone API 36.1 | `Medium_Phone_API_36.1`  | android         |

```bash
flutter emulators --launch Medium_Phone_API_36.1  # start Android emulator
flutter emulators --launch apple_ios_simulator    # start iOS simulator
flutter run -d android
flutter run -d ios
```
