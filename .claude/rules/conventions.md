---
paths:
  - "lib/**/*.dart"
---

# Coding Conventions

## Architecture boundaries

- `data/` → `domain/` → `presentation/` — never import upward or skip layers.
- DAOs wrap raw SQL; repositories wrap DAOs; providers expose repositories to the UI.
- Domain logic (parsing, calculation) lives in `domain/`; no Flutter imports allowed there.

## Singletons

Use a private named constructor and a static `instance` field:

```dart
class FooRepository {
  FooRepository._();
  static final FooRepository instance = FooRepository._();
}
```

Lazy-init heavy resources with `??=`:

```dart
Foo? _foo;
Future<Foo> _getFoo() async {
  _foo ??= await _init();
  return _foo!;
}
```

## Models

- All fields `final`; use `const` constructors.
- SQLite serialization: `toMap()` / `factory Foo.fromMap(Map<String, dynamic>)`.
- SharedPreferences serialization: `toJson()` / `factory Foo.fromJson(Map<String, dynamic>)`.
- SQL column names are `snake_case`; Dart field names are `camelCase`.

## Riverpod state

| Use case | Provider type |
|---|---|
| Async data loaded once | `AsyncNotifierProvider<FooNotifier, FooType>` |
| Async family (keyed by param) | `AsyncNotifierProviderFamily<FooNotifier, FooType, Key>` |
| Synchronous derived state | `Provider<Foo>` |
| Complex mutable state | `StateNotifierProvider<FooNotifier, FooState>` |
| Simple async one-shot | `FutureProvider.family<T, Key>` |

- After any mutation in a notifier, call `ref.invalidateSelf()` to trigger a rebuild.
- Mutable state classes use a `copyWith` method; `reset()` returns `const FooState()`.
- Name pairs: `fooProvider` + `FooNotifier`.

## Error code mapping

Map raw `speech_to_text` error strings to user-facing messages via `SpeechErrorX` in
`lib/domain/services/speech_error.dart`. Never add error-string switches inside widgets.

```dart
// usage in a widget
Text(errorCode.friendlyMessage)
```

Add new codes to `SpeechErrorX.friendlyMessage`, not inline.

## providers.dart structure

Separate logical groups with `// ---` banner comments:

```dart
// ---------------------------------------------------------------------------
// Group name
// ---------------------------------------------------------------------------
```

All providers live in `lib/presentation/providers/providers.dart`.

## Dart style

- No comments unless the WHY is non-obvious (hidden constraint, workaround, subtle invariant).
- Prefer `extension FooX on T` over private helper methods or inline switches for string mapping.
- `debugPrint` for recoverable errors with a `—` note on what was cleared/reset.
