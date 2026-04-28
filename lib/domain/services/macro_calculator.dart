import 'package:uuid/uuid.dart';
import '../../data/models/food.dart';
import '../../data/models/meal_entry.dart';

const _uuid = Uuid();

class MacroCalculator {
  static MealEntry calculate({
    required Food food,
    required double grams,
    required MealType mealType,
    required String date,
  }) {
    if (grams < 0) throw ArgumentError('grams must be non-negative, got $grams');
    final factor = grams / 100.0;
    return MealEntry(
      id: _uuid.v4(),
      date: date,
      mealType: mealType,
      foodId: food.id ?? 0,
      foodName: food.name,
      grams: grams,
      protein: _round(food.proteinPer100g * factor),
      carbs: _round(food.carbsPer100g * factor),
      fat: _round(food.fatPer100g * factor),
      calories: _round(food.caloriesPer100g * factor),
      createdAt: DateTime.now(),
    );
  }

  static double _round(double v) => (v * 10).round() / 10;
}
