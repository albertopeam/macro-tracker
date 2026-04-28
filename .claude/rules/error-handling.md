---
paths:
  - "lib/**/*.dart"
---

# Error Handling

## Try/catch

Use in the data layer and providers for recoverable parsing or deserialization errors. 
Return `null` or a safe default.

```dart
try {
  return Foo.fromJson(jsonDecode(raw));
} catch (e) {
  await prefs.remove(fooKey);
  return Foo.defaults();
}
```

## Error propagation in repositories

Repositories do **not** catch SQLite exceptions — let them propagate to `AsyncNotifier`.
`AsyncNotifier.build()` surfaces them as `AsyncError` automatically.
Only add try/catch in a repository method if there is specific local recovery logic.

## Service-layer errors via callbacks

Services expose `onError` callbacks instead of throwing.
Clear the callback on cleanup.

```dart
onError: (error) {
  _onError?.call(error.errorMsg);
},

Future<void> cancel() async {
  _onError = null;
  await _speech.cancel();
}
```

## Domain validation

Use `ArgumentError` for precondition violations in pure domain functions.
Do not use `ArgumentError` in UI or data layer code.

```dart
if (grams < 0) throw ArgumentError('grams must be non-negative, got $grams');
```

## State-based errors in StateNotifier

Store errors as `String? errorMessage` in the state class.
Provide a `setError(String msg)` method that also resets active state (e.g. `isListening: false`).
UI calls `.friendlyMessage` on the string for display. `reset()` clears it via `const FooState()`.

## Riverpod AsyncValue in UI

Use `.when(loading:, error:, data:)` for all `AsyncNotifierProvider` consumers.
Never access `.value` directly without handling the error case.
For non-critical widgets, silence errors with `SizedBox.shrink()`; for full-page views, show `Text('Error: $e')`.

```dart
asyncValue.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Center(child: Text('Error: $e')),
  data: (value) => buildContent(value),
)
```

## Mounted checks

Always check `mounted` before calling `setState` or reading `ref` in async callbacks.

```dart
onError: (error) {
  if (!mounted) return;
  setState(() => _errorMessage = error);
}
```

## What NOT to use

- No `Result<T>`, `Either<L, R>`, or other functional error wrapper types.
- No custom `Exception` subclasses — use `ArgumentError` for preconditions and let other exceptions propagate naturally.
