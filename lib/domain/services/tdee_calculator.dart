import '../../data/models/macro_totals.dart';
import '../../data/models/user_profile.dart';

class TdeeCalculator {
  static double bmr(UserProfile p) {
    final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  static double tdee(UserProfile p) => bmr(p) * p.activityLevel.multiplier;

  // Mifflin-St Jeor BMR + ISSN macro recommendations
  static MacroGoals maintenance(UserProfile p) => _compute(tdee(p), p.weightKg, 1.6, 0.30);
  static MacroGoals cutting(UserProfile p) => _compute(tdee(p) - 400, p.weightKg, 2.0, 0.25);
  static MacroGoals bulking(UserProfile p) => _compute(tdee(p) + 300, p.weightKg, 1.8, 0.25);

  static MacroGoals _compute(
    double kcal,
    double weightKg,
    double proteinPerKg,
    double fatPct,
  ) {
    final protein = (weightKg * proteinPerKg).roundToDouble();
    final fat = (kcal * fatPct / 9).roundToDouble();
    final carbs = ((kcal - protein * 4 - fat * 9) / 4).clamp(0, double.infinity).roundToDouble();
    return MacroGoals(
      proteinG: protein,
      fatG: fat,
      carbsG: carbs,
      caloriesKcal: kcal.roundToDouble(),
    );
  }
}
