import 'meal_entry.dart';
import 'macro_totals.dart';

class DailyLog {
  final String date;
  final Map<MealType, List<MealEntry>> meals;

  DailyLog({required this.date, required this.meals});

  factory DailyLog.empty(String date) => DailyLog(
        date: date,
        meals: {
          MealType.breakfast: [],
          MealType.lunch: [],
          MealType.dinner: [],
          MealType.snack: [],
        },
      );

  MacroTotals get totals =>
      MacroTotals.fromEntries(meals.values.expand((e) => e).toList()).rounded();

  MacroTotals totalsForMeal(MealType type) =>
      MacroTotals.fromEntries(meals[type] ?? []).rounded();

  List<MealEntry> entriesForMeal(MealType type) => meals[type] ?? [];

  bool get hasAnyEntry => meals.values.any((e) => e.isNotEmpty);
}
