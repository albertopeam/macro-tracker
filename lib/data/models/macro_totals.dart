import 'meal_entry.dart';

class MacroTotals {
  final double protein;
  final double carbs;
  final double fat;
  final double calories;

  const MacroTotals({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });

  static MacroTotals zero() =>
      const MacroTotals(protein: 0, carbs: 0, fat: 0, calories: 0);

  static MacroTotals fromEntries(List<MealEntry> entries) =>
      entries.fold(MacroTotals.zero(), (acc, e) => acc + MacroTotals(
        protein: e.protein,
        carbs: e.carbs,
        fat: e.fat,
        calories: e.calories,
      ));

  MacroTotals operator +(MacroTotals other) => MacroTotals(
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
        calories: calories + other.calories,
      );

  MacroTotals rounded() => MacroTotals(
        protein: _r(protein),
        carbs: _r(carbs),
        fat: _r(fat),
        calories: _r(calories),
      );

  static double _r(double v) => (v * 10).round() / 10;
}

class MacroGoals {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double caloriesKcal;
  final String? preset; // 'maintenance' | 'cutting' | 'bulking'

  const MacroGoals({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.caloriesKcal,
    this.preset,
  });

  static MacroGoals defaults() => const MacroGoals(
      proteinG: 150, carbsG: 250, fatG: 65, caloriesKcal: 2200);

  static MacroGoals cutting() => const MacroGoals(
      proteinG: 180, carbsG: 150, fatG: 50, caloriesKcal: 1800);

  static MacroGoals bulking() => const MacroGoals(
      proteinG: 180, carbsG: 350, fatG: 80, caloriesKcal: 3000);

  Map<String, dynamic> toJson() => {
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'caloriesKcal': caloriesKcal,
        if (preset != null) 'preset': preset,
      };

  factory MacroGoals.fromJson(Map<String, dynamic> j) => MacroGoals(
        proteinG: (j['proteinG'] as num).toDouble(),
        carbsG: (j['carbsG'] as num).toDouble(),
        fatG: (j['fatG'] as num).toDouble(),
        caloriesKcal: (j['caloriesKcal'] as num).toDouble(),
        preset: j['preset'] as String?,
      );
}
