---
paths:
  - "lib/**/*.dart"
---

# Architecture

Clean Architecture layers: `data/` → `domain/` → `presentation/`.

**Data flow for voice logging:**
1. `VoiceService` (wraps `speech_to_text`) captures speech
2. `VoiceParser` (regex) extracts food name + grams from transcript
3. `FuzzyMatcher` (edit distance + word overlap) finds best food match in DB
4. `MacroCalculator` scales `Food` macros by grams → produces `MealEntry`
5. `LogRepository` persists to SQLite via `MealEntryDao`
6. `logProvider(date)` (Riverpod family) is invalidated → UI rebuilds

**State (Riverpod, all in `lib/presentation/providers/providers.dart`):**
- `foodsProvider` — async, cached; loads all foods from SQLite once
- `fuzzyMatcherProvider` — derived from foods
- `logProvider(date)` — family; daily meals + add/delete operations
- `goalsProvider` — macro goals from SharedPreferences
- `voiceProvider` — StateNotifier; tracks listening state, transcript, parse candidates

**Database:** SQLite (`app_database.dart`) seeded from `assets/foods/foods.csv` on first launch.
Schema: `foods` (name, macros/100g, aliases JSON) and `meal_entries` (date, meal_type, grams, computed macros).
