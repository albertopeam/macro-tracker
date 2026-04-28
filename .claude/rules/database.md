---
paths:
  - "lib/data/**/*.dart"
---

# Database

SQLite via `sqflite`. File: `macro_tracker.db` in the app documents directory.

## Schema

**`foods`** — seeded from `assets/foods/foods.csv` on first launch:
- `id` INTEGER PK AUTOINCREMENT
- `name` TEXT UNIQUE, `category` TEXT
- `protein_per_100g`, `carbs_per_100g`, `fat_per_100g`, `calories_per_100g` REAL
- `aliases` TEXT (JSON array)

**`meal_entries`** — one row per logged serving:
- `id` TEXT PK (UUID)
- `date` TEXT (YYYY-MM-DD), `meal_type` TEXT
- `food_id` INTEGER, `food_name` TEXT
- `grams` REAL
- `protein`, `carbs`, `fat`, `calories` REAL (pre-computed at insert time)
- `created_at` TEXT

Indices: `idx_meal_date(date)`, `idx_meal_date_type(date, meal_type)`.

## Layering

DAOs wrap raw SQL; repositories wrap DAOs. Never call DAOs directly from providers or UI.

## Migrations

Add version blocks in `_onUpgrade` — never drop and recreate tables:

```dart
if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
```
