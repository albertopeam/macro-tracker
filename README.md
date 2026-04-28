# Macro Tracker

Offline nutrition logging via voice input, built with Flutter.

## Features

- Voice meal logging — speak a food and quantity, the app finds the match and logs it
- Fuzzy food matching against a built-in database of common foods
- Daily macro tracking (protein, carbs, fat, calories) with progress visualisation
- Calendar heatmap showing daily goal completion at a glance
- Customisable nutrition goals with a built-in TDEE calculator (maintenance / cut / bulk presets)

## Platforms

iOS and Android. Voice recognition requires a physical device — simulators are unreliable due to missing language packs or restricted Apple server access.

## Getting started

**Prerequisites:** Flutter ≥ 3.22

```bash
flutter pub get
flutter run -d ios
flutter run -d android
```

See [SETUP.md](SETUP.md) for platform-specific permission setup (microphone, speech recognition).

## Tests & lint

```bash
flutter test
flutter analyze
```

## License

MIT — see [LICENSE](LICENSE).
